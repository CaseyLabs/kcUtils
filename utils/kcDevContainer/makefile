ENVFILE ?= ./config/settings.env
include $(ENVFILE)
export $(shell sed '/^\#/d; s/=.*//' $(ENVFILE))

IMAGE ?= $(kcServiceName)
WORKDIR ?= $(CURDIR)

.PHONY: help check-docker check build cached-build run shell clean

help:
	@printf '%s\n' 'Targets:'
	@printf '%s\n' '  make build         Build the dev container without cache'
	@printf '%s\n' '  make cached-build  Build the dev container with cache'
	@printf '%s\n' '  make run           Build with cache and enter zsh'
	@printf '%s\n' '  make shell         Alias for make run'
	@printf '%s\n' '  make check         Run local validation checks'
	@printf '%s\n' '  make clean         Remove the local image'

check-docker:
	@command -v docker >/dev/null 2>&1 || { \
		printf '%s\n' 'docker is required but was not found in PATH' >&2; \
		exit 1; \
	}

check: check-docker
	sh -n config/install-system.sh config/install-user.sh
	docker build --check .

build: check-docker
	docker build --no-cache -t "$(IMAGE)" .

cached-build: check-docker
	docker build -t "$(IMAGE)" .

run: cached-build
	docker run --rm \
		--mount type=bind,src="$(WORKDIR)",dst=/home/user/workdir \
		-it "$(IMAGE)" /bin/zsh

shell: run

clean: check-docker
	docker image rm -f "$(IMAGE)"
