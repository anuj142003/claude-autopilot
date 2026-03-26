#!/usr/bin/env bash
# ============================================================================
# Unified ECC + BMAD Orchestrator — Install Script
#
# This script sets up the "smart autopilot" configuration that makes
# Claude Code automatically detect your project phase and route to
# BMAD (planning) or ECC (implementation) mode.
#
# Prerequisites:
#   - Claude Code >= v2.1.0 installed
#   - ECC installed (via plugin or git clone)
#   - BMAD-METHOD installed (via npx bmad-method install)
#
# Usage:
#   cd ~/your-project
#   bash install.sh
# ============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ── Parse flags ───────────────────────────────────────────────
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
    esac
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Unified ECC + BMAD Orchestrator — Installer${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ── Check prerequisites ───────────────────────────────────────
echo -e "${BOLD}Checking prerequisites...${NC}"

MISSING=()

# Claude Code
if command -v claude &> /dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✓${NC} Claude Code found: $CLAUDE_VER"
else
    echo -e "  ${RED}✗${NC} Claude Code not found. Install it with:"
    echo "    npm install -g @anthropic-ai/claude-code"
    MISSING+=("Claude Code")
fi

# ECC check
if [ -d "$HOME/.claude/rules" ] || [ -f ".claude-plugin/plugin.json" ]; then
    echo -e "  ${GREEN}✓${NC} ECC components detected"
else
    echo -e "  ${RED}✗${NC} ECC not detected. Install it with:"
    echo "    git clone https://github.com/affaan-m/everything-claude-code.git"
    echo "    cd everything-claude-code && npm install && ./install.sh typescript"
    MISSING+=("everything-claude-code (ECC)")
fi

# BMAD check
if [ -d "_bmad" ] || [ -d ".bmad" ]; then
    echo -e "  ${GREEN}✓${NC} BMAD-METHOD detected"
else
    echo -e "  ${RED}✗${NC} BMAD-METHOD not detected. Install it with:"
    echo "    npx bmad-method install"
    MISSING+=("BMAD-METHOD")
fi

echo ""

# ── Abort if prerequisites are missing ────────────────────────
if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}Missing prerequisites: ${MISSING[*]}${NC}"
    echo ""
    if [ "$FORCE" = true ]; then
        echo -e "${YELLOW}Proceeding anyway (--force flag set)...${NC}"
        echo ""
    else
        echo "  Install the missing prerequisites above, then re-run this script."
        echo ""
        echo -e "  Or run with ${BOLD}--force${NC} to skip prerequisite checks:"
        echo "    bash install.sh --force"
        echo ""
        exit 1
    fi
fi

# ── Create directories ────────────────────────────────────────
echo -e "${BOLD}Setting up unified orchestrator...${NC}"

mkdir -p .claude/hooks
mkdir -p .claude/rules
mkdir -p _bmad-output/stories
mkdir -p _bmad-output/sprints
mkdir -p _bmad-output/retros

echo -e "  ${GREEN}✓${NC} Directories created"

# ── Copy hook detection script ────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.claude/hooks/detect-project-state.sh" ]; then
    cp "$SCRIPT_DIR/.claude/hooks/detect-project-state.sh" .claude/hooks/detect-project-state.sh
    chmod +x .claude/hooks/detect-project-state.sh
    echo -e "  ${GREEN}✓${NC} Project state detector installed"
else
    echo -e "  ${YELLOW}⚠${NC} detect-project-state.sh not found in script directory"
    echo "    Copy it manually to .claude/hooks/detect-project-state.sh"
fi

# ── Install hooks into settings.json (merge safely) ──────────
HOOKS_SOURCE="$SCRIPT_DIR/.claude/settings.json"
SETTINGS_TARGET=".claude/settings.json"

if [ -f "$HOOKS_SOURCE" ]; then
    if [ -f "$SETTINGS_TARGET" ]; then
        echo -e "  ${YELLOW}⚠${NC} Existing .claude/settings.json found — merging hooks safely"
        cp "$SETTINGS_TARGET" "$SETTINGS_TARGET.bak"

        # Try merging with python3 (available on macOS and most Linux)
        if command -v python3 &> /dev/null; then
            python3 -c "
import json, sys

with open('$SETTINGS_TARGET', 'r') as f:
    existing = json.load(f)

with open('$HOOKS_SOURCE', 'r') as f:
    new_hooks = json.load(f)

# Merge only the 'hooks' key, preserve everything else
existing['hooks'] = new_hooks.get('hooks', {})

with open('$SETTINGS_TARGET', 'w') as f:
    json.dump(existing, f, indent=2)
    f.write('\n')
