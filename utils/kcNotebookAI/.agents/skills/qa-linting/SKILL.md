---
name: qa-linting
description: Run the local validation checks for scripts, JSON, Gemini skills, and generated markdown.
---

# QA Linting

Use non-mutating validation by default:

```bash
jq . .gemini/settings.json
shellcheck run_workflow.sh
shfmt -d run_workflow.sh
gemini skills list
```

For generated summaries and guidance files, run markdown linting when `markdownlint` or `markdownlint-cli` is installed:

```bash
markdownlint -c .markdownlint.json README.md AGENTS.md .agents/skills/**/*.md .gemini/agents/*.md
```

Only use `--fix` or `shfmt -w` when the task explicitly includes formatting edits.
