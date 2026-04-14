# Global Codex Guidance (~/.codex/AGENTS.md)

- For version-sensitive tasks, verify commands, flags, APIs, package versions, and installation steps against the latest official documentation before acting.

- When using external docs, fetch only the minimum relevant material needed for the task.

- Use `$token-efficient-delegation` for broad, high-risk, or multi-file tasks where profile choice or bounded subagents could reduce token usage.

- After code changes, run the relevant project checks that already exist, such as tests, linting, formatting, and type checks.

- Update project documentation when code changes materially affect setup, usage, behavior, or developer workflows.

- Any shell scripts created or modified must be compatible with both `bash` and `zsh`. When writing shell scripts, prefer simple procedural scripts over complex function scripts. After modifying shell scripts, run `shellcheck` and `shfmt` if available, and fix relevant issues.
