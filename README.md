<p align="center">
  <h1 align="center">claude-autopilot</h1>
  <p align="center">
    <strong>Type <code>/autopilot</code> to see available actions from BMAD and ECC based on your project phase</strong>
  </p>
  <p align="center">
    A menu-driven orchestrator that discovers commands at runtime from <a href="https://github.com/affaan-m/everything-claude-code">everything-claude-code</a> and <a href="https://github.com/bmad-code-org/BMAD-METHOD">BMAD-METHOD</a>, then lets you pick what to do next.
  </p>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> &bull;
  <a href="#usage">Usage</a> &bull;
  <a href="#how-it-works">How It Works</a> &bull;
  <a href="#phase-detection">Phase Detection</a> &bull;
  <a href="#architecture">Architecture</a> &bull;
  <a href="#contributing">Contributing</a>
</p>

---

## What is claude-autopilot?

**claude-autopilot is NOT a fork or bundle of ECC or BMAD.** It does not include either framework — you install them separately. What it provides is a thin **orchestration layer** that:

1. **Detects** your project's lifecycle phase on every session start
2. **Discovers** available commands from both frameworks at runtime
3. **Presents** a unified menu of phase-relevant actions
4. **Executes** your choice by invoking the right framework
5. **Loops** — after each action completes, re-detects the phase and shows updated options

No hardcoded command lists. No behavioral routing. Just a menu that adapts to your project state.

## About the Frameworks

### everything-claude-code (ECC)

[ECC](https://github.com/affaan-m/everything-claude-code) by Affaan Mustafa is a comprehensive toolkit that optimizes Claude Code's behavior during **implementation**. It installs globally into `~/.claude/` and provides:

- **Rules** — language-specific coding standards (Python, TypeScript, Go, etc.)
- **Hooks** — auto-formatting, type-checking, security scanning on every code change
- **Skills** — TDD workflows, code review, continuous learning
- **Agents** — specialized sub-agents for exploration, testing, and review

ECC makes Claude write better code, but it doesn't help you figure out *what* to build.

### BMAD-METHOD

[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) by Brian (BMad) Madison is a structured agile workflow system for **planning and design**. It installs per-project and provides:

- **Guided workflows** — brainstorming, requirements elicitation, architecture design, story creation
- **Document templates** — product briefs, PRDs, architecture docs, user stories with acceptance criteria
- **Phase-aware commands** — each workflow is tagged with the lifecycle phase it belongs to

BMAD ensures you build the *right thing*, but it doesn't optimize the AI agent during coding.

### Why Both? A Deeper Look

BMAD and ECC aren't just different tools — they have fundamentally different execution models, and each is stronger where the other is weak.

**BMAD workflows** execute as step-file sequences loaded inline in your main Claude session. Each step is a detailed markdown file (often 400+ lines) with menus, user checkpoints, and frontmatter-based state tracking. BMAD "agents" (like the Architect or Analyst) are actually persona instructions — Claude adopts a communication style and presents a capability menu, but it's the same Claude instance doing all the work in the same context window, on the same model.

**ECC agents** are real sub-processes. When you dispatch an ECC agent (like `code-reviewer` or `tdd-guide`), Claude Code spawns a separate instance with a focused system prompt, running on a dedicated model. A code review runs on Sonnet instead of Opus. A doc update runs on Haiku. Each agent gets a fresh context — not polluted by your 50-message planning conversation.

This creates a natural split:

| Capability | BMAD | ECC |
|-----------|------|-----|
| Guided multi-step workflows | Strong (step files, menus, state tracking) | Weak (no guided flow) |
| User interaction mid-task | Strong (A/P/C menus, approval gates) | Weak (fire-and-forget agents) |
| Task execution quality | Average (same Claude, growing context) | Strong (fresh context, focused prompt) |
| Cost efficiency | None (runs on main session model) | Strong (model-optimized per agent) |
| Auto-formatting, type-checking | None | Strong (hooks run on every edit) |

**BMAD excels at planning** — guiding you from idea to stories with structured workflows and user interaction at every step. **ECC excels at implementation** — delegating coding, testing, and review to specialized agents on cost-appropriate models, with hooks that enforce quality on every edit.

Neither alone covers the full lifecycle. Together, you get guided planning that produces high-quality artifacts, followed by agent-driven implementation with cost optimization and automated quality gates.

### The Gap

Neither framework knows about the other. If you install both, you need to manually decide when to use BMAD workflows vs ECC agents, which slash commands to run, and how to transition between planning and building. **claude-autopilot fills this gap** — one menu that shows the right tool from either framework based on where you are.

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) >= v2.1.0
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) installed
- [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) installed (`npx bmad-method install`)

