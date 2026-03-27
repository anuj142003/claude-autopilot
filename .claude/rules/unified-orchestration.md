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

When completing a planning phase, always:
1. Save the artifact to the correct location above
2. Announce the transition explicitly to the user
3. State what the next recommended phase is
4. Search for the appropriate workflow/agent for the next phase

## Routing Rules

### Planning Phases (MODE: DISCOVER_AND_ROUTE)

- Search BMAD manifests at the path provided by the SessionStart hook
- Match on `canonicalId`, `description`, and `capabilities` fields
- Invoke the matched workflow via its skill ID
- Fall back to ECC planner/architect agents if no BMAD match

### Building Phases (MODE: DELEGATE_TO_ECC)

- Read story acceptance criteria from `_bmad-output/stories/`
- Delegate to ECC agents for cost-optimized execution:
  - planner (opus) for implementation planning
  - tdd-guide (sonnet) for test-first development
  - code-reviewer (sonnet) for code quality review
  - security-reviewer (sonnet) for security scanning
  - doc-updater (haiku) for documentation
- Main session acts as orchestrator, not implementer

## Conflict Resolution

If ECC rules and BMAD workflow guidance conflict:
- For code style and quality: ECC rules take precedence (language-specific and more granular)
- For process and methodology: BMAD workflows take precedence (designed for lifecycle management)
- For security: ECC always takes precedence (has runtime enforcement)
- For testing: BMAD TEA for strategy/architecture, ECC tdd-guide for implementation
