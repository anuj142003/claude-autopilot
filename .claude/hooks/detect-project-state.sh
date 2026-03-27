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

if [ "$HAS_BMAD_DIR" = false ] && [ "$HAS_PRD" = false ] && [ "$HAS_SOURCE_CODE" = false ]; then
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
echo "── Project State ──"
echo "  Source code:               $HAS_SOURCE_CODE"
echo "  Tests:                     $HAS_TESTS"
echo "  Package manager:           $HAS_PACKAGE_JSON"
echo "  Git branch:                $CURRENT_BRANCH"
echo "  Recent commits:            $RECENT_COMMITS"
echo ""

# ── 6. Emit routing instruction ───────────────────────────────
echo "═══════════════════════════════════════════════════════════"
echo "  ROUTING INSTRUCTION"
echo "═══════════════════════════════════════════════════════════"
echo ""

case "$PHASE" in
    IDEATION)
        echo "MODE: BMAD"
        echo "AGENT: Mary (Analyst) or Barry (Quick Flow)"
        echo "ACTION: Start with brainstorming. Ask the user about their idea, then guide them through market/domain analysis using BMAD's analysis workflows."
        echo "NEXT: Product brief creation"
        ;;
    ANALYSIS)
        echo "MODE: BMAD"
        echo "AGENT: Mary (Analyst)"
        echo "ACTION: Continue analysis phase. Help create a product brief using BMAD's brainstorming and research workflows."
        echo "NEXT: PRD creation with John (PM)"
        ;;
    PLANNING)
        echo "MODE: BMAD"
        echo "AGENT: John (PM)"
        echo "ACTION: Product brief is ready. Guide the user through PRD creation using BMAD's elicitation workflow."
        echo "NEXT: Architecture design with Winston (Architect)"
        ;;
    SOLUTIONING)
        echo "MODE: BMAD"
        echo "AGENT: Winston (Architect)"
        echo "ACTION: PRD is ready. Guide architecture design, technology selection, and system design using BMAD's solutioning workflow."
        echo "NEXT: Story creation with Bob (Scrum Master)"
        ;;
    STORY_CREATION)
        echo "MODE: BMAD"
        echo "AGENT: Bob (Scrum Master)"
        echo "ACTION: Architecture is ready. Break down into epics and stories with acceptance criteria using BMAD's story creation workflow."
        echo "NEXT: Implementation with ECC agents"
        ;;
    READY_TO_BUILD|BUILDING)
        echo "MODE: ECC"
        echo "AGENT: ECC agents (code-reviewer, security-reviewer, tdd-guide auto-activate)"
        echo "ACTION: Implementation phase. ECC hooks will auto-format, type-check, and enforce quality. Use /plan for strategy, /tdd for test-driven development."
        echo "ACTIVE: All ECC lifecycle hooks, security scanning, continuous learning"
        if [ "$HAS_STORIES" = true ]; then
            echo "STORIES AVAILABLE: Yes — reference stories in _bmad-output/ for implementation context"
        fi
        ;;
    BROWNFIELD_NO_DOCS)
        echo "MODE: ECC (primary), BMAD (optional)"
        echo "AGENT: ECC agents for implementation"
        echo "ACTION: Existing codebase detected without BMAD planning docs. Default to ECC mode for feature development. If user wants to add structure, suggest BMAD retroactive documentation."
        echo "ACTIVE: All ECC lifecycle hooks, security scanning, continuous learning"
        ;;
    *)
        echo "MODE: ASK"
        echo "ACTION: Unable to determine lifecycle phase. Ask the user what they'd like to do: plan a new feature (BMAD) or implement/fix code (ECC)."
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════"
