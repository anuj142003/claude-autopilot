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

### The Gap

Neither framework knows about the other. If you install both, you need to manually decide when to use BMAD workflows vs ECC agents, which slash commands to run, and how to transition between planning and building. **claude-autopilot fills this gap.**

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
```

The installer will:
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

**...just using ECC?** ECC optimizes agent behavior but doesn't guide you through planning. You get great code but might build the wrong thing.

**...just using BMAD?** BMAD provides structure but doesn't optimize the AI agent during implementation. You get great plans but slower coding.

**...using both manually?** You'd need to know which slash commands to run at each phase, handle conflicts between them, and remember to save artifacts in the right places. `/autopilot` discovers everything at runtime and presents one menu.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Ideas for contributions:

- Additional phase detection patterns (CI/CD status, branch naming)
- Support for other AI coding frameworks beyond ECC and BMAD
- Custom CLAUDE.md templates for specific project types (monorepo, microservices, etc.)
- Integration tests that verify phase detection accuracy

## Credits

- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) by Affaan Mustafa — the agent optimization layer
- [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) by Brian (BMad) Madison — the structured methodology layer
- Analysis and orchestration by [Anuj Saxena](https://github.com/anuj142003)

## License

MIT License. See [LICENSE](LICENSE) for details.
