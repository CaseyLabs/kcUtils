SHELL := /bin/sh

TEMPLATE_DIR := codex-cli
CODEX_HOME ?= $(HOME)/.codex ## Default: $(HOME)/.codex
TARGET ?= ## Repository root for repo and restore-repo
BACKUP_STAMP ?= $(shell date +%Y%m%d-%H%M%S) ## Default: current timestamp
SKILL_NAMES := security-review token-efficient-delegation

.PHONY: help test install install-config repo install-repo install-repo-agents install-repo-skills restore restore-config restore-repo restore-repo-agents restore-repo-skills install-local restore-local

help: ## Show available make targets and variables
	@awk 'BEGIN { \
		printf "%s\n\n", "Codex CLI template installer"; \
		printf "%s\n", "Targets:"; \
	} /^[[:alnum:]_.-]+:([^=]|$$).*## / { \
		name=$$1; sub(/:.*/, "", name); \
		desc=$$0; sub(/^[^#]*## /, "", desc); \
		printf "  make %-24s %s\n", name, desc; \
	} END { printf "\n%s\n", "Variables:"; }' $(MAKEFILE_LIST)
	@awk '/^[A-Z_][A-Z0-9_]*[[:space:]]*[?:+]?=.*## / { \
		name=$$0; sub(/[[:space:]]*[?:+]?=.*/, "", name); \
		desc=$$0; sub(/^[^#]*## /, "", desc); \
		printf "  %-29s %s\n", name "=value", desc; \
	}' $(MAKEFILE_LIST)

test: ## Dry-run the install and restore make targets
	@$(MAKE) --dry-run install repo restore restore-repo CODEX_HOME=/tmp/kcagents-codex-home TARGET=/tmp/kcagents-target BACKUP_STAMP=test

install: install-config ## Install user-level Codex config

restore: restore-config ## Restore user-level Codex config from latest backups

repo: install-repo ## Install repository AGENTS.md and project skills

install-repo: install-repo-agents install-repo-skills ## Install all repository-level files

install-config: ## Install user-level config.toml and AGENTS.md
	@set -eu; \
	mkdir -p "$(CODEX_HOME)"; \
	for target in "$(CODEX_HOME)/config.toml" "$(CODEX_HOME)/AGENTS.md"; do \
		if [ -e "$$target" ]; then \
			backup="$$target.bak-$(BACKUP_STAMP)"; \
			cp -a "$$target" "$$backup"; \
			printf 'Backed up %s -> %s\n' "$$target" "$$backup"; \
		fi; \
	done; \
	cp "$(TEMPLATE_DIR)/config.toml" "$(CODEX_HOME)/config.toml"; \
	cp "$(TEMPLATE_DIR)/codex-global.md" "$(CODEX_HOME)/AGENTS.md"; \
	printf 'Installed %s\n' "$(CODEX_HOME)/config.toml"; \
	printf 'Installed %s\n' "$(CODEX_HOME)/AGENTS.md"

install-repo-agents: ## Install repository-level AGENTS.md
	@set -eu; \
	if [ -z "$(TARGET)" ]; then \
		printf '%s\n' 'TARGET is required. Example: make repo TARGET=/path/to/repo' >&2; \
		exit 2; \
	fi; \
	mkdir -p "$(TARGET)"; \
	target="$(TARGET)/AGENTS.md"; \
	if [ -e "$$target" ]; then \
		backup="$$target.bak-$(BACKUP_STAMP)"; \
		cp -a "$$target" "$$backup"; \
		printf 'Backed up %s -> %s\n' "$$target" "$$backup"; \
	fi; \
	cp "$(TEMPLATE_DIR)/codex-local.md" "$$target"; \
	printf 'Installed %s\n' "$$target"

install-repo-skills: ## Install repository-level skills
	@set -eu; \
	if [ -z "$(TARGET)" ]; then \
		printf '%s\n' 'TARGET is required. Example: make repo TARGET=/path/to/repo' >&2; \
		exit 2; \
	fi; \
	skills_dir="$(TARGET)/.agents/skills"; \
	mkdir -p "$$skills_dir"; \
	for skill in $(SKILL_NAMES); do \
		source="$(TEMPLATE_DIR)/agents/skills/$$skill"; \
		target="$$skills_dir/$$skill"; \
		if [ ! -d "$$source" ]; then \
			printf 'Missing skill template: %s\n' "$$source" >&2; \
			exit 1; \
		fi; \
		if [ -e "$$target" ]; then \
			backup="$$target.bak-$(BACKUP_STAMP)"; \
			cp -a "$$target" "$$backup"; \
			printf 'Backed up %s -> %s\n' "$$target" "$$backup"; \
			rm -rf "$$target"; \
		fi; \
		cp -a "$$source" "$$skills_dir/"; \
		printf 'Installed %s\n' "$$target"; \
	done

restore-config: ## Restore user-level config.toml and AGENTS.md
	@set -eu; \
	for target in "$(CODEX_HOME)/config.toml" "$(CODEX_HOME)/AGENTS.md"; do \
		latest=$$(ls -dt "$$target".bak-* 2>/dev/null | head -n 1 || true); \
		if [ -z "$$latest" ]; then \
			printf 'No backup found for %s\n' "$$target"; \
		else \
			cp -a "$$latest" "$$target"; \
			printf 'Restored %s -> %s\n' "$$latest" "$$target"; \
		fi; \
	done

restore-repo: restore-repo-agents restore-repo-skills ## Restore repository-level files

restore-repo-agents: ## Restore repository-level AGENTS.md
	@set -eu; \
	if [ -z "$(TARGET)" ]; then \
		printf '%s\n' 'TARGET is required. Example: make restore-repo TARGET=/path/to/repo' >&2; \
		exit 2; \
	fi; \
	target="$(TARGET)/AGENTS.md"; \
	latest=$$(ls -dt "$$target".bak-* 2>/dev/null | head -n 1 || true); \
	if [ -z "$$latest" ]; then \
		printf 'No backup found for %s\n' "$$target"; \
	else \
		cp -a "$$latest" "$$target"; \
		printf 'Restored %s -> %s\n' "$$latest" "$$target"; \
	fi

restore-repo-skills: ## Restore repository-level skills
	@set -eu; \
	if [ -z "$(TARGET)" ]; then \
		printf '%s\n' 'TARGET is required. Example: make restore-repo TARGET=/path/to/repo' >&2; \
		exit 2; \
	fi; \
	skills_dir="$(TARGET)/.agents/skills"; \
	for skill in $(SKILL_NAMES); do \
		target="$$skills_dir/$$skill"; \
		latest=$$(ls -dt "$$target".bak-* 2>/dev/null | head -n 1 || true); \
		if [ -z "$$latest" ]; then \
			printf 'No backup found for %s\n' "$$target"; \
		else \
			rm -rf "$$target"; \
			cp -a "$$latest" "$$target"; \
			printf 'Restored %s -> %s\n' "$$latest" "$$target"; \
		fi; \
	done

install-local: ## Install repository files into REPO_ROOT
	@$(MAKE) repo TARGET="$(REPO_ROOT)"

restore-local: ## Restore repository files in REPO_ROOT
	@$(MAKE) restore-repo TARGET="$(REPO_ROOT)"
