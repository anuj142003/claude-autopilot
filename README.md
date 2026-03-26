<p align="center">
  <h1 align="center">claude-autopilot</h1>
  <p align="center">
    <strong>Hands-free orchestration for AI-assisted development</strong>
  </p>
  <p align="center">
    Automatically routes between <a href="https://github.com/affaan-m/everything-claude-code">everything-claude-code</a> (planning & implementation optimization) and <a href="https://github.com/bmad-code-org/BMAD-METHOD">BMAD-METHOD</a> (structured agile workflows) — so you never have to think about which tool to invoke.
  </p>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> &bull;
  <a href="#how-it-works">How It Works</a> &bull;
  <a href="#phase-detection">Phase Detection</a> &bull;
  <a href="#example-project">Example</a> &bull;
  <a href="#configuration">Configuration</a> &bull;
  <a href="#contributing">Contributing</a>
</p>

---

## What is claude-autopilot?

**claude-autopilot is NOT a fork or bundle of ECC or BMAD.** It does not include either framework — you install them separately. What it provides is a thin **orchestration layer** that sits on top of both and automatically routes Claude's behavior based on where your project is in its lifecycle.

Think of it like a traffic controller: ECC and BMAD are the roads, and claude-autopilot decides which road Claude should take at any given moment.

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

- **Agent personas** — Mary (Analyst), John (PM), Winston (Architect), Bob (Scrum Master), Quinn (QA)
- **Workflows** — guided brainstorming, requirements elicitation, architecture design, story creation
- **Document templates** — product briefs, PRDs, architecture docs, user stories with acceptance criteria

BMAD ensures you build the *right thing*, but it doesn't optimize the AI agent during coding.

### The Gap

Neither framework knows about the other. If you install both, you need to manually decide when to use BMAD workflows vs ECC agents, which slash commands to run, and how to transition between planning and building. **claude-autopilot fills this gap.**

## What claude-autopilot Does

1. **Detects** your project's lifecycle phase on every session start
2. **Routes** Claude's behavior to the right framework automatically
3. **Transitions** between planning and implementation as your project progresses

You just type what you want. Claude figures out the rest.

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
- Append orchestrator instructions to your `CLAUDE.md` (or create one)
- Create `_bmad-output/` directories for artifact storage

> **Note:** The installer requires `python3` for safe JSON merging. It will fail gracefully and tell you what to do manually if `python3` is not available.

Or copy the 4 files manually:

```
CLAUDE.md                              -> your-project/CLAUDE.md
.claude/settings.json                  -> merge "hooks" key into your-project/.claude/settings.json
.claude/hooks/detect-project-state.sh  -> your-project/.claude/hooks/detect-project-state.sh
.claude/rules/unified-orchestration.md -> your-project/.claude/rules/unified-orchestration.md
```

### Try it

```bash
cd ~/your-project
claude
# Just tell Claude what you want to build. That's it.
```

## How It Works

Three mechanisms work together to create automatic routing:

```
Session Start
     |
     v
[SessionStart Hook] ──> detect-project-state.sh
     |                        |
     |                   Scans for:
     |                   - BMAD artifacts (PRD, architecture, stories)
     |                   - Source code & tests
     |                   - Git state
     |                        |
     v                        v
[CLAUDE.md]  <────── Phase Detection Result
     |                (IDEATION / PLANNING / BUILDING / etc.)
     |
     v
[Conditional Routing]
     |
     ├── Planning phases ──> BMAD agent personas
     |                       (Mary, John, Winston, Bob)
     |
     └── Build phases ────> ECC agents & hooks
                            (code-reviewer, security, TDD)
```

### The Key Insight

Claude Code's `SessionStart` hook can run any shell script and inject the output into Claude's context. The `CLAUDE.md` file is loaded every session and can contain conditional instructions using `<important if="...">` tags. Combined, these create a **context-aware autopilot** that adapts to your project's current state.

## Phase Detection

The detection script inspects your project directory and determines the lifecycle phase:

| Phase | Trigger | Claude's Behavior |
|-------|---------|-------------------|
| `IDEATION` | No artifacts, no source code | BMAD mode — Mary (Analyst) guides brainstorming |
| `ANALYSIS` | BMAD dir exists, no brief/PRD | BMAD mode — continues analysis toward product brief |
| `PLANNING` | Product brief exists, no PRD | BMAD mode — John (PM) guides PRD creation |
| `SOLUTIONING` | PRD exists, no architecture doc | BMAD mode — Winston (Architect) guides design |
| `STORY_CREATION` | PRD + architecture, no stories | BMAD mode — Bob (Scrum Master) creates stories |
| `READY_TO_BUILD` | Stories exist, no source code | ECC mode — Plan → TDD → Implement → Review → Report |
| `BUILDING` | Stories + source code exist | ECC mode — continues TDD with story acceptance criteria |
| `BROWNFIELD` | Source code but no BMAD artifacts | ECC mode — offers BMAD if user wants structure |

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

The `CLAUDE.md` instructs Claude to save artifacts to these locations automatically.

## Example Project

The `examples/todo-app/` directory contains a starter project that demonstrates the full lifecycle. Clone it and try:

```bash
cd examples/todo-app
claude
# Say: "I want to build a simple todo app with user authentication"
# Claude will detect IDEATION phase and start BMAD planning automatically
```

As you progress through planning phases, the detection script picks up new artifacts and transitions Claude's behavior. See the [example README](examples/todo-app/README.md) for a full walkthrough.

## Configuration

### Customizing Detection

Edit `.claude/hooks/detect-project-state.sh` to customize:

- **File paths** — if your BMAD artifacts are in different locations
- **Phase logic** — if you want different transition conditions
- **Additional checks** — add CI status, branch patterns, etc.

### Customizing Routing

Edit `CLAUDE.md` to customize:

- **Agent behavior** — adjust what Claude does in each phase
- **Transition rules** — change when Claude switches between BMAD and ECC
- **Team conventions** — add project-specific instructions

### Conflict Resolution

| Conflict | Resolution |
|----------|------------|
| Skills directory collision | BMAD uses `.claude/skills/bmad/`, ECC uses `.claude/skills/` — no overlap |
| Both have TDD workflows | ECC for test execution, BMAD for test planning |
| Fresh chat (BMAD) vs long sessions (ECC) | Fresh chats for planning, longer sessions for implementation |
| Rules overlap | ECC rules are language-specific, BMAD is process-specific — they complement |

## Architecture

```
claude-autopilot/
  CLAUDE.md                              # Orchestrator brain — conditional routing instructions
  install.sh                             # One-command installer with safety checks
  .claude/
    settings.json                        # SessionStart hook configuration
    hooks/
      detect-project-state.sh            # Project state detection script
    rules/
      unified-orchestration.md           # Artifact conventions & conflict resolution
  examples/
    todo-app/                            # Full lifecycle example project
  docs/
    ECC-vs-BMAD-Analysis-Report.pdf      # Detailed comparison of both frameworks
    ECC-BMAD-Setup-Guide.pdf             # Step-by-step setup guide
```

## Implementation Workflow

When the project reaches the BUILDING phase, Claude follows a strict 5-step workflow for every story:

1. **Plan** — Read the story's acceptance criteria and outline the approach
2. **Write tests first** — TDD: write failing tests that match acceptance criteria
3. **Implement** — Write minimal code to make tests pass
4. **Review** — Self-review for security, edge cases, architecture adherence, and code quality
5. **Report** — Summarize what was built, show test output, flag any concerns

Tests and review are mandatory — Claude won't skip them even for "simple" features.

## How Is This Different From...

**...just using ECC?** ECC optimizes agent behavior but doesn't guide you through planning. You get great code but might build the wrong thing.

**...just using BMAD?** BMAD provides structure but doesn't optimize the AI agent during implementation. You get great plans but slower coding.

**...using both manually?** You'd need to know which slash commands to run at each phase, handle conflicts between them, and remember to save artifacts in the right places. claude-autopilot does all of this automatically.

## Limitations

This is a **semi-automatic** system (~90% hands-free). Claude Code doesn't support fully deterministic workflow routing — the detection hook informs Claude, and Claude follows the CLAUDE.md instructions semantically. This means:

- Claude may occasionally ask for confirmation at phase transitions (this is intentional)
- Ambiguous user intent triggers a clarification question rather than a wrong guess
- The system depends on artifacts being saved to conventional locations

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
