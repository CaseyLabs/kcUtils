# kcAgents

## Overview

Experimental AI config and skills files for OpenAI Codex CLI, aimed at reducing context window size and token usage.

## Project Layout

- This directory contains reusable Codex CLI configuration templates and custom agent guidance.
- The files are intended to be copied or merged into an end user's Codex configuration, not executed directly from this repository.

```text
.
└── codex-cli/                   # Codex CLI config template files
    ├── agents/
    │   └── skills/              # project-level custom AI Agent skill templates
    │       ├── security-review/
    │       └── token-efficient-delegation/
    ├── codex-global.md          # template for ~/.codex/AGENTS.md
    ├── config.toml              # template for ~/.codex/config.toml
    └── codex-local.md           # template for project-level <repo-root>/AGENTS.md
```

## Install Locations

Use these destinations on the end user's system:

| Template path | Destination |
| --- | --- |
| `codex-cli/config.toml` | `~/.codex/config.toml` |
| `codex-cli/codex-global.md` | `~/.codex/AGENTS.md` |
| `codex-cli/codex-local.md` | `<repo-root>/AGENTS.md` |
| `codex-cli/agents/skills/security-review/` | `<repo-root>/.agents/skills/security-review/` |
| `codex-cli/agents/skills/token-efficient-delegation/` | `<repo-root>/.agents/skills/token-efficient-delegation/` |

## Example Install

Use the Makefile for normal installs:

```sh
make help
```

This prints the available Makefile targets from the target descriptions in `Makefile`.

```sh
make install
```

This installs the user-level Codex config:

- `~/.codex/config.toml`
- `~/.codex/AGENTS.md`

Install the repository-local `AGENTS.md` and project skills separately because the target repository must be explicit:

```sh
make repo TARGET=/path/to/repo
```

Each target that already exists is backed up first with a suffix like `.bak-YYYYMMDD-HHMMSS`.

Run a dry-run check before installing or restoring:

```sh
make test
```

Restore the user-level Codex config from the newest available backups:

```sh
make restore
```

Restore the repository-local `AGENTS.md` and project skills from the newest available backups:

```sh
make restore-repo TARGET=/path/to/repo
```

## Usage

After installing, start Codex as normal:

```sh
codex
```
