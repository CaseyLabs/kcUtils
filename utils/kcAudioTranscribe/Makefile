IMAGE_NAME ?= local-whisper-transcriber
WORKDIR ?= $(CURDIR)
WHISPER_CACHE_VOLUME ?= local-whisper-transcriber-cache
DOCKER ?= docker

.PHONY: build run shell clean help

build:
	$(DOCKER) build -t $(IMAGE_NAME) .

run: build
	$(DOCKER) run --rm -it \
		-v "$(WORKDIR):/workspace" \
		-v "$(WHISPER_CACHE_VOLUME):/root/.cache/whisper" \
		-w /workspace \
		$(IMAGE_NAME) \
		python /app/transcribe_tui.py

shell: build
	$(DOCKER) run --rm -it \
		-v "$(WORKDIR):/workspace" \
		-v "$(WHISPER_CACHE_VOLUME):/root/.cache/whisper" \
		-w /workspace \
		$(IMAGE_NAME) \
		/bin/sh

clean:
	rm -rf transcripts .pytest_cache __pycache__ src/__pycache__ tests/__pycache__

help:
	@printf '%s\n' \
		'make build  - Build the Docker image.' \
		'make run    - Build the image and launch the transcription TUI.' \
		'make shell  - Build the image and open a shell in the container.' \
		'make clean  - Remove generated transcripts and local Python cache files.' \
		'make help   - Show this help.'
