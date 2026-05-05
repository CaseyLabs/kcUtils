# AGENTS.md

## Project purpose

This project implements a local, no-API-key workflow for converting MP4 video files and other common audio/video formats into text transcripts on Linux.

The intended workflow is:

```text
host current working directory
  -> make run
  -> Docker container starts interactively
  -> terminal TUI appears
  -> user selects a local media file from the mounted host directory
  -> ffmpeg extracts normalized audio inside the container
  -> local OpenAI Whisper CLI transcribes audio inside the container
  -> transcript files are written back to the host under ./transcripts/<input-name>/
  -> Gemini Pro web UI is optionally used manually for cleanup or summarization
```

This project must not depend on OpenAI API keys, Gemini API keys, paid API access, browser automation of Gemini, or host-level Python package installation.

## User constraints

Assume the user has:

* A Linux CLI environment.
* Docker installed.
* GNU Make installed.
* Codex CLI installed.
* Access to Google Gemini Pro web UI.
* No intention to use API keys for OpenAI, Codex, or Gemini.
* One or more local MP4/video/audio files in the host's current working directory.

Do not design the workflow around:

* OpenAI API transcription endpoints.
* Gemini API endpoints.
* Automated upload to Gemini web UI.
* Cloud-only services.
* Paid transcription SaaS.
* Host-level Python virtual environments as the primary runtime.
* Requiring the user to manually run `docker build` or `docker run` for normal usage.

## Core implementation target

The primary deliverable is a Dockerized, Makefile-driven TUI transcription tool.

The user-facing entrypoint must be:

```bash
make run
```

`make run` should:

1. Build the Docker image if needed.
2. Start a running interactive container.
3. Mount the host's current working directory into the container.
4. Launch a TUI that appears to the user as a normal terminal application.
5. Let the user select a supported local media file from the mounted host working directory.
6. Transcribe the selected file.
7. Write outputs back to the host filesystem.

The end user should not need to know or type the underlying Docker commands for normal operation.

## Required project files

A good minimal repository should contain:

```text
AGENTS.md
README.md
Makefile
Dockerfile
src/transcribe_tui.py
.gitignore
```

Optional files are acceptable if they improve maintainability:

```text
scripts/
src/requirements.txt
src/pyproject.toml
tests/
```

## Runtime architecture

Use Docker for all code builds, dependencies, and runs.

The host should only need:

```text
docker
make
```

All runtime dependencies should live in the Docker image, including:

```text
ffmpeg
ffprobe
python3
openai-whisper
TUI Python dependencies, if any
```

The container should mount the host current working directory at a stable path, for example:

```text
/workspace
```

The TUI should operate on files under `/workspace` only by default.

Generated outputs should be written to:

```text
/workspace/transcripts/<sanitized-input-name>/
```

which appears on the host as:

```text
./transcripts/<sanitized-input-name>/
```

## Makefile requirements

The `Makefile` is the primary user interface.

Required targets:

```makefile
make build
make run
make shell
make clean
make help
```

Recommended target behavior:

```text
make build
  Build the Docker image.

make run
  Build the image if needed, then run the TUI in an interactive container.
  Mount the host current working directory into /workspace.
  Preserve terminal interactivity with -it.

make shell
  Build the image if needed, then open an interactive shell in the same mounted container environment.

make clean
  Remove generated transcript outputs and local build artifacts only if clearly documented.
  Do not remove user media files.

make help
  Print available commands and short descriptions.
```

`make run` should be safe to run repeatedly.

The Docker image name should be defined as a variable near the top of the Makefile, for example:

```makefile
IMAGE_NAME ?= local-whisper-transcriber
WORKDIR ?= $(CURDIR)
```

Use Docker commands similar to:

```makefile
docker run --rm -it \
  -v "$(WORKDIR):/workspace" \
  -w /workspace \
  $(IMAGE_NAME) \
  python /app/transcribe_tui.py
```

If GPU support is added later, it must be optional and documented separately. CPU mode must work by default.

## Dockerfile requirements

The `Dockerfile` should install all runtime dependencies needed to transcribe files.

Recommended base image:

```dockerfile
python:3.11-slim
```

The image should install:

```text
ffmpeg
openai-whisper
any TUI library used by transcribe_tui.py
```

Recommended implementation style:

```dockerfile
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -U pip \
    && pip install --no-cache-dir openai-whisper

WORKDIR /app
COPY transcribe_tui.py /app/transcribe_tui.py

CMD ["python", "/app/transcribe_tui.py"]
```

