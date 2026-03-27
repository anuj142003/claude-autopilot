# claude-autopilot — Unified Development Orchestrator

You have two complementary AI development frameworks installed. This orchestrator automatically routes you to the right tools based on your project's lifecycle phase.

## How This Works

1. A SessionStart hook detects your project phase and outputs discovery paths
2. You use the discovery protocol below to find the right command for the task
3. You invoke real BMAD workflows and ECC agents — not behavioral descriptions

## Discovery Protocol

When you need a tool for the current task, discover it at runtime:

### Finding BMAD Workflows

BMAD provides structured workflows for planning, design, testing, and creative tasks.

1. Glob the manifest path from the hook output (typically `~/.bmad/cache/external-modules/**/bmad-skill-manifest.yaml`)
2. Read manifests to find commands matching your need — look at `canonicalId`, `description`, `type`, and `capabilities` fields
3. Once you find a match, read its `SKILL.md` or workflow `.md` file in the same directory for full instructions
4. Invoke via the Skill tool using the `canonicalId` as the skill name (e.g., `gds-create-prd`, `bmad-cis-design-thinking`, `bmad-tea`)

**Search tips:**
- Brainstorming/ideation: look for `brainstorm`, `design-thinking`, `innovation` in descriptions
- PRD creation: look for `prd`, `requirements` in canonicalId
- Architecture: look for `architecture`, `game-architecture` in canonicalId
- Stories/epics: look for `stories`, `epics`, `story` in canonicalId
- Testing: look for `testarch`, `test-design`, `test-review`, `atdd` in canonicalId
- Code review: look for `code-review` in canonicalId
- Sprint management: look for `sprint`, `retrospective` in canonicalId

### Finding ECC Agents

ECC provides model-optimized agents for implementation tasks. Each agent runs on a specific model (opus/sonnet/haiku) for cost efficiency.

1. Glob the agents path from the hook output (typically `~/.claude/agents/*.md`)
2. Read agent frontmatter for `name`, `description`, `model`, and `tools` fields
3. Dispatch via the Agent tool with `subagent_type` matching the agent name

**Key ECC agents and their models:**
- Agents are pre-configured with cost-appropriate models
- Deep reasoning tasks (planning, architecture) → typically opus
- Implementation tasks (code review, TDD, security) → typically sonnet
- Lightweight tasks (documentation) → typically haiku

### Finding ECC Skills

ECC skills are already listed in your context (in the system reminder). Invoke via the Skill tool by name.

## Decision Framework

The SessionStart hook tells you the current phase and whether to DISCOVER (search BMAD) or DELEGATE (dispatch ECC agents).

### Planning Phases (IDEATION → STORY_CREATION)

When the hook says `MODE: DISCOVER_AND_ROUTE`:

1. Read the `DISCOVER` instruction from the hook output
2. Search BMAD manifests for matching workflows
3. If a BMAD workflow is found, invoke it and follow its steps
4. If no BMAD workflow matches, use the `FALLBACK` from the hook output
5. Save the output artifact to the path specified in the hook's `ARTIFACT` field
6. When the artifact is saved, announce the phase transition and what comes next

### Building Phases (READY_TO_BUILD, BUILDING, BROWNFIELD)

When the hook says `MODE: DELEGATE_TO_ECC`:

1. Read stories from `_bmad-output/stories/` if available
2. For each story, follow this delegation pattern:
   a. **Plan**: Dispatch ECC planner agent with the story's acceptance criteria
   b. **Test**: Dispatch ECC tdd-guide agent to write failing tests
   c. **Implement**: Write minimal code to pass tests (main session or delegated)
   d. **Review**: Dispatch ECC code-reviewer agent to review the implementation
   e. **Security**: Dispatch ECC security-reviewer agent if the change touches auth, input handling, or APIs
   f. **Docs**: Dispatch ECC doc-updater agent if documentation needs updating
3. The main session acts as a thin orchestrator: read → dispatch → review output → report

**Cost optimization**: By delegating to ECC agents, bulk implementation work runs on sonnet/haiku instead of the main session's model. The main session handles only coordination and user communication.

### When Both Apply

- **Code review**: Search BMAD for review workflows (acceptance criteria validation) AND dispatch ECC code-reviewer (code quality). Use both.
- **Testing**: Search BMAD TEA module for test architecture AND dispatch ECC tdd-guide for test implementation. They complement each other.
- **User asks about planning while building**: For small changes, handle in ECC mode. For significant features, suggest switching to BMAD planning workflows first.

## Artifact Conventions

Planning artifacts must be saved to these locations for phase detection to work:

- Product brief: `_bmad-output/product-brief.md`
- PRD: `_bmad-output/prd.md`
- Architecture: `_bmad-output/architecture.md`
- UX design: `_bmad-output/ux-design.md`
- Stories: `_bmad-output/stories/<epic-name>/<story-name>.md`
- Sprint plans: `_bmad-output/sprints/<sprint-name>.md`
- Retrospectives: `_bmad-output/retros/<sprint-name>-retro.md`

## Conflict Resolution

If ECC and BMAD guidance conflicts:
- Code style and quality: ECC rules take precedence (language-specific, more granular)
- Process and methodology: BMAD workflows take precedence (designed for lifecycle management)
- Security: ECC always takes precedence (has runtime enforcement via hooks)
- Testing: Use BMAD TEA for test strategy/architecture, ECC tdd-guide for test implementation

## General Principles

- Invoke real commands — never role-play personas or describe framework behavior in prose
- Save all planning artifacts to `_bmad-output/` so phase detection stays accurate
- When the user's intent is ambiguous, ask: "Would you like to plan this (I'll find the right BMAD workflow) or build it (I'll delegate to ECC agents)?"
- At phase transitions, announce: "Phase complete. Next phase: [X]. I'll search for the right workflow."
- ECC hooks (formatting, type-checking, security scanning) are always active during implementation — let them work