### Install

```bash
# Clone this repo
git clone https://github.com/anuj142003/claude-autopilot.git

# Navigate to your project
cd ~/your-project

# Run the installer (will check prerequisites first)
bash /path/to/claude-autopilot/install.sh

# Or skip prerequisite checks if you'll install ECC/BMAD later
bash /path/to/claude-autopilot/install.sh --force

# Or auto-accept all prerequisite installation prompts
bash /path/to/claude-autopilot/install.sh --auto-install
```

#### Uninstall

```bash
# Uninstall (removes autopilot files, keeps your artifacts)
bash /path/to/claude-autopilot/uninstall.sh
```

The installer will:
- **Check prerequisites** and offer to install missing ones (Claude Code, ECC, BMAD) interactively
- **Merge** hooks into your existing `.claude/settings.json` (preserving your permissions, env vars, etc.)
- Copy the detection script and orchestration rules
- Install the `/autopilot` command
- Create `_bmad-output/` directories for artifact storage

> **Note:** The installer requires `python3` for safe JSON merging. It will fail gracefully and tell you what to do manually if `python3` is not available.

### Try it

```bash
cd ~/your-project
claude
# Type: /autopilot
```

## Usage

When you start a Claude Code session, the SessionStart hook detects your project phase and displays:

```
═══════════════════════════════════════════════════════════
  Type /autopilot to see available actions for this phase
═══════════════════════════════════════════════════════════
```

Type `/autopilot` and you get a menu like this:

```
════════════════════════════════════════════════
  AUTOPILOT — Phase: PLANNING
════════════════════════════════════════════════

BMAD Workflows:
  [CP]  Create PRD — Generate product requirements document (bmad-core)
  [CA]  Create Architecture — Design system architecture (bmad-core)
  [DE]  Deep Exploration — Research and analyze a topic (bmad-core)

ECC Agents:
  [planner]          Create implementation plan (model: opus)
  [architect]        System design decisions (model: sonnet)
  [security-reviewer] Security analysis (model: sonnet)

Other:
  [H] Show ALL available commands (all phases)
  [Q] Exit autopilot

Pick an option, or describe what you want to do.
```

Pick an option by typing its code, or describe what you want in plain language. After the action completes, autopilot re-detects the phase (artifacts may have changed) and shows an updated menu.

## How It Works

```
You type: /autopilot
     |
     v
[1. Detect Phase]
     |  Check _bmad-output/ artifacts + source code
     |  Determine: IDEATION / PLANNING / BUILDING / etc.
     |
     v
[2. Discover Commands]
     |  BMAD: Parse ~/.bmad/cache/**/module-help.csv
     |        Filter rows by phase column
     |  ECC:  Glob ~/.claude/agents/*.md
     |        Read frontmatter (name, description, model)
     |        Filter by phase relevance
     |
     v
[3. Present Menu]
     |  Show phase-relevant actions from both frameworks
     |  Group by source (BMAD / ECC)
     |
     v
[4. Execute Choice]
     |  BMAD workflow → invoke via Skill tool
     |  ECC agent → dispatch via Agent tool
     |
     v
[5. Loop]
     Re-detect phase → updated menu → next action
```

## Phase Detection

The detection script inspects your project directory and determines the lifecycle phase:

| Phase | Trigger | Available Actions |
|-------|---------|-------------------|
| `IDEATION` | No artifacts, no source code | BMAD brainstorming and ideation workflows |
| `ANALYSIS` | BMAD dir exists, no brief/PRD | BMAD analysis and research workflows |
| `PLANNING` | Product brief exists, no PRD | BMAD requirements and PRD creation workflows |
| `SOLUTIONING` | PRD exists, no architecture doc | BMAD architecture and design workflows |
| `STORY_CREATION` | PRD + architecture, no stories | BMAD story creation and sprint planning workflows |
| `READY_TO_BUILD` | Stories exist, no source code | ECC agents for planning, TDD, and implementation |
| `BUILDING` | Stories + source code exist | ECC agents for coding, testing, reviewing, and security |
| `BROWNFIELD` | Source code but no BMAD artifacts | ECC agents for implementation; BMAD workflows available on request |

### Artifact Convention

Phase detection depends on artifacts being saved to the right locations:

