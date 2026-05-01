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
#
# Behavior:
# - Gitleaks scans Git history when `.git/` is present, otherwise it falls back
#   to filesystem-only scanning.
# - Grype scans the mounted directory for package vulnerabilities.
# - Trivy scans the mounted directory for misconfigurations such as Dockerfile
#   and IaC security-posture issues.
# - actionlint checks GitHub Actions workflows when `.github/workflows/` exists.
# - The image always runs all stages and returns non-zero if any stage finds
#   issues at its configured threshold.

FROM anchore/grype:v0.111.1@sha256:3c1cd2ff38196e753751fb1619b3b6787a6e3e79149f2a2aec57946d2c154cd2 AS grype
FROM aquasec/trivy:0.70.0@sha256:be1190afcb28352bfddc4ddeb71470835d16462af68d310f9f4bca710961a41e AS trivy
FROM rhysd/actionlint:latest@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667 AS actionlint

# Use the official Gitleaks image as the runtime base because it already
# includes Git plus a minimal shell environment.
FROM ghcr.io/gitleaks/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f

# Copy the standalone binaries into the final image so one container can
# perform all scans locally without nested Docker calls.
COPY --from=grype /grype /usr/local/bin/grype
COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=actionlint /usr/local/bin/actionlint /usr/local/bin/actionlint

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
    TRIVY_SKIP_DB_UPDATE=true

WORKDIR /work
USER 65532:65532
ENTRYPOINT []

CMD ["/bin/sh", "-eu", "-c", "\
target=${SCAN_TARGET:-/repo}; \
[ -d \"$target\" ] || { printf 'scan target not found: %s\\n' \"$target\" >&2; exit 1; }; \
mkdir -p \"$XDG_CACHE_HOME\" \"$GRYPE_DB_CACHE_DIR\"; \
unset GITLEAKS_CONFIG GITLEAKS_CONFIG_TOML; \
gitleaks_status=0; \
grype_status=0; \
trivy_status=0; \
actionlint_status=0; \
set -- --source \"$target\" --no-banner --exit-code 1; \
if [ \"${GITLEAKS_VERBOSE}\" = 'true' ]; then \
  set -- \"$@\" -v; \
fi; \
if [ \"${GITLEAKS_REDACT}\" = 'true' ]; then \
  set -- \"$@\" --redact; \
fi; \
if [ -n \"${GITLEAKS_REPORT_FORMAT}\" ]; then \
  set -- \"$@\" --report-format \"${GITLEAKS_REPORT_FORMAT}\" --report-path -; \
fi; \
printf '\\n==> Secret scan (gitleaks)\\n'; \
if [ -d \"$target/.git\" ]; then \
  git config --global --add safe.directory \"$target\"; \
  gitleaks detect \"$@\" || gitleaks_status=$?; \
else \
  gitleaks detect \"$@\" --no-git || gitleaks_status=$?; \
fi; \
printf '\\n==> Vulnerability scan (grype)\\n'; \
grype \"dir:$target\" --exclude '**/.git' --fail-on \"$GRYPE_FAIL_ON\" -o table || grype_status=$?; \
printf '\\n==> Misconfiguration scan (trivy)\\n'; \
set -- fs --scanners \"$TRIVY_SCANNERS\" --severity \"$TRIVY_SEVERITY\" --skip-dirs \"$target/.git\" --skip-version-check --exit-code 1 \"$target\"; \
if [ \"${TRIVY_SKIP_DB_UPDATE}\" = 'true' ]; then \
  set -- \"$@\" --skip-db-update --skip-java-db-update; \
fi; \
trivy \"$@\" || trivy_status=$?; \
printf '\\n==> Workflow lint (actionlint)\\n'; \
if [ -d \"$target/.github/workflows\" ]; then \
  if find \"$target/.github/workflows\" -maxdepth 1 -type f \\( -name '*.yml' -o -name '*.yaml' \\) | grep -q .; then \
    (cd \"$target\" && actionlint -shellcheck= -pyflakes=) || actionlint_status=$?; \
  else \
    printf 'no workflow files found under %s/.github/workflows\\n' \"$target\"; \
  fi; \
else \
  printf 'no .github/workflows directory found under %s\\n' \"$target\"; \
fi; \
if [ \"$gitleaks_status\" -ne 0 ]; then \
  printf 'gitleaks exited with status %s\\n' \"$gitleaks_status\" >&2; \
fi; \
if [ \"$grype_status\" -ne 0 ]; then \
  printf 'grype exited with status %s\\n' \"$grype_status\" >&2; \
fi; \
if [ \"$trivy_status\" -ne 0 ]; then \
  printf 'trivy exited with status %s\\n' \"$trivy_status\" >&2; \
fi; \
if [ \"$actionlint_status\" -ne 0 ]; then \
  printf 'actionlint exited with status %s\\n' \"$actionlint_status\" >&2; \
fi; \
[ \"$gitleaks_status\" -eq 0 ] && [ \"$grype_status\" -eq 0 ] && [ \"$trivy_status\" -eq 0 ] && [ \"$actionlint_status\" -eq 0 ] \
"]
