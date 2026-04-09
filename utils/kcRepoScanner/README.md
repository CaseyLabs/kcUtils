# `kcRepoScanner`

A small Docker-based utility for scanning any local Git repository with one portable image.

## What It Runs

- `gitleaks` for secret scanning, including Git history when `.git/` is present
- `grype` for package vulnerability scanning
- `trivy` for Dockerfile and IaC misconfiguration scanning
- `actionlint` for GitHub Actions workflow linting

## Quick Start

From this project directory:

```sh
make scan
```

That builds the scanner image and runs it against this project directory by default.

To scan a different local repository:

```sh
make scan TARGET=/absolute/path/to/repo
```

## Useful Commands

```sh
make build
make scan
make scan TARGET=/home/user/git/tmp/numa-fork
make scan-json TARGET=/home/user/git/tmp/numa-fork
make clean
```

## Notes

- `make scan-json` enables verbose Gitleaks logs and prints JSON findings to stdout.
- The scanner always runs all stages and exits non-zero if any stage reports findings.
- `make scan` and `make scan-json` now do simple preflight checks for `docker` and the target directory before starting the container.
- The image mounts the target repository read-only at `/repo`.
- Workflow linting only runs when `.github/workflows/` exists in the target repository.

## Runtime Options

You can override scanner settings directly with `docker run` if needed:

```sh
docker build -f Dockerfile.scan -t kc-repo-scanner:local .

docker run --rm \
  --mount type=bind,src="/path/to/repo",dst=/repo,readonly \
  -e GITLEAKS_VERBOSE=true \
  -e GITLEAKS_REPORT_FORMAT=json \
  -e GITLEAKS_REDACT=false \
  -e GRYPE_FAIL_ON=critical \
  -e TRIVY_SCANNERS=misconfig \
  -e TRIVY_SEVERITY=HIGH,CRITICAL \
  kc-repo-scanner:local
```
