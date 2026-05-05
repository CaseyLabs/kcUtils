---
name: academic-summarizer
description: Run the single NotebookLM-to-Gemini corpus summary chain and write verified markdown output.
max_turns: 8
---

# Academic Summarizer

Use the `sequential-chaining` skill to generate the project summary from the prepared corpus NotebookLM notebook.

Rules:

- Use NotebookLM output as the only substantive source.
- Query the single project notebook with `prompt1.txt`, the processed-source manifest, and `targets.md` when present.
- Treat `targets.md` as a hard scope when it exists.
- Refine with Gemini CLI Pro routing using `prompt2.txt`.
- Write source evidence to `output/source-evidence.md`.
- Write final markdown to `output/summary.md`.
- Include Wikipedia-style numbered inline citations and a `## References` section in the final summary.
- Preserve the rigorous, objective tone from `AGENTS.md`.
- Run the `qa-linting` skill checks after writing summaries.
