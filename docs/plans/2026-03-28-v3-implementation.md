# claude-autopilot v3 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace v1's CLAUDE.md behavioral routing with a menu-driven `/autopilot` command that discovers BMAD/ECC commands at runtime and presents phase-relevant choices to the user.

**Architecture:** Two components: (1) lightweight SessionStart hook that detects phase and nudges user to type `/autopilot`, (2) `/autopilot` command skill that discovers commands from both frameworks, presents a menu, executes user's choice, and loops with "what's next."

**Tech Stack:** Bash (hook), Markdown (command skill, CLAUDE.md), CSV parsing (BMAD module-help.csv)

---

## Task 1: Simplify detect-project-state.sh

Replace the routing instruction section (lines 212-271) with a simple one-liner nudge. Keep all phase detection logic (lines 1-210) unchanged.

**Files:**
- Modify: `.claude/hooks/detect-project-state.sh:212-271`

**Step 1: Replace the routing instruction section**

Replace everything from line 212 (`# ── 6. Emit routing instruction`) through line 271 (the final `═══` line) with:

```bash
# ── 6. Emit nudge ─────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════"
echo "  Type /autopilot to see available actions for this phase"
echo "═══════════════════════════════════════════════════════════"
```

**Step 2: Verify the script runs**

Run: `bash .claude/hooks/detect-project-state.sh`
Expected: Phase detection output followed by the one-liner nudge. No routing instructions, no persona names.

**Step 3: Commit**

```bash
git add .claude/hooks/detect-project-state.sh
git commit -m "feat: simplify hook to phase detection + one-liner nudge for /autopilot"
```

---

## Task 2: Simplify CLAUDE.md

Replace the heavy behavioral routing instructions with a minimal file that mentions `/autopilot` and artifact conventions.

**Files:**
- Rewrite: `CLAUDE.md`

**Step 1: Replace the entire CLAUDE.md with:**

```markdown
# claude-autopilot — Unified Development Orchestrator

This project has both [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) and [everything-claude-code](https://github.com/affaan-m/everything-claude-code) installed.

## Getting Started

Type `/autopilot` to see available actions for your current project phase. The command detects where you are in the development lifecycle and shows relevant options from both frameworks.

## Artifact Conventions

Planning artifacts are saved to `_bmad-output/` for phase detection:

- Product brief: `_bmad-output/product-brief.md`
- PRD: `_bmad-output/prd.md`
- Architecture: `_bmad-output/architecture.md`
- UX design: `_bmad-output/ux-design.md`
- Stories: `_bmad-output/stories/<epic-name>/<story-name>.md`
- Sprint plans: `_bmad-output/sprints/<sprint-name>.md`

## Phase Detection

A SessionStart hook automatically detects your project phase based on which artifacts exist. Run `/autopilot` at any time to see what actions are available.
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: simplify CLAUDE.md to minimal /autopilot reference"
```

---

## Task 3: Simplify unified-orchestration.md

Remove routing rules, keep only artifact conventions.

**Files:**
- Rewrite: `.claude/rules/unified-orchestration.md`

**Step 1: Replace the entire file with:**

```markdown
# Unified ECC + BMAD Orchestration Rules

## Artifact Location Conventions

All planning artifacts MUST be saved to `_bmad-output/` with these filenames:

- Product brief: `_bmad-output/product-brief.md`
- PRD: `_bmad-output/prd.md`
- Architecture: `_bmad-output/architecture.md`
- UX design: `_bmad-output/ux-design.md`
- Stories: `_bmad-output/stories/<epic-name>/<story-name>.md`
- Sprint plans: `_bmad-output/sprints/<sprint-name>.md`
- Retrospectives: `_bmad-output/retros/<sprint-name>-retro.md`

This convention ensures the SessionStart hook can detect project state accurately.

## Phase Transition Signals

When completing a planning phase, always:
1. Save the artifact to the correct location above
2. Announce the transition explicitly to the user
3. Suggest running `/autopilot` to see next available actions
```

**Step 2: Commit**

```bash
git add .claude/rules/unified-orchestration.md
git commit -m "feat: simplify orchestration rules to artifact conventions only"
```

---

## Task 4: Create the /autopilot command

This is the core of v3. Create a command skill file that implements the menu-driven router.

**Files:**
- Create: `.claude/commands/autopilot.md`

**Step 1: Create the commands directory**

Run: `mkdir -p .claude/commands`

**Step 2: Write the autopilot command file**

Create `.claude/commands/autopilot.md` with:

```markdown
---
description: Discover and run BMAD workflows or ECC agents based on your project phase
---

# Autopilot — Menu-Driven Command Router

You are the autopilot orchestrator. Your job is to detect the project phase, discover available commands from both BMAD and ECC, present a menu, execute the user's choice, and loop.

## Step 1: Detect Phase

Run the phase detection logic by checking which artifacts exist in the project:

1. Check for `_bmad-output/` artifacts:
   - Product brief: `_bmad-output/product-brief.md`
   - PRD: `_bmad-output/prd.md`
   - Architecture: `_bmad-output/architecture.md`
   - Stories: `_bmad-output/stories/` (any .md files inside)
2. Check for source code directories: `src/`, `app/`, `lib/`, `pkg/`, `cmd/`, `internal/`
3. Determine phase:
   - No artifacts, no source → **IDEATION**
   - No brief, no PRD, has source → **BROWNFIELD**
   - Has brief, no PRD → **PLANNING**
   - Has PRD, no architecture → **SOLUTIONING**
   - Has PRD + architecture, no stories → **STORY_CREATION**
   - Has stories, no source → **READY_TO_BUILD**
   - Has stories + source → **BUILDING**

## Step 2: Discover BMAD Commands

Search for BMAD's `module-help.csv` files:

1. Glob `~/.bmad/cache/external-modules/*/src/module-help.csv`
2. For each CSV found, read it and parse the rows. The CSV columns are:
   `module,skill,display-name,menu-code,description,action,args,phase,after,before,required,output-location,outputs`
3. Filter rows where `phase` matches the current lifecycle phase:
   - Phase `anytime` → always include
   - Phase `0-learning` → include in any phase
   - Phase `1-preproduction` → include in IDEATION, ANALYSIS
   - Phase `2-design` → include in PLANNING, SOLUTIONING
   - Phase `3-solutioning` or `3-technical` → include in SOLUTIONING, STORY_CREATION
   - Phase `4-production` → include in READY_TO_BUILD, BUILDING
4. Collect: skill name, display name, menu code, description, module name

If no BMAD installation is found at `~/.bmad/`, skip this step and note that BMAD is not installed.

## Step 3: Discover ECC Agents

1. Glob `~/.claude/agents/*.md`
2. For each agent file, read just the YAML frontmatter (between the `---` delimiters) to get:
   - `name`: agent identifier
   - `description`: what the agent does
   - `model`: which model it runs on (opus/sonnet/haiku)
3. Given the current phase, select which agents are relevant:
   - Use your semantic understanding of the agent descriptions
   - In PLANNING phases: agents related to planning, architecture, analysis
   - In BUILDING phases: agents related to coding, testing, reviewing, security, documentation
   - In any phase: agents that are broadly applicable
4. For each relevant agent, note: name, description, model

If no agents directory exists, skip this step and note that ECC agents are not available.

## Step 4: Present Menu

Display a menu like this:

```
════════════════════════════════════════════════
  AUTOPILOT — Phase: [PHASE_NAME]
════════════════════════════════════════════════

BMAD Workflows:
  [menu-code] display-name — description (module)
  [menu-code] display-name — description (module)
  ...

ECC Agents:
  [agent-name] description (model: X)
  [agent-name] description (model: X)
  ...

Other:
  [H] Show ALL available commands (all phases)
  [Q] Exit autopilot

Pick an option, or describe what you want to do.
```

If either BMAD or ECC has no relevant commands for this phase, omit that section and note it.

## Step 5: Execute Choice

Based on user's input:

- **If user picks a BMAD menu code or skill name:** Invoke the BMAD workflow using the Skill tool with the skill's `skill` column value as the skill name. Example: `Skill tool with skill: "gds-create-prd"`
- **If user picks an ECC agent name:** Dispatch the agent using the Agent tool with `subagent_type` matching the agent's `name` field. Include context about the current project state and any relevant artifacts from `_bmad-output/`.
- **If user types "H":** Re-run discovery but show ALL commands from all phases, not just the current phase.
- **If user types "Q":** Exit autopilot mode. Say "Exiting autopilot. You can type /autopilot anytime to return."
- **If user describes what they want in natural language:** Match their intent to the discovered commands. Pick the best match, confirm with the user, then execute.

## Step 6: After Completion

When the invoked workflow or agent finishes:

1. Re-detect the phase (artifacts may have changed)
2. If the phase changed, announce: "Phase updated: [OLD] → [NEW]"
3. Present the updated menu with relevant actions for the new phase
4. Continue the loop

## Important Rules

- Never role-play personas — you are a router, not an actor
- Never hardcode command lists — always discover at runtime
- Always show which framework (BMAD/ECC) provides each option
- For ECC agents, always show the model they run on (helps user understand cost)
- If both BMAD and ECC offer similar capabilities (e.g., code review), show both and let the user choose
- Save all planning artifacts to `_bmad-output/` paths so phase detection stays accurate
```

**Step 3: Commit**

```bash
git add .claude/commands/autopilot.md
git commit -m "feat: create /autopilot command — menu-driven router with runtime discovery"
```

---

## Task 5: Update install.sh

Add installation of the autopilot command file. Also fix BMAD detection to check `~/.bmad/`.

**Files:**
- Modify: `install.sh`

**Step 1: Add commands directory creation after the existing mkdir block (around line 100-104)**

After `mkdir -p _bmad-output/retros`, add:

```bash
mkdir -p .claude/commands
```

**Step 2: Add command file installation after the rules installation block (around line 168)**

After the rules installation block, add:

```bash
# ── Install autopilot command ─────────────────────────────
if [ -f "$SCRIPT_DIR/.claude/commands/autopilot.md" ]; then
    cp "$SCRIPT_DIR/.claude/commands/autopilot.md" .claude/commands/autopilot.md
    echo -e "  ${GREEN}✓${NC} Autopilot command installed (/autopilot)"
fi
```

**Step 3: Fix BMAD prerequisite check (lines 69-76)**

Replace the BMAD check to look at `~/.bmad/` first:

```bash
# BMAD check
if [ -d "$HOME/.bmad/cache/external-modules" ]; then
    echo -e "  ${GREEN}✓${NC} BMAD-METHOD detected (global install)"
elif [ -d "_bmad" ] || [ -d ".bmad" ]; then
    echo -e "  ${GREEN}✓${NC} BMAD-METHOD detected (project install)"
else
    echo -e "  ${RED}✗${NC} BMAD-METHOD not detected. Install it with:"
    echo "    npx bmad-method install"
    MISSING+=("BMAD-METHOD")
fi
```

**Step 4: Update the summary section to mention /autopilot**

In the "How it works" section (around lines 217-221), replace the explanation with:

```bash
echo -e "  ${BOLD}How it works:${NC}"
echo -e "    1. Every time you start Claude Code, the hook detects your project phase"
echo -e "    2. Type ${CYAN}/autopilot${NC} to see available actions from both BMAD and ECC"
echo -e "    3. Pick an action — autopilot invokes the right framework for you"
echo ""
echo -e "  ${BOLD}Try it now:${NC}"
echo -e "    ${CYAN}claude${NC}"
echo -e "    Then type: ${CYAN}/autopilot${NC}"
```

**Step 5: Commit**

```bash
git add install.sh
git commit -m "feat: update installer to include /autopilot command and fix BMAD detection"
```

---

## Task 6: Update README.md

Rewrite to reflect v3 architecture — `/autopilot` as the entry point, no personas, no behavioral descriptions.

**Files:**
- Modify: `README.md`

**Step 1: Key sections to update**

1. **Tagline**: "Type `/autopilot` to see available actions from BMAD and ECC based on your project phase."
2. **What claude-autopilot Does**: Detects phase, discovers commands from both frameworks at runtime, presents a menu, executes your choice.
3. **How It Works diagram**: Show the `/autopilot` command flow: detect phase → discover BMAD CSV + ECC agents → present menu → execute → loop
4. **Phase Detection table**: Keep phases, but change "Claude's Behavior" column to "Available Actions" showing what `/autopilot` offers
5. **Remove all persona references** (Mary, John, Winston, Bob, Quinn)
6. **Add a "Usage" section** showing what `/autopilot` looks like in practice
7. **Architecture section**: Update to show the 2-component design (hook + command)
8. **Add Cost Optimization section** explaining ECC agent model routing

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README for v3 menu-driven architecture"
```

---

## Task 7: Test end-to-end in sample project

**Files:**
- No files created — verification task

**Step 1: Clean up and recreate sample project**

```bash
rm -rf /tmp/sample-project
mkdir /tmp/sample-project && cd /tmp/sample-project && git init
echo "# Sample Project" > README.md && git add . && git commit -m "init"
```

**Step 2: Install autopilot**

```bash
bash /Users/Anuj.Saxena/Trivium/toolAnalysis/claude-autopilot/install.sh --force
```

Expected: Installer shows all checks passing, installs 5 files including autopilot command.

**Step 3: Verify hook output**

```bash
bash .claude/hooks/detect-project-state.sh
```

Expected: Phase detection output + one-liner "Type /autopilot to see available actions"

**Step 4: Verify autopilot command file is installed**

```bash
cat .claude/commands/autopilot.md | head -5
```

Expected: Shows the autopilot command frontmatter.

**Step 5: Verify phase transitions**

```bash
# IDEATION → should show BMAD brainstorming/ideation commands
# (actual /autopilot test requires interactive Claude session)
mkdir -p _bmad-output && touch _bmad-output/product-brief.md
bash .claude/hooks/detect-project-state.sh | grep "PHASE\|autopilot"

touch _bmad-output/prd.md
bash .claude/hooks/detect-project-state.sh | grep "PHASE\|autopilot"

touch _bmad-output/architecture.md
bash .claude/hooks/detect-project-state.sh | grep "PHASE\|autopilot"

mkdir -p _bmad-output/stories && touch _bmad-output/stories/s1.md
bash .claude/hooks/detect-project-state.sh | grep "PHASE\|autopilot"

mkdir -p src && touch src/main.py
bash .claude/hooks/detect-project-state.sh | grep "PHASE\|autopilot"
```

Expected: Each phase correctly detected, all showing the /autopilot nudge.

**Step 6: Clean up**

```bash
rm -rf /tmp/sample-project
```
