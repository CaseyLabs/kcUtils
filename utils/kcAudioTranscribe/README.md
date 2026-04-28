# kcAudioTranscribe

Docker-driven tool that uses a local OpenAI Whisper AI model to extract audio from a video, and then convert it to a transcript text file.

- OpenAI Whisper is an open-source, automatic speech recognition (ASR) system that converts audio to text.

## Usage

```bash
make run
```

`make run` builds the Docker image, mounts the current working directory at `/workspace`, and launches a terminal menu that:

1. Lists supported media files in the top level of the current directory.
2. Lets you pick one by number.
3. Extracts audio with `ffmpeg`.
4. Runs local `openai-whisper`.
5. Writes transcripts to `./transcripts/<sanitized-name>/`.

## Other targets

```bash
make build
make shell
make clean
make help
```

## Notes

- Supported input types: `.mp4`, `.mkv`, `.mov`, `.webm`, `.m4a`, `.mp3`, `.wav`, `.flac`, `.aac`, `.ogg`
- Whisper model downloads are cached in a Docker volume named `local-whisper-transcriber-cache`.
- `make clean` removes generated transcripts and Python cache files only.

## Output

Typical outputs include:

- `audio.wav`
- `audio.txt`
- `audio.srt`
- `audio.vtt`
- `audio.json`
- `audio.tsv`
- `run.log`
