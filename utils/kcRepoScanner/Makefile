IMAGE ?= kc-repo-scanner:local
REPO ?= $(CURDIR)
TARGET ?= $(REPO)
DOCKERFILE ?= Dockerfile

.PHONY: help build scan scan-json clean check-docker check-target

help:
	@printf '%s\n' 'Targets:'
	@printf '%s\n' '  make build      Build the portable scanner image'
	@printf '%s\n' '  make scan       Run the scanner against REPO or TARGET (default: current directory)'
	@printf '%s\n' '  make scan-json  Run with verbose JSON gitleaks output'
	@printf '%s\n' '  make clean      Remove the local scanner image'

check-docker:
	@command -v docker >/dev/null 2>&1 || { \
		printf '%s\n' 'docker is required but was not found in PATH' >&2; \
		exit 1; \
	}

check-target:
	@[ -d "$(TARGET)" ] || { \
		printf 'scan target not found: %s\n' "$(TARGET)" >&2; \
		exit 1; \
	}

build: check-docker
	docker build -f "$(DOCKERFILE)" -t "$(IMAGE)" .

scan: build check-target
	@docker run --rm \
		--mount type=bind,src="$(TARGET)",dst=/repo,readonly \
		"$(IMAGE)"; \
	status=$$?; \
	if [ "$$status" -ne 0 ]; then \
		printf 'scan reported findings or scanner errors for %s (exit %s)\n' "$(TARGET)" "$$status" >&2; \
		exit "$$status"; \
	fi

scan-json: build check-target
	@docker run --rm \
		--mount type=bind,src="$(TARGET)",dst=/repo,readonly \
		-e GITLEAKS_VERBOSE=true \
		-e GITLEAKS_REPORT_FORMAT=json \
		-e GITLEAKS_REDACT=false \
		"$(IMAGE)"; \
	status=$$?; \
	if [ "$$status" -ne 0 ]; then \
		printf 'scan reported findings or scanner errors for %s (exit %s)\n' "$(TARGET)" "$$status" >&2; \
		exit "$$status"; \
	fi

clean:
	docker image rm -f "$(IMAGE)"
