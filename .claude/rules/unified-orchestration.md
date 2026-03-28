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
