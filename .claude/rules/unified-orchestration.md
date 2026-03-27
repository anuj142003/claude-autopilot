# Unified ECC + BMAD Orchestration Rules

## Artifact Location Conventions

All BMAD planning artifacts MUST be saved to `_bmad-output/` with these filenames:

- Product brief: `_bmad-output/product-brief.md`
- PRD: `_bmad-output/prd.md`
- Architecture: `_bmad-output/architecture.md`
- UX design: `_bmad-output/ux-design.md`
- Stories: `_bmad-output/stories/<epic-name>/<story-name>.md`
- Sprint plans: `_bmad-output/sprints/<sprint-name>.md`
- Retrospectives: `_bmad-output/retros/<sprint-name>-retro.md`

This convention ensures the SessionStart hook can detect project state accurately.

## Phase Transition Signals

When completing a BMAD planning phase, always:
1. Save the artifact to the correct location above
2. Announce the transition explicitly to the user
3. State what the next recommended phase is

## Implementation Rules

During ECC implementation mode:
- Always check `_bmad-output/stories/` for acceptance criteria before implementing a feature
- Reference the architecture document from `_bmad-output/architecture.md` for design decisions
- Follow ECC language-specific rules (loaded from `~/.claude/rules/` or `.claude/rules/`)
- Let ECC hooks handle formatting, type-checking, and security scanning automatically

## Conflict Resolution

If ECC rules and BMAD workflow guidance conflict:
- For code style and quality: ECC rules take precedence (they're language-specific and more granular)
- For process and methodology: BMAD workflows take precedence (they're designed for lifecycle management)
- For security: ECC always takes precedence (it has runtime enforcement)