" && echo -e "  ${GREEN}✓${NC} Hooks merged into existing settings.json (backup: settings.json.bak)" \
            || {
                echo -e "  ${RED}✗${NC} Failed to merge settings. Your backup is at settings.json.bak"
                echo "    Please manually add the hooks from: $HOOKS_SOURCE"
            }
        else
            echo -e "  ${YELLOW}⚠${NC} python3 not found — cannot auto-merge"
            echo "    Please manually add the hooks from: $HOOKS_SOURCE"
            echo "    Your existing settings are backed up at: settings.json.bak"
        fi
    else
        cp "$HOOKS_SOURCE" "$SETTINGS_TARGET"
        echo -e "  ${GREEN}✓${NC} settings.json (with hooks) installed"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Source settings.json not found in $SCRIPT_DIR/.claude/"
fi

# ── Install orchestration rules ───────────────────────────────
if [ -f "$SCRIPT_DIR/.claude/rules/unified-orchestration.md" ]; then
    cp "$SCRIPT_DIR/.claude/rules/unified-orchestration.md" .claude/rules/unified-orchestration.md
    echo -e "  ${GREEN}✓${NC} Orchestration rules installed"
fi

# ── Install CLAUDE.md ─────────────────────────────────────────
ORCHESTRATOR_MARKER="# Unified Development Orchestrator — ECC + BMAD-METHOD"

# Resolve real paths to prevent reading/writing the same file
SOURCE_CLAUDE="$(cd "$SCRIPT_DIR" && pwd)/CLAUDE.md"
TARGET_CLAUDE="$(pwd)/CLAUDE.md"

if [ "$SOURCE_CLAUDE" = "$TARGET_CLAUDE" ]; then
    echo -e "  ${YELLOW}⚠${NC} CLAUDE.md source and target are the same file — skipping to avoid loop"
elif [ -f "CLAUDE.md" ] && grep -qF "$ORCHESTRATOR_MARKER" CLAUDE.md 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} CLAUDE.md already contains the unified orchestrator — skipping"
elif [ -f "CLAUDE.md" ]; then
    echo -e "  ${YELLOW}⚠${NC} Existing CLAUDE.md found — backing up to CLAUDE.md.bak"
    cp CLAUDE.md CLAUDE.md.bak
    echo ""
    echo -e "  ${YELLOW}Your existing CLAUDE.md has been backed up.${NC}"
    echo -e "  ${YELLOW}The unified CLAUDE.md will be appended to your existing one.${NC}"
    echo ""
    # Use a temp file to avoid any read/write race conditions
    cp "$SOURCE_CLAUDE" /tmp/_unified_claude_md_tmp
    echo "" >> CLAUDE.md
    echo "---" >> CLAUDE.md
    echo "" >> CLAUDE.md
    cat /tmp/_unified_claude_md_tmp >> CLAUDE.md
    rm -f /tmp/_unified_claude_md_tmp
    echo -e "  ${GREEN}✓${NC} Unified orchestrator appended to CLAUDE.md"
elif [ -f "$SOURCE_CLAUDE" ]; then
    cp "$SOURCE_CLAUDE" CLAUDE.md
    echo -e "  ${GREEN}✓${NC} CLAUDE.md installed"
else
    echo -e "  ${YELLOW}⚠${NC} Source CLAUDE.md not found in $SCRIPT_DIR"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Installation Complete!${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Files installed:"
echo -e "    ${GREEN}CLAUDE.md${NC}                           — Orchestrator instructions"
echo -e "    ${GREEN}.claude/settings.json${NC}               — SessionStart hook config"
echo -e "    ${GREEN}.claude/hooks/detect-project-state.sh${NC} — State detection script"
echo -e "    ${GREEN}.claude/rules/unified-orchestration.md${NC} — Routing rules"
echo -e "    ${GREEN}_bmad-output/${NC}                        — Artifact directories"
echo ""
echo -e "  ${BOLD}How it works:${NC}"
echo -e "    1. Every time you start Claude Code, the hook detects your project phase"
echo -e "    2. Claude sees the phase and automatically enters the right mode:"
echo -e "       ${PURPLE}BMAD mode${NC} for planning (Ideation → PRD → Architecture → Stories)"
echo -e "       ${BLUE}ECC mode${NC}  for building (Implementation → Review → Deploy)"
echo -e "    3. Just tell Claude what you want — no slash commands needed"
echo ""
echo -e "  ${BOLD}Try it now:${NC}"
echo -e "    ${CYAN}claude${NC}"
echo -e "    Then say: ${CYAN}\"I want to build a task management app\"${NC}"
echo ""
