---
name: target-scope
description: Interpret optional targets.md as a hard scope for the corpus summary.
max_turns: 3
---

# Target Scope

Read `targets.md` only when it exists. Do not modify files.

Return a concise hard-scope summary of the requested pages, chapters, or topics. If a target is ambiguous, preserve the ambiguity instead of inventing a source mapping. When `targets.md` is absent, report that the summary should cover the full uploaded corpus.
