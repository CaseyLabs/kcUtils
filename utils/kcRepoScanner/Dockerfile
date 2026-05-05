# syntax=docker/dockerfile:1

# Portable local repository scanner.
#
# Copy this file into another Git repository and build it there:
#   docker build -t repo-scan:local .
#
# Run it against the current checkout:
#   docker run --rm \
#     --mount type=bind,src="$(pwd)",dst=/repo,readonly \
#     repo-scan:local
#
# All-in-one quick start from the target repository root:
#   docker build -t repo-scan:local . && \
#   docker run --rm --mount type=bind,src="$(pwd)",dst=/repo,readonly repo-scan:local
#
# Common runtime options:
#   -e GITLEAKS_VERBOSE=true
#     Print more Gitleaks log output.
#   -e GITLEAKS_REDACT=false
#     Show unredacted matched values in Gitleaks output.
#   -e GITLEAKS_REPORT_FORMAT=json
#     Emit a structured Gitleaks report to stdout.
#   -e GRYPE_FAIL_ON=critical
#     Change the vulnerability severity threshold.
#   -e TRIVY_SCANNERS=misconfig
#     Choose which Trivy scanners to run. The default focuses on Dockerfile/IaC
#     posture checks rather than duplicating Grype's package vulnerability scan.
#   -e TRIVY_SEVERITY=HIGH,CRITICAL
#     Limit the Trivy findings that appear in the report.
#   -e SCAN_TARGET=/some/path
#     Scan a different mount path inside the container.
#   -e SCAN_DEPENDENCIES=false
#     Override dependency scanning. Supported values: auto, true, false.
#   -e SCAN_IAC=false
#     Override Dockerfile/IaC misconfiguration scanning. Supported values:
#     auto, true, false.
#   -e SCAN_GITHUB_ACTIONS=false
#     Override GitHub Actions linting. Supported values: auto, true, false.
#   -e SCAN_SHELL=false
#     Override shell script linting. Supported values: auto, true, false.
#   -e SCAN_INSPECT_ONLY=true
#     Print the repository inventory and scan plan without running scanners.
#
# Behavior:
# - Gitleaks scans Git history when `.git/` is present, otherwise it falls back
#   to filesystem-only scanning.
# - Grype scans the mounted directory for package vulnerabilities when common
#   dependency manifests or lockfiles are present.
# - Trivy scans the mounted directory for misconfigurations when common
#   Dockerfile/IaC files are present.
# - actionlint checks GitHub Actions workflows when `.github/workflows/` exists.
# - ShellCheck checks shell files when common shell extensions or shell shebangs
#   are present.
# - The image always runs Gitleaks plus applicable stages and returns non-zero if any stage finds
#   issues at its configured threshold.

FROM anchore/grype:v0.111.0@sha256:af9f30d1de4ecfbbcd2b674371e8df787879e16832af8ab81551b0bf1ec0ad5b AS grype
FROM aquasec/trivy:0.69.3@sha256:bcc376de8d77cfe086a917230e818dc9f8528e3c852f7b1aff648949b6258d1c AS trivy
FROM rhysd/actionlint:latest@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667 AS actionlint
FROM ghcr.io/zizmorcore/zizmor:1.24.1@sha256:128ebbe369a95f9d4427737e794537256095b55f779a247aebc960dc4ea1f7b3 AS zizmor
FROM koalaman/shellcheck:stable@sha256:bb596a0d169b85ddd81d8b6d3a2ff6d5baf5fca10b97f575ebc647c3dff62b3d AS shellcheck

# Use a glibc runtime so the official zizmor binary can run alongside the
# other scanner binaries.
FROM debian:trixie-slim@sha256:cedb1ef40439206b673ee8b33a46a03a0c9fa90bf3732f54704f99cb061d2c5a

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

# Copy the standalone binaries into the final image so one container can
# perform all scans locally without nested Docker calls.
COPY --from=ghcr.io/gitleaks/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f /usr/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=grype /grype /usr/local/bin/grype
COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=actionlint /usr/local/bin/actionlint /usr/local/bin/actionlint
COPY --from=zizmor /usr/bin/zizmor /usr/local/bin/zizmor
COPY --from=shellcheck /bin/shellcheck /usr/local/bin/shellcheck

ENV HOME=/tmp \
    XDG_CACHE_HOME=/tmp/.cache \
    GRYPE_DB_CACHE_DIR=/tmp/.cache/grype/db \
    TRIVY_CACHE_DIR=/tmp/.cache/trivy \
    SCAN_TARGET=/repo \
    GITLEAKS_VERBOSE=false \
    GITLEAKS_REDACT=true \
    GITLEAKS_REPORT_FORMAT= \
    GRYPE_FAIL_ON=high \
    TRIVY_SCANNERS=misconfig \
    TRIVY_SEVERITY=HIGH,CRITICAL \
    TRIVY_SKIP_DB_UPDATE=true \
    SCAN_DEPENDENCIES=auto \
    SCAN_IAC=auto \
    SCAN_GITHUB_ACTIONS=auto \
    SCAN_SHELL=auto \
    SCAN_INSPECT_ONLY=false

WORKDIR /work
COPY --chmod=755 scanner.sh /usr/local/bin/kc-repo-scanner
USER 65532:65532
ENTRYPOINT []
CMD ["/usr/local/bin/kc-repo-scanner"]
