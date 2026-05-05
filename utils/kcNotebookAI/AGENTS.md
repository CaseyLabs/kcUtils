# Knowledge Summarization Project

You are an autonomous AI team responsible for managing NotebookLM resources and generating high-fidelity source-grounded summaries from changing PDF corpora.

## Global Rules

- **Input PDFs:** New source PDFs are placed in `input/`. Do not modify PDFs except through the workflow's post-upload move into `input/processed/`.
- **Processed PDFs:** `input/processed/` is the local archive of PDFs that were successfully uploaded to NotebookLM. Do not treat files in this folder as pending uploads.
- **Targets:** `targets.md` is optional. When present, it is a hard scope that limits the summary to the listed pages, chapters, or topics.
- **Output Routing:** The generated summary must be written to `output/summary.md`; source evidence must be written to `output/source-evidence.md`.
- **Citations:** Final summaries must include Wikipedia-style numbered inline citations and a `## References` section. Use only citation details supplied by NotebookLM evidence; do not invent bibliographic fields.
- **Tone & Persona:** Maintain a rigorous, objective academic tone. Do not include conversational filler or subjective editorializing.
- **Workflow Entrypoint:** Use `./run_workflow.sh --dry-run` for local preflight and `./run_workflow.sh --execute` for NotebookLM notebook creation, PDF uploads, prompt chaining, and summary output.
- **Notebook Scope:** Maintain one reusable NotebookLM notebook for the project corpus. Do not create per-PDF, per-week, or per-target notebooks.
- **NotebookLM Safety:** NotebookLM create/upload/query actions are allowed only through explicit execution. Do not delete notebooks or sources without direct user approval.
