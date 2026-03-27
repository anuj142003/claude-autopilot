<p align="center">
  <h1 align="center">claude-autopilot</h1>
  <p align="center">
    <strong>Discovers and invokes the right BMAD workflow or ECC agent based on your project's lifecycle phase</strong>
  </p>
  <p align="center">
    A thin orchestration layer that sits on top of <a href="https://github.com/affaan-m/everything-claude-code">everything-claude-code</a> and <a href="https://github.com/bmad-code-org/BMAD-METHOD">BMAD-METHOD</a> — detecting your project phase, discovering available commands at runtime, and routing to real workflows with cost-optimized model selection.
  </p>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> &bull;
  <a href="#how-it-works">How It Works</a> &bull;
  <a href="#phase-detection">Phase Detection</a> &bull;
  <a href="#cost-optimization">Cost Optimization</a> &bull;
  <a href="#configuration">Configuration</a> &bull;
  <a href="#contributing">Contributing</a>
</p>

---

## What is claude-autopilot?

**claude-autopilot is NOT a fork or bundle of ECC or BMAD.** It does not include either framework — you install them separately. What it provides is a thin **orchestration layer** that sits on top of both and automatically routes to the right tools based on where your project is in its lifecycle.

Think of it like a traffic controller: ECC and BMAD are the roads, and claude-autopilot decides which road to take at any given moment — discovering available commands at runtime rather than maintaining a static registry.

## About the Frameworks

### everything-claude-code (ECC)

