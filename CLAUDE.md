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
