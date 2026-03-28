#!/usr/bin/env bash
# ============================================================================
# Unified ECC + BMAD Orchestrator — Uninstall Script
#
# Removes claude-autopilot files from the current project.
# Does NOT uninstall ECC or BMAD themselves.
#
# Usage:
#   cd ~/your-project
#   bash uninstall.sh
# ============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Unified ECC + BMAD Orchestrator — Uninstaller${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

ORCHESTRATOR_MARKER="# claude-autopilot"

# ── Check if autopilot is installed ──────────────────────────
if [ ! -f "CLAUDE.md" ] || ! grep -qF "$ORCHESTRATOR_MARKER" CLAUDE.md 2>/dev/null; then
    if [ ! -f ".claude/hooks/detect-project-state.sh" ] && [ ! -f ".claude/commands/autopilot.md" ]; then
        echo -e "${YELLOW}claude-autopilot does not appear to be installed in this directory.${NC}"
        echo ""
        exit 0
    fi
fi

echo -e "${BOLD}This will remove the following claude-autopilot files:${NC}"
echo ""

# ── List files that will be removed ──────────────────────────
FILES_TO_REMOVE=()

for f in \
    ".claude/hooks/detect-project-state.sh" \
    ".claude/commands/autopilot.md" \
    ".claude/rules/unified-orchestration.md" \
; do
    if [ -f "$f" ]; then
        echo -e "  ${RED}✗${NC} $f"
        FILES_TO_REMOVE+=("$f")
    fi
done

# CLAUDE.md — only remove if it's ours (contains the marker)
if [ -f "CLAUDE.md" ] && grep -qF "$ORCHESTRATOR_MARKER" CLAUDE.md 2>/dev/null; then
    echo -e "  ${RED}✗${NC} CLAUDE.md"
    FILES_TO_REMOVE+=("CLAUDE.md")
fi

# settings.json — only remove the hooks key, not the whole file
if [ -f ".claude/settings.json" ]; then
    echo -e "  ${YELLOW}~${NC} .claude/settings.json (will remove hooks section only)"
fi

echo ""
echo -e "${BOLD}The following will NOT be removed:${NC}"
echo -e "  ${GREEN}✓${NC} _bmad-output/ (your planning artifacts)"
echo -e "  ${GREEN}✓${NC} ECC installation (~/.claude/)"
echo -e "  ${GREEN}✓${NC} BMAD installation (~/.bmad/)"
echo ""

# ── Confirm ──────────────────────────────────────────────────
read -r -p "Proceed with uninstall? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) ;;
    *)
        echo ""
        echo "Uninstall cancelled."
        exit 0
        ;;
esac

echo ""
echo -e "${BOLD}Removing files...${NC}"

# ── Remove files ─────────────────────────────────────────────
for f in "${FILES_TO_REMOVE[@]}"; do
    rm -f "$f"
    echo -e "  ${GREEN}✓${NC} Removed $f"
done

# ── Clean up settings.json hooks ─────────────────────────────
if [ -f ".claude/settings.json" ] && command -v python3 &> /dev/null; then
    python3 -c "
import json
with open('.claude/settings.json', 'r') as f:
    settings = json.load(f)
if 'hooks' in settings:
    del settings['hooks']
    with open('.claude/settings.json', 'w') as f:
        json.dump(settings, f, indent=2)
        f.write('\n')
    print('  \033[0;32m✓\033[0m Removed hooks from .claude/settings.json')
else:
    print('  \033[0;32m✓\033[0m No hooks found in .claude/settings.json')
" 2>/dev/null || echo -e "  ${YELLOW}⚠${NC} Could not clean settings.json — remove 'hooks' key manually"
fi

# ── Clean up empty directories ───────────────────────────────
rmdir .claude/hooks 2>/dev/null && echo -e "  ${GREEN}✓${NC} Removed empty .claude/hooks/" || true
rmdir .claude/commands 2>/dev/null && echo -e "  ${GREEN}✓${NC} Removed empty .claude/commands/" || true
rmdir .claude/rules 2>/dev/null && echo -e "  ${GREEN}✓${NC} Removed empty .claude/rules/" || true

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Uninstall Complete${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  claude-autopilot has been removed from this project."
echo -e "  Your planning artifacts in ${GREEN}_bmad-output/${NC} are untouched."
echo -e "  ECC and BMAD are still installed globally."
echo ""
