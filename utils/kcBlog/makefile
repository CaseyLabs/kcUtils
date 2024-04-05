kcServiceName := $(or ${kcServiceName},kc-blog)
gitRoot := $(shell git rev-parse --show-toplevel)

.PHONY: build run shell

build:
				# Perform a non-cached build
				mkdir -p ./output && \
				set -a && \
				. ./config/settings.env && \
				set +a && \
				docker build --no-cache -t ${kcServiceName} .

run: 
				set -a && \
				. ./config/settings.env && \
				set +a && \
				docker build -t ${kcServiceName} . && \
				docker run -v ./output:/home/notroot/output ${kcServiceName}

shell:
				# Enter a container shell
				set -a && \
				. ./config/settings.env && \
				set +a && \
				docker build -t ${kcServiceName} . && \
				docker run -it -v ./output:/home/notroot/output ${kcServiceName} /bin/sh