---
name: pdf-ingestion
description: Upload pending PDFs to the single NotebookLM corpus notebook and archive successful uploads.
---

# PDF Ingestion

Use one reusable NotebookLM notebook for the project corpus:

1. Verify the file exists as a top-level `input/*.pdf` file.
2. Verify the single notebook ID is stored under `knowledge:notebook` in `.workflow_state.json`, or create the notebook only during explicit workflow execution.
3. Upload with synchronous waiting:

```bash
nlm source add <notebook-id> --file "input/<filename>.pdf" --wait
```

1. After the upload succeeds, move the PDF to `input/processed/<filename>.pdf`.
2. Record the original and processed paths in workflow state.

Do not delete NotebookLM notebooks or sources. Do not upload files already under `input/processed/`.
