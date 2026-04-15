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
make scan
make scan TARGET=/path/to/your/repo
make scan-json TARGET=/path/to/your/repo
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
docker build -t kc-repo-scanner:local .

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

## Published Image

This repository can publish `kcRepoScanner` to GitHub Container Registry as:

```sh
ghcr.io/casylabs/kcutils/kcreposcanner:latest
```

You can also run that image directly if it has already been published:

```sh
reposcan() {
  docker run --rm \
    --mount type=bind,src="$1",dst=/repo,readonly \
    ghcr.io/casylabs/kcutils/kcreposcanner:latest
}

reposcan /path/to/repo
```