```
_bmad-output/
  product-brief.md        # ANALYSIS -> PLANNING
  prd.md                  # PLANNING -> SOLUTIONING
  architecture.md         # SOLUTIONING -> STORY_CREATION
  ux-design.md            # Optional
  stories/                # STORY_CREATION -> READY_TO_BUILD
    epic-name/
      story-name.md
  sprints/                # Sprint tracking
  retros/                 # Retrospectives
```

## Architecture

Two components:

### 1. SessionStart Hook (`detect-project-state.sh`)

A lightweight shell script that runs on every session start. It scans for BMAD artifacts and source code to determine the lifecycle phase, then outputs a one-liner nudging the user to type `/autopilot`. No behavioral routing, no persona assignments — just phase detection and a hint.

### 2. `/autopilot` Command (`.claude/commands/autopilot.md`)

The core orchestrator. A Claude Code command skill that implements the menu-driven loop: detect phase, discover commands from both frameworks at runtime, present a unified menu, execute the user's choice, and loop. It never hardcodes command lists — it parses BMAD's `module-help.csv` files and reads ECC agent frontmatter on every invocation.

```
claude-autopilot/
  CLAUDE.md                              # Minimal — mentions /autopilot exists
  install.sh                             # One-command installer with safety checks
  uninstall.sh                           # Removes autopilot files, keeps artifacts
  .claude/
    settings.json                        # SessionStart hook configuration
    commands/
      autopilot.md                       # Menu-driven command router
    hooks/
      detect-project-state.sh            # Project state detection script
    rules/
      unified-orchestration.md           # Artifact conventions
  docs/
    ECC-vs-BMAD-Analysis-Report.pdf      # Detailed comparison of both frameworks
    ECC-BMAD-Setup-Guide.pdf             # Step-by-step setup guide
```

## Cost Optimization

During BUILDING phases, `/autopilot` shows which model each ECC agent runs on, so you can make informed cost decisions:

| Agent | Model | Use Case |
|-------|-------|----------|
| planner | Opus | Deep reasoning for implementation plans |
| tdd-guide | Sonnet | Test-driven development workflow |
| code-reviewer | Sonnet | Code quality and architecture review |
| security-reviewer | Sonnet | Security analysis |
| doc-updater | Haiku | Lightweight documentation updates |

The main session handles only menu presentation and user interaction. Bulk work is delegated to agents running on the appropriate model tier — use Haiku for lightweight tasks and Opus only when deep reasoning is needed.

## How Is This Different From...

**...just using ECC?** ECC has powerful agents and hooks for implementation, but no guided workflow for planning. You'd need to know which of the 28+ agents to dispatch, when, and in what order. There's no step-by-step process that takes you from idea to stories — you jump straight to code.

**...just using BMAD?** BMAD has excellent guided workflows for planning, but its "agents" are just persona instructions — the same Claude instance role-playing different characters in the same session. During implementation, there's no agent delegation to cheaper models, no hooks for auto-formatting or type-checking, and no specialized sub-processes for code review or security scanning.

**...using both manually?** You'd need to know that BMAD has 60+ workflows spread across 4 modules, which ones apply to your current phase, how to invoke them, and when to switch to ECC's agents for implementation. `/autopilot` discovers all of this at runtime and presents one menu — no framework knowledge required.

## Limitations

- **Explicit invocation required** — `/autopilot` is a command-based system; it must be explicitly typed at the start of each session to activate the menu
- **Artifact path convention** — Phase detection depends on planning artifacts being saved to the `_bmad-output/` directory at the expected paths; artifacts saved elsewhere will not be detected
- **Separate prerequisites** — BMAD and ECC must be installed independently (though the installer can walk you through it interactively)
- **Runtime discovery** — The menu contents are discovered at runtime from installed frameworks, so what you see depends on what is currently installed

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Ideas for contributions:

- Improve `/autopilot` command menu UX
- Better phase-to-BMAD-phase mapping in the CSV filter
- Support for additional BMAD modules
- Automated end-to-end testing of the `/autopilot` flow
- Additional phase detection patterns (CI/CD status, branch naming)
- Support for other AI coding frameworks beyond ECC and BMAD

## Credits

- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) by Affaan Mustafa — the agent optimization layer
- [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) by Brian (BMad) Madison — the structured methodology layer
- Analysis and orchestration by [Anuj Saxena](https://github.com/anuj142003)

## License

MIT License. See [LICENSE](LICENSE) for details.
