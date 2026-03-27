# claude-autopilot v3 — Menu-Driven Command Router

## Problem

Users who install both BMAD and ECC don't know when to use which framework, what commands are available, or where to start. The v1 approach (CLAUDE.md behavioral descriptions) and v2 approach (CLAUDE.md discovery protocol) both fail because project-level instructions can't reliably override user-level plugins that compete for Claude's attention.

## Key Insights from v1/v2 Failures

1. **CLAUDE.md can't be the orchestrator brain** — other plugins (Superpowers, etc.) inject competing instructions at equal or higher priority
2. **Behavioral descriptions don't work** — telling Claude to "act as Mary" is weaker than BMAD's actual guided workflows
3. **Discovery protocol was right, enforcement was wrong** — finding commands at runtime is good, but trying to auto-route Claude's behavior is fragile

## Design Principles

1. **Don't compete with other plugins** — autopilot activates only when explicitly invoked
2. **Don't modify either framework** — wrap around BMAD and ECC as-is
3. **Don't hardcode commands** — discover at runtime so framework updates don't break autopilot
4. **Let Claude do the thinking** — use Claude's semantic understanding to filter and match, not keyword logic
5. **BMAD for guidance, ECC for execution** — each framework's strength in its right place

## Architecture

Two components:

### 1. SessionStart Hook (lightweight nudge)

The existing `detect-project-state.sh` is simplified to:
- Detect the current lifecycle phase (keep existing logic)
- Output a one-liner: `Type /autopilot to see available actions for your current phase`
- No behavioral instructions, no routing, no discovery paths

This avoids all conflicts with other plugins — it's just a hint.

### 2. `/autopilot` Command (the real entry point)

A skill/command file that implements a menu-driven loop:

**On invocation:**
1. Run phase detection (same logic as the hook)
2. Discover BMAD commands:
   - Find all `module-help.csv` files in `~/.bmad/cache/external-modules/`
   - Parse CSV to get: skill name, display name, menu code, description, phase
   - Filter by phase column matching current lifecycle phase
3. Discover ECC agents:
   - Glob `~/.claude/agents/*.md`
   - Read frontmatter (name, description, model)
   - Let Claude filter which agents are relevant to the current phase based on descriptions
4. Discover ECC skills:
   - Already available in Claude's context
   - Let Claude filter which are relevant
5. Present a unified menu:
   ```
   You're in [PHASE] phase.

   Available actions:
     [1] Action name → source (BMAD/ECC), brief description
     [2] Action name → source (BMAD/ECC), brief description
     ...
     [H] Show all available commands

   Pick one, or describe what you want to do.
   ```
6. Execute user's choice:
   - BMAD workflow → invoke via Skill tool with the skill's canonicalId
   - ECC agent → dispatch via Agent tool with subagent_type and model from frontmatter
   - ECC skill → invoke via Skill tool
7. After completion, show updated menu with "what's next" options
8. Loop until user exits or switches to free-form

### Phase-to-Action Filtering

**BMAD commands:** Filtered by the `phase` column in `module-help.csv`:
- `anytime` → always shown
- `1-preproduction` → shown in IDEATION, ANALYSIS
- `2-design` → shown in PLANNING, SOLUTIONING
- `3-technical` → shown in STORY_CREATION
- `4-production` → shown in READY_TO_BUILD, BUILDING

**ECC agents:** Claude reads all agent descriptions and selects which are relevant to the current phase. No keyword mapping — Claude's semantic understanding handles this.

**ECC skills:** Same as agents — Claude selects relevant ones.

### Cost Optimization

During BUILDING phases, when the menu offers ECC agents, each agent runs on its configured model:
- planner → opus (deep reasoning)
- tdd-guide → sonnet (implementation)
- code-reviewer → sonnet (review)
- security-reviewer → sonnet (security)
- doc-updater → haiku (lightweight)

The main session handles only menu presentation and user interaction. Bulk work is delegated to agents on cheaper models.

## What Changes from v1

| Component | v1 | v3 |
|-----------|-----|-----|
| `CLAUDE.md` | Heavy behavioral routing instructions | Minimal — just mentions `/autopilot` exists |
| `detect-project-state.sh` | Full routing with persona recommendations | Phase detection + one-liner nudge |
| `/autopilot` command | Doesn't exist | New — the entire orchestration logic |
| `unified-orchestration.md` | Artifact conventions + routing rules | Artifact conventions only |
| `settings.json` | SessionStart hook | Same, simplified output |
| `install.sh` | Installs 4 files | Installs 5 files (adds autopilot command) |

## What Stays the Same

- Phase detection logic (IDEATION through BUILDING)
- Artifact conventions (`_bmad-output/` paths)
- Both frameworks untouched
- Install script structure

## Implementation Order

1. Simplify `detect-project-state.sh` — keep phase detection, replace routing with one-liner nudge
2. Simplify `CLAUDE.md` — remove behavioral instructions, add brief mention of `/autopilot`
3. Simplify `unified-orchestration.md` — remove routing rules, keep artifact conventions
4. Create `/autopilot` command skill file — the core of v3
5. Update `install.sh` — install the new command file
6. Update `README.md` — reflect v3 architecture
7. Test end-to-end in sample project
