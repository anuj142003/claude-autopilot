#!/usr/bin/env bash
# ============================================================================
# Project State Detector for ECC + BMAD Unified Orchestration
#
# This script runs on every SessionStart hook. It inspects the project
# directory and outputs a structured state summary that gets injected
# into Claude's context. Claude then uses this to decide whether to
# act in BMAD mode (planning/design) or ECC mode (implementation).
# ============================================================================

set -euo pipefail

# ── Color codes for structured output ──
# (Claude reads the raw text, colors are for human debugging)

echo "═══════════════════════════════════════════════════════════"
echo "  PROJECT STATE DETECTION — Unified ECC + BMAD Orchestrator"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ── 1. Detect BMAD artifacts ──────────────────────────────────
HAS_BMAD_DIR=false
HAS_PRD=false
HAS_ARCHITECTURE=false
HAS_STORIES=false
HAS_STORIES_UNIMPLEMENTED=false
HAS_PRODUCT_BRIEF=false
HAS_UX_DESIGN=false
BMAD_ARTIFACT_COUNT=0

if [ -d "_bmad" ] || [ -d ".bmad" ] || [ -d "_bmad-output" ]; then
    HAS_BMAD_DIR=true
fi

# Check for PRD (multiple common locations)
for f in _bmad-output/prd.md _bmad-output/PRD.md docs/PRD.md docs/prd.md _bmad-output/*.prd.md; do
    if compgen -G "$f" > /dev/null 2>&1; then
        HAS_PRD=true
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + 1))
        break
    fi
done

# Check for architecture docs
for f in _bmad-output/architecture.md _bmad-output/arch*.md docs/architecture.md docs/ARCHITECTURE.md; do
    if compgen -G "$f" > /dev/null 2>&1; then
        HAS_ARCHITECTURE=true
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + 1))
        break
    fi
done

# Check for product brief
for f in _bmad-output/product-brief.md _bmad-output/brief*.md docs/product-brief.md; do
    if compgen -G "$f" > /dev/null 2>&1; then
        HAS_PRODUCT_BRIEF=true
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + 1))
        break
    fi
done

# Check for UX design docs
for f in _bmad-output/ux*.md _bmad-output/design*.md docs/ux-design.md; do
    if compgen -G "$f" > /dev/null 2>&1; then
        HAS_UX_DESIGN=true
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + 1))
        break
    fi
done

# Check for stories
STORY_COUNT=0
# Check for stories in both flat and nested (epic/story) directory structures
for f in _bmad-output/stories/*.md _bmad-output/stories/**/*.md _bmad-output/epics/*.md _bmad-output/epics/**/*.md _bmad-output/story-*.md; do
    if compgen -G "$f" > /dev/null 2>&1; then
        HAS_STORIES=true
        STORY_COUNT=$(compgen -G "$f" 2>/dev/null | wc -l)
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + STORY_COUNT))
        break
    fi
done
# Fallback: use find if compgen missed nested stories
if [ "$HAS_STORIES" = false ] && [ -d "_bmad-output/stories" ]; then
    STORY_COUNT=$(find _bmad-output/stories -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$STORY_COUNT" -gt 0 ]; then
        HAS_STORIES=true
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + STORY_COUNT))
    fi
fi

# ── 1b. Detect UI/UX design artifacts ────────────────────────
HAS_DESIGN_TOKENS=false
HAS_BRAND_GUIDE=false
HAS_COMPONENT_SPECS=false
HAS_UIUX_SKILLS=false

# Design token files
for f in _bmad-output/design-tokens.md _bmad-output/design-system.md; do
    if compgen -G "$f" > /dev/null 2>&1; then
        HAS_DESIGN_TOKENS=true
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + 1))
        break
    fi
done

# Brand guide
for f in _bmad-output/brand-guide.md _bmad-output/brand*.md; do
    if compgen -G "$f" > /dev/null 2>&1; then
        HAS_BRAND_GUIDE=true
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + 1))
        break
    fi
done

# Component specs
for f in _bmad-output/component-specs.md _bmad-output/components*.md; do
    if compgen -G "$f" > /dev/null 2>&1; then
        HAS_COMPONENT_SPECS=true
        BMAD_ARTIFACT_COUNT=$((BMAD_ARTIFACT_COUNT + 1))
        break
    fi
