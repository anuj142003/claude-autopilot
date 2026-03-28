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
