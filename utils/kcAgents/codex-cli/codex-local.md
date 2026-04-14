# Repository AGENTS.md

Instructions for Codex and other coding agents working in this repository.

## Goals

- Make the smallest correct change that satisfies the task.
- Preserve existing project conventions unless there is a clear reason to change them.

## Project defaults

- This is a container-first repository.
- Use Docker for build, test, run, and other development workflows and tooling.
- Prefer non-root containers unless the task explicitly requires elevated privileges.
- Provide and use a `Makefile` as the main Docker-driven developer entrypoint, with a minimal amount of command options: make build/test/run/stop/clean/logs/shell. Makefile commands should call an individual `scripts/` shell script for each individual command.
- Use TDD by default for new features, bug fixes, and behavior changes:
  - write or update a failing test first when practical.
  - implement the smallest change needed to make the test pass.
  - refactor only after behavior is covered.
  - HOWEVER, write tests for CODE only, do not write tests for written content, filenames or directory structures, etc.
- Pin versions, images, and actions where practical.

## Implementation rules

- Keep secrets, tokens, and credentials out of code, logs, fixtures, and documentation.
- Prefer explicit error propagation or clear surfaced failures over silent fallbacks.
- When behavior changes, update or add the relevant tests.

## Verification

- After making changes, run the relevant existing checks for the files touched.
- Prefer the smallest set of checks that gives high confidence, then expand if needed.
- If tests or checks cannot be run, state that clearly and explain why.
- Do not claim success without verification.

## Documentation

- Update documentation when code changes materially affect setup, usage, behavior, configuration, or developer workflows.
- Keep documentation changes tightly scoped to the task.
- Ensure developer documentation reflects the actual Docker and Makefile workflow.

## Review tasks

- For review requests, prioritize findings: bugs, risks, behavioral regressions, and missing tests.
- Present findings before summaries when practical.

## Output expectations

- Summarize what changed and why. Keep responses concise and specific.
