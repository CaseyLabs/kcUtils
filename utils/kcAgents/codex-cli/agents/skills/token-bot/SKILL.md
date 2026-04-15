---
name: token-bot
description: Use when a task may benefit from profile selection, deep-mode escalation, or bounded subagent delegation to reduce Codex CLI token usage. Trigger for broad repo analysis, multi-file debugging, reviews, planning, ambiguous implementation requests, or when the user asks whether to use routine, standard, deep, mini subagents, subagents, or token-saving workflows.
metadata:
  short-description: Choose profiles and subagents efficiently
---

# token-bot

`token-bot` is a token-efficient delegation skill. Use this skill to control context growth and model spend while preserving quality.

## Default stance

- You may be autonomous in your decision whether or not to run subagents without input or requirement from me.
- Prefer the smallest capable workflow: focused local work before delegation.
- Keep tasks short. Start a fresh session after a clear task boundary instead of carrying a large thread forward.
- Do not use subagents for simple questions, one-file edits, direct command output, or tightly coupled changes.

## Profile choice

- Use `routine` for repo navigation, small edits, straightforward fixes, docs, formatting, and simple questions.
- Use `standard` for normal implementation, moderate debugging, test failures, and multi-file changes.
- Use `deep` for high-uncertainty or high-risk work: architecture decisions, hard bugs, security-sensitive changes, complex refactors, migration design, concurrency/data-loss risks, production incidents, or when repeated routine/standard attempts fail.
- Recommend starting a new `deep` session when the current thread is already large and the next step needs deep reasoning.
- Do not simulate `deep` by spawning many mini subagents. Escalate the main session when synthesis and judgment are the hard part.

## Subagent policy

- Use mini subagents only for independent bounded side work that can run in parallel without blocking the next local step.
- Good subagent tasks: read-only subsystem mapping, test/log triage, dependency or config inspection, independent API/schema lookup, and focused review of a narrow path.
- Bad subagent tasks: broad repo analysis without scope, single-file edits, sequential debugging, work that requires shared mutable state, or implementation with overlapping write sets.
- Prefer one or two subagents. Use more only when the task naturally splits into distinct subsystems.
- Give each subagent one question, a clear scope, and a compact output format. For code changes, assign disjoint files or modules and state that other agents may be editing concurrently.

## Decision flow

1. If the task is simple and bounded, work locally in the current profile.
2. If it is normal coding or debugging, use or recommend `standard`.
3. If it is hard, risky, or repeatedly failing, recommend a fresh `deep` session.
4. If independent exploration can reduce main-thread context, delegate narrow read-only work to mini subagents.
5. If the current thread is large, prefer summarizing state and starting a new session over adding more agents.

## User-facing guidance

- When recommending a profile switch, give the exact command:
  - `codex --profile routine`
  - `codex --profile standard`
  - `codex --profile deep`
- When delegating, briefly state why each subagent is worth its token cost.