done

# UI/UX skills installed (project-level or global)
if [ -d ".claude/skills/ui-ux-pro-max" ] || [ -d "$HOME/.claude/skills/ui-ux-pro-max" ]; then
    HAS_UIUX_SKILLS=true
fi

# ── 1c. Detect non-BMAD planning artifacts ───────────────────
# Users may create planning docs outside _bmad-output/ (e.g., via brainstorming,
# manual planning, or other tools). Detect these so we can inform autopilot.
HAS_INFORMAL_PLANS=false
INFORMAL_PLAN_COUNT=0

for d in docs/plans docs/design docs/planning design plans; do
    if [ -d "$d" ]; then
        count=$(find "$d" -name "*.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            HAS_INFORMAL_PLANS=true
            INFORMAL_PLAN_COUNT=$((INFORMAL_PLAN_COUNT + count))
        fi
    fi
done

# ── 2. Detect ECC artifacts ───────────────────────────────────
HAS_ECC_HOOKS=false
HAS_ECC_RULES=false
HAS_ECC_SKILLS=false
HAS_INSTINCTS=false

if [ -f ".claude/settings.json" ] || [ -f "$HOME/.claude/settings.json" ]; then
    HAS_ECC_HOOKS=true
fi

if [ -d ".claude/rules" ] || [ -d "$HOME/.claude/rules" ]; then
    HAS_ECC_RULES=true
fi

if [ -d ".claude/skills" ] || [ -d "$HOME/.claude/skills" ]; then
    HAS_ECC_SKILLS=true
fi

if [ -d "$HOME/.claude/skills/learned" ] && [ "$(ls -A "$HOME/.claude/skills/learned" 2>/dev/null)" ]; then
    HAS_INSTINCTS=true
fi

# ── 3. Detect project code state ──────────────────────────────
HAS_SOURCE_CODE=false
HAS_TESTS=false
HAS_PACKAGE_JSON=false
RECENT_COMMITS=0
CURRENT_BRANCH="unknown"

# Source code detection
for d in src/ app/ lib/ pkg/ cmd/ internal/; do
    if [ -d "$d" ]; then
        HAS_SOURCE_CODE=true
        break
    fi
done

# Test detection
for d in tests/ test/ __tests__/ spec/ *_test.go; do
    if compgen -G "$d" > /dev/null 2>&1; then
        HAS_TESTS=true
        break
    fi
done

# Package manager
if [ -f "package.json" ] || [ -f "requirements.txt" ] || [ -f "go.mod" ] || [ -f "Cargo.toml" ] || [ -f "pyproject.toml" ]; then
    HAS_PACKAGE_JSON=true
fi

# Git state
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    RECENT_COMMITS=$( (git log --oneline -20 2>/dev/null || true) | wc -l | tr -d ' ')
fi

# ── 4. Determine lifecycle phase ──────────────────────────────
PHASE="UNKNOWN"
PHASE_DETAIL=""

if [ "$HAS_BMAD_DIR" = false ] && [ "$HAS_PRD" = false ] && [ "$HAS_SOURCE_CODE" = false ] && [ "$HAS_INFORMAL_PLANS" = true ]; then
    PHASE="PLANNING_INFORMAL"
    PHASE_DETAIL="Found $INFORMAL_PLAN_COUNT planning doc(s) outside _bmad-output/. Design work exists but not in BMAD format. Consider formalizing into a product brief or PRD, or proceed directly to implementation."
elif [ "$HAS_BMAD_DIR" = false ] && [ "$HAS_PRD" = false ] && [ "$HAS_SOURCE_CODE" = false ]; then
    PHASE="IDEATION"
    PHASE_DETAIL="No project artifacts found. This appears to be a brand new project or idea."
elif [ "$HAS_PRODUCT_BRIEF" = false ] && [ "$HAS_PRD" = false ]; then
    if [ "$HAS_SOURCE_CODE" = true ]; then
        PHASE="BROWNFIELD_NO_DOCS"
        PHASE_DETAIL="Existing codebase without BMAD planning artifacts. Could benefit from retroactive documentation, or proceed directly with ECC for implementation."
    else
        PHASE="ANALYSIS"
        PHASE_DETAIL="BMAD directory exists but no product brief or PRD yet. Start with brainstorming and analysis."
    fi
elif [ "$HAS_PRD" = false ] && [ "$HAS_PRODUCT_BRIEF" = true ]; then
    PHASE="PLANNING"
    PHASE_DETAIL="Product brief exists but no PRD. Ready for requirements elicitation and PRD creation."
elif [ "$HAS_PRD" = true ] && [ "$HAS_ARCHITECTURE" = false ]; then
    PHASE="SOLUTIONING"
    PHASE_DETAIL="PRD exists but no architecture document. Ready for architecture design."
elif [ "$HAS_PRD" = true ] && [ "$HAS_ARCHITECTURE" = true ] && [ "$HAS_STORIES" = false ]; then
    PHASE="STORY_CREATION"
    PHASE_DETAIL="PRD and architecture exist but no stories. Ready for epic/story breakdown."
elif [ "$HAS_STORIES" = true ] && [ "$HAS_SOURCE_CODE" = false ]; then
    PHASE="READY_TO_BUILD"
    PHASE_DETAIL="Stories exist ($STORY_COUNT found) but no source code yet. Ready for implementation with ECC."
elif [ "$HAS_STORIES" = true ] && [ "$HAS_SOURCE_CODE" = true ]; then
    PHASE="BUILDING"
    PHASE_DETAIL="Active development — stories and source code both exist. Continue implementation with ECC agents."
elif [ "$HAS_SOURCE_CODE" = true ] && [ "$HAS_TESTS" = true ]; then
    PHASE="BUILDING"
    PHASE_DETAIL="Active development with tests. ECC agents should handle implementation and quality."
else
    PHASE="BUILDING"
    PHASE_DETAIL="Source code exists. Default to ECC implementation mode."
fi

# ── 4b. Add UI/UX hints when skills are available ────────────
if [ "$HAS_UIUX_SKILLS" = true ]; then
    case "$PHASE" in
        PLANNING_INFORMAL|SOLUTIONING|STORY_CREATION|READY_TO_BUILD|BUILDING|BROWNFIELD_NO_DOCS)
            if [ "$HAS_DESIGN_TOKENS" = false ]; then
                PHASE_DETAIL="$PHASE_DETAIL UI/UX design skills are available — consider generating design tokens, brand guide, or component specs."
            fi
            ;;
    esac
