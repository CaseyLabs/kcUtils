from __future__ import annotations

import re
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

WORKSPACE_ROOT = Path("/workspace")
SUPPORTED_EXTENSIONS = {
    ".aac",
    ".flac",
    ".m4a",
    ".mkv",
    ".mov",
    ".mp3",
    ".mp4",
    ".ogg",
    ".wav",
    ".webm",
}
DEFAULT_MODEL = "medium"
DEFAULT_LANGUAGE = "English"
DEFAULT_OUTPUT_FORMAT = "all"
DEFAULT_CLEAN_AUDIO = False
MODEL_CHOICES = [
    ("tiny", "fastest, least accurate"),
    ("base", "fast, low resource"),
    ("small", "balanced for weaker systems"),
    ("medium", "recommended default for accuracy"),
    ("turbo", "faster option, especially useful for English"),
    ("large", "slower, more accurate, heavier"),
]
OUTPUT_FORMAT_CHOICES = ["all", "txt", "srt", "vtt", "tsv", "json"]
CLEAN_AUDIO_FILTER = "highpass=f=80,lowpass=f=8000,afftdn=nf=-25"


@dataclass(frozen=True)
class SelectedMedia:
    input_path: Path
    output_dir: Path
    audio_path: Path
    log_path: Path


class TranscribeError(RuntimeError):
    pass


def sanitize_name(name: str) -> str:
    normalized = unicodedata.normalize("NFKD", name)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    ascii_text = ascii_text.replace(" ", "_")
    ascii_text = re.sub(r"[^A-Za-z0-9._-]+", "_", ascii_text)
    ascii_text = re.sub(r"_+", "_", ascii_text)
    ascii_text = re.sub(r"[-.]{2,}", "_", ascii_text)
    ascii_text = ascii_text.strip("._-")
    return ascii_text or "transcript"


def discover_media_files(workspace: Path) -> list[Path]:
    files: list[Path] = []
    for entry in sorted(workspace.iterdir(), key=lambda path: path.name.lower()):
        if not entry.is_file():
            continue
        if entry.name.startswith("."):
            continue
        if entry.suffix.lower() in SUPPORTED_EXTENSIONS:
            files.append(entry)
    return files


def prompt_line(prompt: str, default: str | None = None) -> str:
    if default is None:
        suffix = ""
    else:
        suffix = f" [{default}]"
    try:
        value = input(f"{prompt}{suffix}: ").strip()
    except EOFError as exc:
        raise TranscribeError("Input stream closed.") from exc
    if not value and default is not None:
        return default
    return value


def prompt_yes_no(prompt: str, default: bool = False) -> bool:
    default_label = "Y/n" if default else "y/N"
    while True:
        try:
            value = input(f"{prompt} [{default_label}]: ").strip().lower()
        except EOFError as exc:
            raise TranscribeError("Input stream closed.") from exc
        if not value:
            return default
        if value in {"y", "yes"}:
            return True
        if value in {"n", "no"}:
            return False
        print("Please enter y or n.")


def prompt_choice(
    prompt: str,
    options: list[tuple[str, str]],
    default_value: str,
) -> str:
    value_to_index = {value: str(index + 1) for index, (value, _) in enumerate(options)}
    print(prompt)
    for index, (value, description) in enumerate(options, start=1):
        default_marker = " (default)" if value == default_value else ""
        print(f"  {index}) {value:<6} {description}{default_marker}")
    while True:
        try:
            raw = input(f"Select [default: {default_value}]: ").strip().lower()
        except EOFError as exc:
            raise TranscribeError("Input stream closed.") from exc
        if not raw:
            return default_value
        if raw in value_to_index:
            return raw
        if raw.isdigit() and 1 <= int(raw) <= len(options):
            return options[int(raw) - 1][0]
        print("Please select one of the listed options.")


def prompt_media_file(files: list[Path]) -> Path:
    print("Local Whisper Transcriber")
    print()
    print("Media files found in current directory:")
    print()
    for index, file_path in enumerate(files, start=1):
        print(f"  {index}) {file_path.name}")
    print()
    while True:
        try:
            raw = input(f"Select a file to transcribe [1-{len(files)}], or q to quit: ").strip().lower()
        except EOFError as exc:
            raise TranscribeError("Input stream closed.") from exc
        if raw in {"q", "quit"}:
            raise SystemExit(0)
        if raw.isdigit() and 1 <= int(raw) <= len(files):
            return files[int(raw) - 1]
        print("Please select a listed file number or q to quit.")


