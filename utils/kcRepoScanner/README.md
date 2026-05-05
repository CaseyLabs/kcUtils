# `kcRepoScanner`

A small Docker-based utility for scanning any local Git repository with one portable image. It detects the target repository shape first, then runs the scanners that apply.

## What It Runs

- `gitleaks` for secret scanning, including Git history when `.git/` is present
- `grype` for package vulnerability scanning when dependency manifests or lockfiles are present
- `trivy` for Dockerfile and IaC misconfiguration scanning when common infra files are present
- `actionlint` for GitHub Actions workflow linting when GitHub workflow files are present
- `shellcheck` for shell script linting when common shell script files or shell shebangs are present

The scanner does not run project-defined commands such as `npm install`, `go test`, Gradle tasks, or shell scripts from the target repository.

## Quick Start

From this project directory:

```sh
make scan TARGET=/path/to/your/repo
```

That builds the scanner image and runs it against the target directory.

If you prefer, `REPO=/path/to/your/repo` works too:

```sh
make scan REPO=/path/to/your/repo
```

## Quick Setup

```sh
# Set target repo on your system
myRepo="${HOME}/git/path/to/repo"

# Clone just this directory
git clone --depth=1 --filter=blob:none --sparse https://github.com/CaseyLabs/kcUtils.git kcTmp && cd kcTmp && git sparse-checkout set utils/kcRepoScanner && mv utils/kcRepoScanner ../kcRepoScanner && cd .. && rm -rf kcTmp && cd kcRepoScanner

# Run the security scan
make scan TARGET="${myRepo}"
```

## Useful Commands

```sh
make build
make inspect
make inspect TARGET=/path/to/your/repo
make scan
make scan TARGET=/path/to/your/repo
make scan-json TARGET=/path/to/your/repo
make clean
```

## Inspect First

Use `make inspect` when you do not know what language, dependency manager, infrastructure files, or CI system the target repository uses:

```sh
make inspect TARGET=/path/to/your/repo
```

That prints an inventory and the scan plan without running scanners. Example output:

```text
==> Repository inventory
target: /repo
git repository: yes
languages: Go, JavaScript/Node
dependency files: go.mod, go.sum, package.json, package-lock.json
infra files: Dockerfile, Terraform
ci systems: none detected
shell files: 2 detected

==> Enabled scanners
gitleaks: enabled
grype: enabled
trivy misconfig: enabled
actionlint: skipped (no GitHub Actions workflow files detected)
shellcheck: enabled
```

## Notes

- `make scan-json` enables verbose Gitleaks logs and prints JSON findings to stdout.
- The scanner always runs Gitleaks. Other scanners default to `auto` and are skipped when their input type is not present.
- The scanner exits non-zero if any enabled stage reports findings.
- `make scan` and `make scan-json` now do simple preflight checks for `docker` and the target directory before starting the container.
- The image mounts the target repository read-only at `/repo`.
- The target directory must be readable and searchable by the container's non-root scanner user.
- Workflow linting only runs when `.github/workflows/` exists in the target repository.
- ShellCheck runs for `*.sh`, `*.bash`, `*.dash`, `*.ksh`, and files with supported shell shebangs.
- Non-GitHub CI systems are detected in the inventory, but only GitHub Actions currently has a built-in linter.

## Runtime Options

You can override scanner settings directly with `docker run` if needed:

```sh
docker build -t kc-repo-scanner:local .

docker run --rm \
  --mount type=bind,src="/path/to/repo",dst=/repo,readonly \
  -e GITLEAKS_VERBOSE=true \
  -e GITLEAKS_REPORT_FORMAT=json \
  -e GITLEAKS_REDACT=false \
  -e GRYPE_FAIL_ON=critical \
  -e TRIVY_SCANNERS=misconfig \
  -e TRIVY_SEVERITY=HIGH,CRITICAL \
  -e SCAN_DEPENDENCIES=auto \
  -e SCAN_IAC=auto \
  -e SCAN_GITHUB_ACTIONS=auto \
  -e SCAN_SHELL=auto \
  kc-repo-scanner:local
```

The `SCAN_DEPENDENCIES`, `SCAN_IAC`, `SCAN_GITHUB_ACTIONS`, and `SCAN_SHELL` options accept `auto`, `true`, or `false`. Use `true` to force a scanner on and `false` to force it off.

To inspect without scanning:

```sh
docker run --rm \
  --mount type=bind,src="/path/to/repo",dst=/repo,readonly \
  -e SCAN_INSPECT_ONLY=true \
  kc-repo-scanner:local
```

## Published Image

This repository can publish `kcRepoScanner` to GitHub Container Registry as:

```sh
docker pull ghcr.io/caseylabs/kcutils/kcreposcanner:latest
```

You can also run that image directly if it has already been published:

```sh
reposcan() {
  docker run --rm \
  --mount type=bind,src="$1",dst=/repo,readonly \
  ghcr.io/caseylabs/kcutils/kcreposcanner:latest
}

# Then:
reposcan ~/path/to/repo
```