fi

# ── 5. Output structured state ────────────────────────────────
echo "LIFECYCLE PHASE: $PHASE"
echo "DETAIL: $PHASE_DETAIL"
echo ""
echo "── BMAD Artifacts ──"
echo "  BMAD directory installed:  $HAS_BMAD_DIR"
echo "  Product brief:             $HAS_PRODUCT_BRIEF"
echo "  PRD:                       $HAS_PRD"
echo "  Architecture doc:          $HAS_ARCHITECTURE"
echo "  UX design doc:             $HAS_UX_DESIGN"
echo "  Stories:                   $HAS_STORIES (count: $STORY_COUNT)"
echo "  Total BMAD artifacts:      $BMAD_ARTIFACT_COUNT"
echo ""
echo "── ECC Components ──"
echo "  Hooks installed:           $HAS_ECC_HOOKS"
echo "  Rules installed:           $HAS_ECC_RULES"
echo "  Skills installed:          $HAS_ECC_SKILLS"
echo "  Learned instincts:         $HAS_INSTINCTS"
echo ""
echo "── UI/UX Design ──"
echo "  UI/UX skills installed:    $HAS_UIUX_SKILLS"
echo "  Design tokens:             $HAS_DESIGN_TOKENS"
echo "  Brand guide:               $HAS_BRAND_GUIDE"
echo "  Component specs:           $HAS_COMPONENT_SPECS"
echo ""
echo "── Informal Planning ──"
echo "  Non-BMAD plan docs:       $HAS_INFORMAL_PLANS (count: $INFORMAL_PLAN_COUNT)"
echo ""
echo "── Project State ──"
echo "  Source code:               $HAS_SOURCE_CODE"
echo "  Tests:                     $HAS_TESTS"
echo "  Package manager:           $HAS_PACKAGE_JSON"
echo "  Git branch:                $CURRENT_BRANCH"
echo "  Recent commits:            $RECENT_COMMITS"
echo ""

# ── 6. Emit nudge ─────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════"
echo "  Type /autopilot to see available actions for this phase"
echo "═══════════════════════════════════════════════════════════"
