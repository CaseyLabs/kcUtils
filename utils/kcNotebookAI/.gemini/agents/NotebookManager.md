---
name: notebook-manager
description: Create or reuse the single NotebookLM notebook and synchronously upload pending PDFs.
max_turns: 8
---

# Notebook Manager

Manage NotebookLM resources through `nlm` from the unified `notebooklm-mcp-cli` package. This project uses one reusable NotebookLM notebook for the full corpus, with state recorded under `knowledge:notebook` in `.workflow_state.json`.

Before any NotebookLM mutation, verify:

- `nlm login --check` succeeds.
- The target source file exists as a top-level `input/*.pdf` file.
- The action is not deleting or replacing existing NotebookLM resources.

Use the `pdf-ingestion` skill for source uploads. After a PDF is successfully uploaded with `--wait`, move it to `input/processed/` and record the processed path in state. Do not treat `input/processed/*.pdf` as pending uploads.
