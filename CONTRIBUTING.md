# Contributing to claude-autopilot

Thanks for your interest in contributing! This project bridges two major AI development frameworks, and there's plenty of room to improve it.

## How to Contribute

1. **Fork** the repository
2. **Create a branch** for your feature or fix (`git checkout -b feature/my-improvement`)
3. **Make your changes** and test them
4. **Submit a pull request** with a clear description of what you changed and why

## Areas Where Help is Needed

### Detection Improvements
- Better heuristics for brownfield project detection
- CI/CD status integration (detect if builds are passing/failing)
- Git branch pattern detection (feature branches, release branches)
- Support for monorepo structures

### `/autopilot` Command
- Improve `/autopilot` command menu UX
- Better phase-to-BMAD-phase mapping in the CSV filter
- Support for additional BMAD modules
- Automated end-to-end testing of the `/autopilot` flow

### Framework Support
- Additional BMAD workflow mappings
- Support for other AI coding frameworks (Cursor rules, Windsurf, etc.)

### Documentation
- Video walkthroughs of the full lifecycle
- Troubleshooting guides for common edge cases
- Translations

## Testing Your Changes

The detection script can be tested locally:

```bash
cd examples/todo-app
bash ../../.claude/hooks/detect-project-state.sh
# Should output lifecycle phase and end with:
# "Type /autopilot to see available actions for this phase"

# Create a fake PRD to test phase progression
mkdir -p _bmad-output
echo "# PRD" > _bmad-output/prd.md
bash ../../.claude/hooks/detect-project-state.sh
# Should output: LIFECYCLE PHASE: SOLUTIONING
```

## Code Style

- Shell scripts: Use `set -euo pipefail`, quote variables, use `[[ ]]` for conditionals
- Markdown: Follow existing formatting conventions
- Keep the install script idempotent (safe to run multiple times)

## Reporting Issues

When reporting issues, please include:
- Your Claude Code version (`claude --version`)
- Your OS and shell
- Whether ECC and BMAD are installed and which versions
- The output of `bash .claude/hooks/detect-project-state.sh` from your project directory
