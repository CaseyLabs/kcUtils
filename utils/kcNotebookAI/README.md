# Knowledge Summarizer

Knowledge Summarizer turns a folder of PDFs into one source-grounded Markdown
summary. It uses one reusable NotebookLM notebook for the project corpus, asks
NotebookLM to extract evidence from the uploaded PDFs, then asks Gemini to turn
that evidence into `output/summary.md`.

Use this when you want a repeatable summary workflow for a changing PDF corpus,
with local records of what was uploaded and citation details preserved for the
final document.

## What It Creates

- `output/source-evidence.md`: the evidence extracted from NotebookLM.
- `output/summary.md`: the final polished summary with numbered citations.
- `.workflow_state.json`: the local record of the reusable NotebookLM notebook,
  uploaded sources, generated outputs, and workflow runs.
- `input/processed/`: the local archive of PDFs that were uploaded
  successfully.

The workflow does not create a new notebook for each PDF or each run. It keeps
using the notebook recorded in `.workflow_state.json`.

## Requirements

Install the command-line tools before running the workflow:

- Gemini CLI `0.40.1` or newer.
- Python `3.11` or newer.
- `jq` and `grep`.
- `shellcheck` and `shfmt` for validating changes to the workflow script.
- Optional: `markdownlint` for checking generated Markdown and documentation.

Install the NotebookLM CLI and MCP server:

```bash
uv tool install --force notebooklm-mcp-cli
```

Sign in to NotebookLM and check that the local tools can reach it:

```bash
nlm login
nlm login --check
gemini mcp list
```

The project settings expect `notebooklm-mcp` to be available on `PATH`.

## Add PDFs

Put new PDFs directly in `input/`:

```text
input/
  article-a.pdf
  report-b.pdf
```

Do not put new PDFs in `input/processed/`. That folder is only for files that
the workflow already uploaded successfully.

After a successful `--execute` run, each uploaded PDF is moved from `input/` to
`input/processed/`.

## Optional: Limit the Summary Scope

Create `targets.md` when you want the summary to focus on specific pages,
chapters, sections, or topics.

Example:

```markdown
# Targets

- Chapter 2, pages 31-58
- The section on risk controls
- Any discussion of implementation constraints
```

When `targets.md` exists, it is a hard scope. NotebookLM and Gemini are told to
treat the rest of the uploaded corpus as out of scope.

## Run the Workflow

Start with a dry run. This checks the local PDF counts and shows what would
happen without uploading, querying, or writing output.

```bash
./run_workflow.sh --dry-run
```

Upload pending PDFs, create or reuse the NotebookLM notebook, refresh the
evidence, and write the final summary:

```bash
./run_workflow.sh --execute
```

The first successful execute run creates the reusable NotebookLM notebook and
records its ID in `.workflow_state.json`. Later execute runs reuse that same
notebook and upload only PDFs that are currently pending in `input/`.

## Common Options

Use a named NotebookLM profile:

```bash
./run_workflow.sh --execute --profile research
```

You can also set the profile with an environment variable:

```bash
NLM_PROFILE=research ./run_workflow.sh --execute
```

Choose the Gemini model used for the final summary step:

```bash
./run_workflow.sh --execute --model pro
```

You can also set it with `GEMINI_MODEL`:

```bash
GEMINI_MODEL=pro ./run_workflow.sh --execute
```

Increase the NotebookLM query timeout for large corpora or broad targets:

```bash
./run_workflow.sh --execute --query-timeout 900
```

Increase the source-processing timeout for very large PDFs:

```bash
./run_workflow.sh --execute --source-wait-timeout 900
```

The default timeout for both NotebookLM queries and source processing is 600
seconds.

## Refresh an Existing Summary

Use `--verify` when the notebook is already prepared and you want to regenerate
the evidence and final summary without uploading new PDFs:

```bash
./run_workflow.sh --verify
```

This requires `.workflow_state.json` to contain the prepared
`knowledge:notebook` entry.

## Check the Remote Notebook

Use `--check-remote` to confirm that the recorded NotebookLM notebook is still
accessible and that its remote source metadata includes the PDFs archived in
`input/processed/`.

```bash
./run_workflow.sh --check-remote
```

This check is read-only. It does not upload PDFs, query Gemini, write output
files, or update `.workflow_state.json`.

## Output and Citations

The final summary must use numbered inline citations such as `[1]` and must end
with a `## References` section. The workflow rejects Gemini output that does not
include numbered inline citations and a populated numbered reference list.

References are built only from citation details supplied by NotebookLM evidence.
If NotebookLM provides only a source label, page range, or marker, the summary
uses that available detail instead of guessing missing bibliographic fields.

## Troubleshooting

If authentication fails, sign in again and rerun the checks:

```bash
nlm login
nlm login --check
gemini mcp list
```

If `--verify` or `--check-remote` says the prepared notebook is missing, run
`--execute` first or restore the correct `.workflow_state.json`.

If `.workflow_state.json` is missing but `input/processed/` already contains
PDFs, restore the state file or move those PDFs back to `input/` before running
`--execute`. The script stops in this case because it cannot prove which remote
notebook contains the archived PDFs.

If an upload stops because a processed file already exists, rename or remove the
duplicate file in `input/processed/` before trying again.

If NotebookLM source processing or querying times out, rerun with a larger
timeout:

```bash
./run_workflow.sh --execute --source-wait-timeout 900 --query-timeout 900
```

## Validate Project Changes

Run these checks after changing the workflow or project documentation:

```bash
jq . .gemini/settings.json
shellcheck run_workflow.sh
shfmt -d run_workflow.sh
gemini skills list
```

If `markdownlint` is installed, also run:

```bash
markdownlint -c .markdownlint.json README.md AGENTS.md .agents/skills/**/*.md .gemini/agents/*.md
```

## NotebookLM Caveat

`notebooklm-mcp-cli` uses NotebookLM internal APIs and browser-cookie
authentication. If Google changes those APIs or the local cookie session
expires, rerun `nlm login` and repeat the preflight checks before executing the
workflow.