If additional Python dependencies are added, prefer a `requirements.txt` file and install it in the image.

Avoid host dependency leakage. Do not require `pip install` on the host.

## TUI requirements

The TUI should be implemented as a terminal application launched inside the Docker container.

Recommended implementation file:

```text
transcribe_tui.py
```

The TUI may be implemented with standard library prompts or a TUI helper library. Prefer simple, reliable behavior over visual complexity.

Acceptable implementation approaches:

* Python standard library interactive numbered menu.
* `prompt_toolkit` selection menu.
* `textual` or `rich` if the added dependency is justified.

The first implementation should prefer a simple numbered terminal menu unless the user asks for a richer UI.

The TUI must:

1. Scan `/workspace` for supported media files.
2. Show a list of matching files from the host current working directory.
3. Let the user select a file by keyboard.
4. Ask for transcription options or use sensible defaults.
5. Run `ffmpeg` to extract audio.
6. Run `whisper` to transcribe audio.
7. Show progress messages.
8. Show the final output path.
9. Exit cleanly.

Supported file extensions:

```text
.mp4
.mkv
.mov
.webm
.m4a
.mp3
.wav
.flac
.aac
.ogg
```

By default, scan only the top level of `/workspace` to keep file selection predictable.

It is acceptable to add an option to scan recursively later, but do not make recursive scanning the default unless documented.

## TUI user flow

Recommended first-run flow:

```text
Local Whisper Transcriber

Media files found in current directory:

  1) lecture.mp4
  2) meeting.m4a
  3) interview.mov

Select a file to transcribe [1-3], or q to quit:
```

After file selection:

```text
Selected: lecture.mp4

Choose Whisper model:
  1) tiny    fastest, least accurate
  2) base
  3) small
  4) medium  recommended default
  5) turbo   faster option, especially useful for English
  6) large   slower, heavier

Model [medium]:
Language [English]:
Output format [all]:
Clean audio? [y/N]:
```

Then:

```text
Extracting audio with ffmpeg...
Transcribing with Whisper...
Done.
Transcript directory: /workspace/transcripts/lecture/
Plain text transcript: /workspace/transcripts/lecture/audio.txt
```

Paths printed to the user should also include host-relative paths when possible:

```text
Host output directory: ./transcripts/lecture/
```

## Default transcription settings

Recommended defaults:

```text
model: medium
language: English
output format: all
clean audio: false
```

Common model guidance:

```text
tiny    fastest, least accurate
base    fast, low resource
small   balanced for weaker systems
medium  recommended default for accuracy
large   slower, more accurate, heavier
turbo   faster option, especially useful for English
```

The TUI should allow users to override these values, but defaults should make the normal case simple.

## Audio extraction requirements

Default extraction should use:

```bash
ffmpeg -y \
  -i "$INPUT" \
  -vn \
  -ac 1 \
  -ar 16000 \
  -c:a pcm_s16le \
  "$AUDIO_FILE"
```

If clean audio is enabled, apply conservative speech-focused filtering, for example:

```bash
-af "highpass=f=80,lowpass=f=8000,afftdn=nf=-25"
```

Do not make aggressive audio changes by default. The default path should preserve speech intelligibility with minimal transformation.

## Output layout

For input:

```text
my video.mp4
```

The output directory should be:

```text
./transcripts/my_video/
```

Expected files may include:

```text
audio.wav
audio.txt
audio.srt
audio.vtt
audio.json
audio.tsv
run.log
```

The exact transcript file basename may be determined by Whisper. If the extracted audio file is `audio.wav`, Whisper usually emits `audio.txt`, `audio.srt`, etc.

## Error handling requirements

The tool should fail clearly when:

* Docker is not installed.
* Docker daemon is not running.
* The image cannot be built.
* `/workspace` cannot be mounted.
* No supported media files are found in the host current working directory.
* The selected input file is missing.
* The input extension is unsupported.
* `ffmpeg` fails.
* `whisper` fails.
* Audio extraction fails.
* The output directory cannot be created.

Avoid silent failures. Do not swallow command errors unless there is a clear fallback.

When shell scripts are used, use Bash strict mode:

```bash
set -euo pipefail
```

In Python, use clear exceptions and non-zero exits for unrecoverable errors.

## Filename handling

The implementation must safely handle input filenames with spaces.

Use argument arrays in Python subprocess calls rather than shell strings.

Good:

```python
subprocess.run([
    "ffmpeg",
    "-y",
    "-i",
    str(input_path),
    "-vn",
    "-ac",
    "1",
    "-ar",
    "16000",
    "-c:a",
    "pcm_s16le",
    str(audio_file),
], check=True)
```

Avoid:

```python
subprocess.run(f"ffmpeg -i {input_path} {audio_file}", shell=True)
```

Sanitize output directory names by replacing spaces with underscores and removing unusual characters. Preserve enough of the original filename to make outputs easy to identify.

## Gemini Pro web UI role

Gemini is optional and manual. Do not automate it.

After the local transcript is created, the user may upload the `.txt` file to Gemini Pro web UI and use one of these prompts.

### Cleanup prompt

```text
Clean up this transcript without changing the meaning.

Rules:
- Keep the speaker's wording as much as possible.
- Fix obvious transcription errors.
- Add paragraphs and punctuation.
- Do not summarize unless I ask.
- Do not remove technical details.
- Mark uncertain words as [unclear].
```

### Notes prompt

```text
Turn this transcript into:
1. A concise summary
2. Key topics
3. Action items
4. Names, dates, and technical terms mentioned
5. Open questions

Do not invent missing information.
```

## Codex CLI role

Codex CLI should be used to improve and maintain this local Dockerized workflow, not to perform transcription itself.

Useful Codex tasks:

* Implement or review the Makefile.
* Implement or review the Dockerfile.
* Implement or review `transcribe_tui.py`.
* Add a README.
* Add shellcheck-friendly formatting for shell snippets.
* Add tests for filename sanitization and media discovery.
* Add batch transcription later.
* Add `.gitignore` entries for generated outputs.

Example Codex prompt:

```text
Implement this project using AGENTS.md as the source of truth.

Create:
- Makefile
- Dockerfile
- transcribe_tui.py
- README.md
- .gitignore

Requirements:
- make run is the primary user entrypoint
- make run builds and launches an interactive Docker container
- the container mounts the host current working directory at /workspace
- the user sees a terminal TUI
- the TUI lets the user select a supported media file from the host current directory
- transcription uses local ffmpeg and local openai-whisper inside Docker
- no OpenAI API keys
- no Gemini API keys
- no browser automation
- outputs go under ./transcripts/<input-name>/ on the host
- filenames with spaces must work
```

## README requirements

If creating or editing `README.md`, include:

* What the workflow does.
* The no-API-key limitation.
* Docker and Make requirements.
* `make build`, `make run`, `make shell`, and `make clean` usage.
* How the host current working directory is mounted.
* How to select a file in the TUI.
* Output directory explanation.
* Gemini cleanup prompt.
* Troubleshooting section.

Troubleshooting should cover:

* `docker: command not found`
* Docker daemon not running
* permission denied connecting to Docker socket
* slow transcription on CPU
* out-of-memory errors with larger Whisper models
* poor audio quality
* no media files found
* unsupported file type

## Verification checklist

After modifying the project, verify:

```bash
make help
make build
```

If the host has Docker available, verify:

```bash
make run
```

Use a small sample media file where possible.

Validate Python syntax:

```bash
python -m py_compile transcribe_tui.py
```

Or inside Docker:

```bash
make shell
python -m py_compile /app/transcribe_tui.py
```

If ShellCheck is available and shell scripts are added:

```bash
shellcheck <script-name>.sh
```

Do not require real media files for basic syntax validation, but document that full end-to-end testing requires a small video or audio file.

## Future enhancements

Acceptable future improvements:

* Batch mode for all supported files in the current directory.
* Recursive scan mode.
* `--dry-run` mode.
* Optional GPU Docker runtime support.
* `--diarization-note` explaining that speaker diarization is not handled by standard Whisper CLI.
* Automatic Markdown report generation from transcript metadata.
* Optional CPU/GPU detection messaging.
* Optional compression or deletion of intermediate `audio.wav`.

Avoid future improvements that require:

* API keys.
* Unofficial Gemini web automation.
* Uploading private media to third-party services by default.
* Hidden network calls.
* Host-level Python dependency installation for normal usage.

## Privacy and data handling

Default behavior must keep the media file, extracted audio, and transcript local.

Do not upload files anywhere.
Do not call external APIs.
Do not add telemetry.
Do not add background network checks.

The only intentional external/manual step is that the user may choose to upload the completed transcript text file to Gemini Pro web UI for cleanup or summarization.
