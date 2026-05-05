#!/bin/sh
set -eu

target=${SCAN_TARGET:-/repo}

gitleaks_status=0
grype_status=0
trivy_status=0
actionlint_status=0
zizmor_status=0
shellcheck_status=0

scan_dependencies=${SCAN_DEPENDENCIES:-auto}
scan_iac=${SCAN_IAC:-auto}
scan_github_actions=${SCAN_GITHUB_ACTIONS:-auto}
scan_shell=${SCAN_SHELL:-auto}

languages="none detected"
dependency_files="none detected"
infra_files="none detected"
ci_files="none detected"
shell_files="none detected"
run_grype=false
run_trivy=false
run_actionlint=false
run_shellcheck=false
shell_file_list=/tmp/kc-repo-scanner-shell-files

append_item() {
	current=$1
	item=$2

	if [ "$current" = "none detected" ]; then
		printf '%s' "$item"
	else
		printf '%s, %s' "$current" "$item"
	fi
}

has_file() {
	[ -f "$target/$1" ]
}

has_repo_file() {
	has_file "$1" || find "$target" -type d -name .git -prune -o -type f -name "$1" -print -quit | grep -q .
}

has_dir() {
	[ -d "$target/$1" ]
}

has_glob() {
	find "$target" -type d -name .git -prune -o "$@" -print -quit | grep -q .
}

has_workflow_files() {
	find "$target/.github/workflows" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) -print -quit | grep -q .
}

is_shell_shebang() {
	case $1 in
	'#'!'/'*'/sh'* | '#'!'/'*'/bash'* | '#'!'/'*'/dash'* | '#'!'/'*'/ksh'* | '#'!'/'*'env sh'* | '#'!'/'*'env bash'* | '#'!'/'*'env dash'* | '#'!'/'*'env ksh'*)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

detect_shell_files() {
	: >"$shell_file_list"

	find "$target" -type d -name .git -prune -o -type f \( \
		-name '*.sh' -o \
		-name '*.bash' -o \
		-name '*.dash' -o \
		-name '*.ksh' \
		\) -print >"$shell_file_list"

	find "$target" -type d -name .git -prune -o -type f -print | while IFS= read -r file; do
		first_line=$(sed -n '1p' "$file" 2>/dev/null || true)
		if is_shell_shebang "$first_line" && ! grep -Fxq "$file" "$shell_file_list"; then
			printf '%s\n' "$file" >>"$shell_file_list"
		fi
	done

	if [ -s "$shell_file_list" ]; then
		shell_files="$(wc -l <"$shell_file_list" | tr -d ' ') detected"
		run_shellcheck=true
	fi
}

