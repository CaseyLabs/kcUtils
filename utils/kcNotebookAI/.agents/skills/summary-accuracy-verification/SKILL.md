---
name: summary-accuracy-verification
description: Verify the generated corpus summary against the prepared NotebookLM notebook, source-evidence.md, optional targets.md, .workflow_state.json, and prompt2.txt.
---

# Summary Accuracy Verification

## Overview

Verify the generated summary by querying the prepared corpus NotebookLM notebook, saving refreshed source-grounded evidence to `output/source-evidence.md`, and refining `output/summary.md` with Gemini CLI using `prompt2.txt`. Treat NotebookLM responses as the only substantive source evidence, including citation details.

Prefer the scripted entrypoint when running the full project workflow:

```bash
./run_workflow.sh --verify
```

## Workflow

1. Verify NotebookLM readiness before source queries.
   - Run `nlm login --check`.
   - Read the notebook ID from `.workflow_state.json` using the `knowledge:notebook` key.
   - Use the single project corpus notebook.
   - Do not delete notebooks or sources.
   - If the notebook is missing from state, stop and report that `./run_workflow.sh --execute` must prepare it first.

1. Query the corpus notebook for verification evidence.
   - Include the processed-source manifest.
   - Include `targets.md` when present and treat it as the hard scope.
   - Ask NotebookLM for detailed source-grounded evidence, coverage requirements, citation details, and accuracy warnings.
   - Do not send the entire current summary to NotebookLM; long generated summaries can exceed practical query size and fail.

1. Save the evidence sidecar.
   - Write combined NotebookLM verification notes to `output/source-evidence.md`.
   - The evidence file should contain NotebookLM citations, page references, source labels, or other available citation details.

1. Run the final Gemini verification pass with `prompt2.txt`.
   - Assemble stdin with:
     - corpus context
     - optional hard-scope targets
     - current markdown summary when revising
     - NotebookLM verification evidence
   - Invoke Gemini with project defaults unless the user requests a model:

```bash
gemini --model pro --prompt="$(cat prompt2.txt)" < verification-input.txt
```

1. Handle the result.
   - The expected Gemini output is only final markdown summary text.
   - The summary must use numbered inline citations and end with `## References`.
   - Replace `output/summary.md` only when the task asks to update or revise files.
   - If the task asks only for an audit, report the accuracy findings and do not write output files.
   - Preserve markdownlint-compatible formatting and the rigorous academic tone from `AGENTS.md`.

## Validation

After writing revised summaries or skill changes, run the repo checks that apply:

```bash
jq . .gemini/settings.json
shellcheck run_workflow.sh
shfmt -d run_workflow.sh
gemini skills list
markdownlint -c .markdownlint.json README.md AGENTS.md .agents/skills/**/*.md .gemini/agents/*.md
```

If markdownlint is not installed, state that it was skipped.