def make_output_selection(input_path: Path, workspace: Path) -> SelectedMedia:
    sanitized_stem = sanitize_name(input_path.stem)
    output_dir = workspace / "transcripts" / sanitized_stem
    audio_path = output_dir / "audio.wav"
    log_path = output_dir / "run.log"
    return SelectedMedia(input_path=input_path, output_dir=output_dir, audio_path=audio_path, log_path=log_path)


def log_message(log_path: Path, message: str) -> None:
    timestamp = datetime.now().isoformat(timespec="seconds")
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(f"[{timestamp}] {message}\n")


def run_command(args: list[str], log_path: Path, description: str) -> None:
    log_message(log_path, f"RUN {description}: {' '.join(map(shlex_quote, args))}")
    result = subprocess.run(args, capture_output=True, text=True)
    if result.stdout:
        log_message(log_path, f"STDOUT {description}:\n{result.stdout.rstrip()}")
    if result.stderr:
        log_message(log_path, f"STDERR {description}:\n{result.stderr.rstrip()}")
    if result.returncode != 0:
        raise TranscribeError(
            f"{description} failed with exit code {result.returncode}. See {log_path}."
        )
    log_message(log_path, f"OK {description}")


def shlex_quote(arg: str) -> str:
    if not arg:
        return "''"
    if re.fullmatch(r"[A-Za-z0-9_./:-]+", arg):
        return arg
    return "'" + arg.replace("'", "'\"'\"'") + "'"


def extract_audio(selection: SelectedMedia, clean_audio: bool) -> None:
    print("Extracting audio with ffmpeg...")
    selection.output_dir.mkdir(parents=True, exist_ok=True)
    ffmpeg_args = [
        "ffmpeg",
        "-y",
        "-i",
        str(selection.input_path),
        "-vn",
        "-ac",
        "1",
        "-ar",
        "16000",
        "-c:a",
        "pcm_s16le",
    ]
    if clean_audio:
        ffmpeg_args.extend(["-af", CLEAN_AUDIO_FILTER])
    ffmpeg_args.append(str(selection.audio_path))
    run_command(ffmpeg_args, selection.log_path, "ffmpeg audio extraction")


def run_whisper(
    selection: SelectedMedia,
    model: str,
    language: str | None,
    output_format: str,
) -> Path:
    print("Transcribing with Whisper...")
    whisper_args = [
        "whisper",
        str(selection.audio_path),
        "--model",
        model,
        "--output_dir",
        str(selection.output_dir),
        "--output_format",
        output_format,
        "--task",
        "transcribe",
        "--device",
        "cpu",
        "--fp16",
        "False",
    ]
    if language:
        whisper_args.extend(["--language", language])
    run_command(whisper_args, selection.log_path, "whisper transcription")
    return selection.output_dir / "audio.txt"


def print_summary(selection: SelectedMedia, transcript_path: Path) -> None:
    host_output_dir = Path("transcripts") / selection.output_dir.name
    print("Done.")
    print(f"Transcript directory: {selection.output_dir}")
    print(f"Host output directory: ./{host_output_dir.as_posix()}/")
    if transcript_path.exists():
        print(f"Plain text transcript: {transcript_path}")


def main() -> int:
    try:
        if not WORKSPACE_ROOT.is_dir():
            raise TranscribeError(f"{WORKSPACE_ROOT} does not exist or is not a directory.")
        files = discover_media_files(WORKSPACE_ROOT)
        if not files:
            raise TranscribeError("No supported media files were found in /workspace.")

        input_path = prompt_media_file(files)
        if not input_path.exists():
            raise TranscribeError(f"Selected file is missing: {input_path}")
        if input_path.suffix.lower() not in SUPPORTED_EXTENSIONS:
            raise TranscribeError(f"Unsupported input extension: {input_path.suffix}")

        selection = make_output_selection(input_path, WORKSPACE_ROOT)

        print()
        print(f"Selected: {input_path.name}")
        print()
        model = prompt_choice("Choose Whisper model:", MODEL_CHOICES, DEFAULT_MODEL)
        language = prompt_line("Language", DEFAULT_LANGUAGE)
        if language.lower() in {"auto", "detect"}:
            language = ""
        output_format = prompt_choice(
            "Choose output format:",
            [(name, "Whisper output format") for name in OUTPUT_FORMAT_CHOICES],
            DEFAULT_OUTPUT_FORMAT,
        )
        clean_audio = prompt_yes_no("Clean audio?", DEFAULT_CLEAN_AUDIO)

        extract_audio(selection, clean_audio)
        transcript_path = run_whisper(selection, model, language or None, output_format)
        print_summary(selection, transcript_path)
        return 0
    except TranscribeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