detect_repo() {
	detect_shell_files

	if has_repo_file go.mod; then
		languages=$(append_item "$languages" "Go")
		dependency_files=$(append_item "$dependency_files" "go.mod")
		run_grype=true
	fi
	if has_repo_file go.sum; then
		dependency_files=$(append_item "$dependency_files" "go.sum")
		run_grype=true
	fi

	if has_repo_file package.json; then
		languages=$(append_item "$languages" "JavaScript/Node")
		dependency_files=$(append_item "$dependency_files" "package.json")
		run_grype=true
	fi
	for file in package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lockb; do
		if has_repo_file "$file"; then
			dependency_files=$(append_item "$dependency_files" "$file")
			run_grype=true
		fi
	done

	for file in pyproject.toml requirements.txt requirements-dev.txt Pipfile Pipfile.lock poetry.lock uv.lock; do
		if has_repo_file "$file"; then
			if [ "$languages" = "none detected" ] || ! printf '%s' "$languages" | grep -q 'Python'; then
				languages=$(append_item "$languages" "Python")
			fi
			dependency_files=$(append_item "$dependency_files" "$file")
			run_grype=true
		fi
	done

	if has_repo_file Cargo.toml; then
		languages=$(append_item "$languages" "Rust")
		dependency_files=$(append_item "$dependency_files" "Cargo.toml")
		run_grype=true
	fi
	if has_repo_file Cargo.lock; then
		dependency_files=$(append_item "$dependency_files" "Cargo.lock")
		run_grype=true
	fi

	for file in Gemfile Gemfile.lock; do
		if has_repo_file "$file"; then
			if [ "$languages" = "none detected" ] || ! printf '%s' "$languages" | grep -q 'Ruby'; then
				languages=$(append_item "$languages" "Ruby")
			fi
			dependency_files=$(append_item "$dependency_files" "$file")
			run_grype=true
		fi
	done

	for file in pom.xml build.gradle build.gradle.kts gradle.lockfile; do
		if has_repo_file "$file"; then
			if [ "$languages" = "none detected" ] || ! printf '%s' "$languages" | grep -q 'Java/JVM'; then
				languages=$(append_item "$languages" "Java/JVM")
			fi
			dependency_files=$(append_item "$dependency_files" "$file")
			run_grype=true
		fi
	done

	for file in composer.json composer.lock; do
		if has_repo_file "$file"; then
			if [ "$languages" = "none detected" ] || ! printf '%s' "$languages" | grep -q 'PHP'; then
				languages=$(append_item "$languages" "PHP")
			fi
			dependency_files=$(append_item "$dependency_files" "$file")
			run_grype=true
		fi
	done

	for file in mix.exs mix.lock; do
		if has_repo_file "$file"; then
			if [ "$languages" = "none detected" ] || ! printf '%s' "$languages" | grep -q 'Elixir'; then
				languages=$(append_item "$languages" "Elixir")
			fi
			dependency_files=$(append_item "$dependency_files" "$file")
			run_grype=true
		fi
	done

	if has_repo_file Dockerfile || has_glob -type f -name 'Dockerfile.*'; then
		infra_files=$(append_item "$infra_files" "Dockerfile")
		run_trivy=true
	fi
	for file in compose.yml compose.yaml docker-compose.yml docker-compose.yaml; do
		if has_repo_file "$file"; then
			infra_files=$(append_item "$infra_files" "$file")
			run_trivy=true
		fi
	done
	if has_glob -type f -name '*.tf'; then
		infra_files=$(append_item "$infra_files" "Terraform")
		run_trivy=true
	fi
	if has_dir charts || has_file Chart.yaml; then
		infra_files=$(append_item "$infra_files" "Helm")
		run_trivy=true
	fi
	if has_dir k8s || has_dir kubernetes || has_glob -type f \( -name 'kustomization.yml' -o -name 'kustomization.yaml' \); then
		infra_files=$(append_item "$infra_files" "Kubernetes")
		run_trivy=true
	fi

	if has_dir .github/workflows && has_workflow_files; then
		ci_files=$(append_item "$ci_files" "GitHub Actions")
		run_actionlint=true
	fi
	if has_file .gitlab-ci.yml; then
		ci_files=$(append_item "$ci_files" "GitLab CI")
	fi
	if has_dir .circleci; then
		ci_files=$(append_item "$ci_files" "CircleCI")
	fi
	if has_file .woodpecker.yml || has_file .woodpecker.yaml || has_dir .woodpecker; then
		ci_files=$(append_item "$ci_files" "Woodpecker CI")
	fi
	if has_file .drone.yml || has_file .drone.yaml; then
		ci_files=$(append_item "$ci_files" "Drone CI")
	fi

	case "$scan_dependencies" in
	true) run_grype=true ;;
	false) run_grype=false ;;
	auto) ;;
	*)
		printf 'invalid SCAN_DEPENDENCIES value: %s\n' "$scan_dependencies" >&2
		exit 1
		;;
	esac

	case "$scan_iac" in
	true) run_trivy=true ;;
	false) run_trivy=false ;;
	auto) ;;
	*)
		printf 'invalid SCAN_IAC value: %s\n' "$scan_iac" >&2
		exit 1
		;;
	esac

	case "$scan_github_actions" in
	true) run_actionlint=true ;;
	false) run_actionlint=false ;;
	auto) ;;
	*)
		printf 'invalid SCAN_GITHUB_ACTIONS value: %s\n' "$scan_github_actions" >&2
		exit 1
		;;
	esac

	case "$scan_shell" in
	true) run_shellcheck=true ;;
	false) run_shellcheck=false ;;
	auto) ;;
	*)
		printf 'invalid SCAN_SHELL value: %s\n' "$scan_shell" >&2
		exit 1
		;;
	esac
}

print_plan() {
	printf '\n==> Repository inventory\n'
	printf 'target: %s\n' "$target"
	if [ -d "$target/.git" ]; then
		printf 'git repository: yes\n'
	else
		printf 'git repository: no\n'
	fi
	printf 'languages: %s\n' "$languages"
	printf 'dependency files: %s\n' "$dependency_files"
	printf 'infra files: %s\n' "$infra_files"
	printf 'ci systems: %s\n' "$ci_files"
	printf 'shell files: %s\n' "$shell_files"

	printf '\n==> Enabled scanners\n'
	printf 'gitleaks: enabled\n'
	if [ "$run_grype" = true ]; then
		printf 'grype: enabled\n'
	else
		printf 'grype: skipped (no dependency manifests or locks detected)\n'
	fi
	if [ "$run_trivy" = true ]; then
		printf 'trivy misconfig: enabled\n'
	else
		printf 'trivy misconfig: skipped (no common Docker/IaC files detected)\n'
	fi
	if [ "$run_actionlint" = true ]; then
		printf 'actionlint: enabled\n'
		printf 'zizmor: enabled\n'
	else
		printf 'actionlint: skipped (no GitHub Actions workflow files detected)\n'
		printf 'zizmor: skipped (no GitHub Actions workflow files detected)\n'
	fi
	if [ "$run_shellcheck" = true ]; then
		printf 'shellcheck: enabled\n'
	else
		printf 'shellcheck: skipped (no shell files detected)\n'
	fi
}

