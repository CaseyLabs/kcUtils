---
name: sequential-chaining
description: Execute the two-phase NotebookLM-to-Gemini corpus summary chain using source evidence sidecars and Gemini Pro model routing.
---

# Sequential Chaining

Phase 1: Query the prepared corpus NotebookLM notebook with `prompt1.txt`, the processed-source manifest, and `targets.md` when present:

```bash
nlm notebook query <notebook-id> "$(cat prompt1.txt)

CORPUS CONTEXT:
Processed source files:
- input/processed/<source>.pdf

TARGETS_MD_HARD_SCOPE:
<targets.md content or none>"
```

Save the NotebookLM output to `output/source-evidence.md`. The evidence should include a citation inventory with NotebookLM markers, page references, source labels, or other available citation detail.

Phase 2: Refine the NotebookLM evidence with Gemini CLI Pro routing:

```bash
gemini --model pro --prompt="$(cat prompt2.txt)" < source-evidence-input.txt
```

The workflow script also accepts `--model <model>` or `GEMINI_MODEL=<model>` when an explicit Gemini model ID is required. The final markdown must remain grounded in the NotebookLM evidence. If `targets.md` exists, treat it as the complete allowed scope and do not expand into unrelated corpus material. Final summaries must use numbered inline citations such as `[1]` and end with `## References`.
