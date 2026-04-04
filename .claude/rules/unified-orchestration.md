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
- Design tokens: `_bmad-output/design-tokens.md`
- Brand guide: `_bmad-output/brand-guide.md`
- Component specs: `_bmad-output/component-specs.md`

This convention ensures the SessionStart hook can detect project state accurately.

## Phase Transition Signals

When completing a planning phase, always:
1. Save the artifact to the correct location above
2. Announce the transition explicitly to the user
3. Suggest running `/autopilot` to see next available actions

## UI/UX Design Skills

When [UI UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) skills are installed, `/autopilot` discovers and surfaces them during design and build phases. These skills are a separate prerequisite — autopilot orchestrates them but does not ship them.

Core skills (no external dependencies): `ui-ux-pro-max`, `design-system`, `brand`, `ui-styling`
Optional skills (require Gemini API key): `design`, `slides`, `banner-design`

Save design outputs to `_bmad-output/` using the artifact filenames above so phase detection stays accurate.