[ECC](https://github.com/affaan-m/everything-claude-code) by Affaan Mustafa is a comprehensive toolkit that optimizes Claude Code's behavior during **implementation**. It installs globally into `~/.claude/` and provides:

- **Rules** — language-specific coding standards (Python, TypeScript, Go, etc.)
- **Hooks** — auto-formatting, type-checking, security scanning on every code change
- **Skills** — TDD workflows, code review, continuous learning
- **Agents** — model-optimized sub-agents (opus for planning, sonnet for implementation, haiku for docs)

ECC makes Claude write better code, but it doesn't help you figure out *what* to build.

### BMAD-METHOD

[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) by Brian (BMad) Madison is a structured agile workflow system for **planning and design**. It installs globally to `~/.bmad/` and provides:

- **Workflows** — guided brainstorming, requirements elicitation, architecture design, story creation
- **Slash commands** — 60+ discoverable commands with manifests (`bmad-skill-manifest.yaml`)
- **Document templates** — product briefs, PRDs, architecture docs, user stories with acceptance criteria
- **Test architecture** — TEA module for test strategy and ATDD

BMAD ensures you build the *right thing*, but it doesn't optimize the AI agent during coding.

### The Gap

Neither framework knows about the other. If you install both, you need to manually decide when to use BMAD workflows vs ECC agents, which slash commands to run, and how to transition between planning and building. **claude-autopilot fills this gap.**

## What claude-autopilot Does

1. **Detects** your project's lifecycle phase on every session start
2. **Discovers** available BMAD workflows and ECC agents at runtime by scanning manifest files and agent directories
3. **Routes** to real commands with cost-optimized model selection — BMAD workflows for planning, ECC agents for building

You just type what you want. The orchestrator finds and invokes the right tool.

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

Three layers work together to create automatic discovery and routing:

```
Session Start
     |
     v
[SessionStart Hook] ──> detect-project-state.sh
     |                        |
     |                   Scans for:
     |                   - BMAD artifacts (PRD, architecture, stories)
     |                   - Source code & tests
     |                   - Framework install paths
     |                        |
     v                        v
[CLAUDE.md]  <────── Phase + Discovery Paths
     |                (phase, BMAD manifest paths, ECC agent paths)
     |
     v
[Discovery Protocol]
     |
     ├── Planning phases ──> Discover BMAD workflows
     |                       (search manifests, invoke via Skill tool)
     |
     └── Building phases ──> Delegate to ECC agents
                             (model-optimized: opus/sonnet/haiku)
```

### The Key Insight

Claude Code's `SessionStart` hook runs a shell script that outputs the current phase **and** the paths where BMAD and ECC commands can be discovered. The `CLAUDE.md` teaches Claude a **discovery protocol** — how to search manifest files, match commands to the current need, and invoke them. This means the orchestrator never needs updating when BMAD or ECC add new commands.

## Phase Detection

The detection script inspects your project directory and determines the lifecycle phase:

| Phase | Trigger | Action |
|-------|---------|--------|
| `IDEATION` | No artifacts, no source code | Discovers BMAD brainstorming/ideation workflows |
| `ANALYSIS` | BMAD dir exists, no brief/PRD | Discovers BMAD analysis/research workflows |
| `PLANNING` | Product brief exists, no PRD | Discovers BMAD PRD creation workflows |
| `SOLUTIONING` | PRD exists, no architecture doc | Discovers BMAD architecture/design workflows |
| `STORY_CREATION` | PRD + architecture, no stories | Discovers BMAD story/epic creation workflows |
| `READY_TO_BUILD` | Stories exist, no source code | Delegates to ECC agents (planner, tdd-guide, code-reviewer) |
| `BUILDING` | Stories + source code exist | Delegates to ECC agents with story acceptance criteria |
| `BROWNFIELD` | Source code but no BMAD artifacts | Delegates to ECC agents; offers BMAD for retroactive planning |

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

## Cost Optimization

During BUILDING phases (where most tokens are spent), claude-autopilot delegates work to ECC agents that run on cost-appropriate models instead of doing everything in the main session:

| Task | Delegated To | Model | Cost Tier |
|------|-------------|-------|-----------|
| Implementation planning | ECC planner agent | Opus | Premium (but scoped to planning only) |
| Writing tests (TDD) | ECC tdd-guide agent | Sonnet | Standard |
| Code review | ECC code-reviewer agent | Sonnet | Standard |
| Security scanning | ECC security-reviewer agent | Sonnet | Standard |
| Documentation updates | ECC doc-updater agent | Haiku | Economy |

The main session acts as a **thin orchestrator** during building: read the story, decide which agent to dispatch, review the output, and report back. Bulk implementation work runs on sonnet/haiku rather than the main session's model, reducing cost without sacrificing quality.

During PLANNING phases, BMAD workflows run interactively in the main session since they require back-and-forth user collaboration.

## Example Project

The `examples/todo-app/` directory contains a starter project that demonstrates the full lifecycle. Clone it and try:

```bash
cd examples/todo-app
claude
# Say: "I want to build a simple todo app with user authentication"
# Claude will detect IDEATION phase and discover BMAD planning workflows automatically
```

As you progress through planning phases, the detection script picks up new artifacts and transitions to the next phase. See the [example README](examples/todo-app/README.md) for a full walkthrough.

## Configuration

### Customizing Detection

Edit `.claude/hooks/detect-project-state.sh` to customize:

- **File paths** — if your BMAD artifacts are in different locations
- **Phase logic** — if you want different transition conditions
- **Discovery paths** — if BMAD or ECC are installed in non-standard locations
- **Additional checks** — add CI status, branch patterns, etc.

### Customizing Routing

Edit `CLAUDE.md` to customize:

- **Discovery protocol** — adjust how Claude searches for commands
- **Routing rules** — change when Claude uses BMAD vs ECC
- **Delegation patterns** — modify which agents handle which tasks
- **Team conventions** — add project-specific instructions

### Conflict Resolution

| Conflict | Resolution |
|----------|------------|
| Code style (ECC) vs process (BMAD) | ECC rules for code quality, BMAD workflows for methodology |
| Both have testing workflows | BMAD TEA for test strategy/architecture, ECC tdd-guide for test implementation |
| Both have code review | BMAD for acceptance criteria validation, ECC code-reviewer for code quality |
| Rules overlap | ECC rules are language-specific, BMAD is process-specific — they complement |

## Architecture

```
claude-autopilot/
  CLAUDE.md                              # Discovery protocol + routing rules + delegation instructions
  install.sh                             # One-command installer with prerequisite detection
  .claude/
    settings.json                        # SessionStart hook configuration
    hooks/
      detect-project-state.sh            # Phase detection + framework discovery paths
    rules/
      unified-orchestration.md           # Artifact conventions + routing rule reference
  examples/
    todo-app/                            # Full lifecycle example project
  docs/
    ECC-vs-BMAD-Analysis-Report.pdf      # Detailed comparison of both frameworks
    ECC-BMAD-Setup-Guide.pdf             # Step-by-step setup guide
```

## Implementation Workflow

When the project reaches the BUILDING phase, the orchestrator delegates to ECC agents following a strict workflow for every story:

1. **Plan** — Dispatch ECC planner agent with story acceptance criteria
2. **Write tests first** — Dispatch ECC tdd-guide agent for TDD (write failing tests first)
3. **Implement** — Write minimal code to make tests pass
4. **Review** — Dispatch ECC code-reviewer agent for code quality review
5. **Security** — Dispatch ECC security-reviewer if the change touches auth, input handling, or APIs
6. **Report** — Summarize what was built, show test output, flag any concerns

The main session orchestrates this pipeline; individual agents handle the heavy lifting on cost-appropriate models.

## How Is This Different From...

**...just using ECC?** ECC optimizes agent behavior but doesn't guide you through planning. You get great code but might build the wrong thing.

**...just using BMAD?** BMAD provides structure but doesn't optimize the AI agent during implementation. You get great plans but slower coding.

**...using both manually?** You'd need to know which slash commands to run at each phase, handle conflicts between them, and remember to save artifacts in the right places. claude-autopilot discovers and routes automatically.

## Limitations

This is a **semi-automatic** system (~90% hands-free). Claude Code doesn't support fully deterministic workflow routing — the detection hook informs Claude, and Claude follows the CLAUDE.md instructions semantically. This means:

- Claude may occasionally ask for confirmation at phase transitions (this is intentional)
- Ambiguous user intent triggers a clarification question rather than a wrong guess
- The system depends on artifacts being saved to conventional locations
- Discovery adds a small number of tool calls (manifest reads) — mitigated by on-demand scanning

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
