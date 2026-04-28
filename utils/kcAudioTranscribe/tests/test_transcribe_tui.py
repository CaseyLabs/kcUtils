from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

import transcribe_tui


class TranscribeTuiTests(unittest.TestCase):
    def test_sanitize_name_handles_spaces_and_symbols(self) -> None:
        self.assertEqual(transcribe_tui.sanitize_name("my video! 2024"), "my_video_2024")

    def test_discover_media_files_uses_top_level_supported_extensions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "meeting.m4a").write_text("x", encoding="utf-8")
            (root / "notes.txt").write_text("x", encoding="utf-8")
            (root / "nested").mkdir()
            (root / "nested" / "interview.mp3").write_text("x", encoding="utf-8")

            discovered = transcribe_tui.discover_media_files(root)

            self.assertEqual([path.name for path in discovered], ["meeting.m4a"])

    def test_make_output_selection_uses_sanitized_stem(self) -> None:
        selection = transcribe_tui.make_output_selection(
            Path("/workspace/My Lecture.mp4"),
            Path("/workspace"),
        )

        self.assertEqual(selection.output_dir, Path("/workspace/transcripts/My_Lecture"))
        self.assertEqual(selection.audio_path, Path("/workspace/transcripts/My_Lecture/audio.wav"))


if __name__ == "__main__":
    unittest.main()
