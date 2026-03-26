# Example: Todo App — Full Lifecycle Walkthrough

This example demonstrates how claude-autopilot guides you through the complete development lifecycle — from idea to implementation — without manual slash commands.

## Setup

```bash
# 1. Make sure claude-autopilot is installed in this directory
cd examples/todo-app
bash ../../install.sh

# 2. Launch Claude Code
claude
```

## What Happens at Each Phase

### Phase 1: IDEATION (you start here)

The detection script finds no artifacts and no source code. Claude enters BMAD mode as Mary (Analyst).

**Try saying:** "I want to build a simple todo app with user authentication and team sharing"

Claude will guide you through brainstorming and produce `_bmad-output/product-brief.md`.

### Phase 2: PLANNING

Next session, the hook detects the product brief. Claude becomes John (PM) and guides PRD creation.

**Try saying:** "Let's create the requirements document"

Claude uses Socratic questioning to refine requirements and produces `_bmad-output/prd.md`.

### Phase 3: SOLUTIONING

The hook detects the PRD. Claude becomes Winston (Architect) and guides system design.

**Try saying:** "What architecture should we use?"

Claude produces `_bmad-output/architecture.md`.

### Phase 4: STORY_CREATION

Architecture exists. Claude becomes Bob (Scrum Master) and creates stories.

**Try saying:** "Break this down into implementable stories"

Claude creates files in `_bmad-output/stories/`.

### Phase 5: BUILDING

Stories exist. Claude switches to ECC mode. Hooks auto-format, type-check, and security-scan.

**Try saying:** "Let's implement the user auth story"

Claude references the story's acceptance criteria and writes code with ECC quality enforcement.

## Simulating Phase Progression

If you want to skip ahead to see how different phases behave, create the artifacts manually:

```bash
# Jump to PLANNING phase
mkdir -p _bmad-output
echo "# Product Brief\n\nA todo app with auth and team sharing." > _bmad-output/product-brief.md

# Jump to SOLUTIONING phase
echo "# PRD\n\n## Features\n- User auth\n- Todo CRUD\n- Team sharing" > _bmad-output/prd.md

# Jump to STORY_CREATION phase
echo "# Architecture\n\n## Stack\n- Next.js + PostgreSQL" > _bmad-output/architecture.md

# Jump to BUILDING phase
mkdir -p _bmad-output/stories/auth
echo "# Story: User Registration\n\n## Acceptance Criteria\n- User can sign up with email" > _bmad-output/stories/auth/user-registration.md
mkdir -p src
echo "// placeholder" > src/index.ts
```

Then run `claude` and observe how it automatically enters the right mode.

## Resetting

To start over:

```bash
rm -rf _bmad-output src
```