run_gitleaks() {
	set -- --source "$target" --no-banner --exit-code 1
	if [ "${GITLEAKS_VERBOSE}" = 'true' ]; then
		set -- "$@" -v
	fi
	if [ "${GITLEAKS_REDACT}" = 'true' ]; then
		set -- "$@" --redact
	fi
	if [ -n "${GITLEAKS_REPORT_FORMAT}" ]; then
		set -- "$@" --report-format "${GITLEAKS_REPORT_FORMAT}" --report-path -
	fi

	printf '\n==> Secret scan (gitleaks)\n'
	if [ -d "$target/.git" ]; then
		git config --global --add safe.directory "$target"
		gitleaks detect "$@" || gitleaks_status=$?
	else
		gitleaks detect "$@" --no-git || gitleaks_status=$?
	fi
}

run_grype_scan() {
	printf '\n==> Vulnerability scan (grype)\n'
	if [ "$run_grype" = true ]; then
		grype "dir:$target" --exclude '**/.git' --fail-on "$GRYPE_FAIL_ON" -o table || grype_status=$?
	else
		printf 'skipped: no dependency manifests or lockfiles detected\n'
	fi
}

run_trivy_scan() {
	printf '\n==> Misconfiguration scan (trivy)\n'
	if [ "$run_trivy" = true ]; then
		set -- fs --scanners "$TRIVY_SCANNERS" --severity "$TRIVY_SEVERITY" --skip-dirs "$target/.git" --skip-version-check --exit-code 1 "$target"
		if [ "${TRIVY_SKIP_DB_UPDATE}" = 'true' ]; then
			set -- "$@" --skip-db-update --skip-java-db-update
		fi
		trivy "$@" || trivy_status=$?
	else
		printf 'skipped: no common Docker/IaC files detected\n'
	fi
}

run_actionlint_scan() {
	printf '\n==> Workflow lint (actionlint)\n'
	if [ "$run_actionlint" = true ]; then
		find "$target/.github/workflows" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) -exec actionlint -pyflakes= {} + || actionlint_status=$?
	else
		printf 'skipped: no GitHub Actions workflow files detected\n'
	fi
}

run_zizmor_scan() {
	printf '\n==> GitHub Actions security scan (zizmor)\n'
	if [ "$run_actionlint" = true ]; then
		zizmor --offline --strict-collection --collect=workflows,actions --persona=regular "$target" || zizmor_status=$?
	else
		printf 'skipped: no GitHub Actions workflow files detected\n'
	fi
}

run_shellcheck_scan() {
	printf '\n==> Shell lint (shellcheck)\n'
	if [ "$run_shellcheck" = true ]; then
		while IFS= read -r shell_file; do
			shellcheck "$shell_file" || shellcheck_status=$?
		done <"$shell_file_list"
	else
		printf 'skipped: no shell files detected\n'
	fi
}

print_status() {
	if [ "$gitleaks_status" -ne 0 ]; then
		printf 'gitleaks exited with status %s\n' "$gitleaks_status" >&2
	fi
	if [ "$grype_status" -ne 0 ]; then
		printf 'grype exited with status %s\n' "$grype_status" >&2
	fi
	if [ "$trivy_status" -ne 0 ]; then
		printf 'trivy exited with status %s\n' "$trivy_status" >&2
	fi
	if [ "$actionlint_status" -ne 0 ]; then
		printf 'actionlint exited with status %s\n' "$actionlint_status" >&2
	fi
	if [ "$zizmor_status" -ne 0 ]; then
		printf 'zizmor exited with status %s\n' "$zizmor_status" >&2
	fi
	if [ "$shellcheck_status" -ne 0 ]; then
		printf 'shellcheck exited with status %s\n' "$shellcheck_status" >&2
	fi
}

[ -d "$target" ] || {
	printf 'scan target not found: %s\n' "$target" >&2
	exit 1
}
[ -r "$target" ] && [ -x "$target" ] || {
	printf 'scan target is not readable/searchable by the scanner user: %s\n' "$target" >&2
	exit 1
}
mkdir -p "$XDG_CACHE_HOME" "$GRYPE_DB_CACHE_DIR"
unset GITLEAKS_CONFIG GITLEAKS_CONFIG_TOML

detect_repo
print_plan

if [ "${SCAN_INSPECT_ONLY:-false}" = 'true' ]; then
	exit 0
fi

run_gitleaks
run_grype_scan
run_trivy_scan
run_actionlint_scan
run_zizmor_scan
run_shellcheck_scan
print_status

[ "$gitleaks_status" -eq 0 ] && [ "$grype_status" -eq 0 ] && [ "$trivy_status" -eq 0 ] && [ "$actionlint_status" -eq 0 ] && [ "$zizmor_status" -eq 0 ] && [ "$shellcheck_status" -eq 0 ]
