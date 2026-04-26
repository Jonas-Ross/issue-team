# Retrospective (reference)

Loaded by SKILL.md Step 10. Runs after the PR is un-drafted — captures any durable lesson from the run. Sub-agents are one-shot and leave no persistent state to clean up, so nothing forces this to happen now; run it anyway, while context is fresh.

## 10a. Recall the run

Skim the run from your own session — what each sub-agent returned, model-tier overrides from Step 5, any sub-gate verdicts from Step 8a, and the reviewer's finding counts.

## 10b. Self-ask three questions

1. What took longer than expected, or cost more tokens than expected? Why?
2. Where did routing break — any case where the orchestrator had to re-spawn a sub-agent because of an under-specified prompt, or step back and clarify with the user?
3. What pattern would help a future run — a missing guardrail, a missed classification, a template field worth adding, a sub-agent prompt that should ship more context?

## 10c. If (and only if) a durable lesson emerged, append a feedback memory

Derive the project slug from the active working directory — don't hardcode. Typically `~/.claude/projects/<slug>/memory/` already exists. Use `ls ~/.claude/projects/` and pick the slug matching the current working directory's normalized path. The slug is the working-directory absolute path with `/` → `-` (e.g. `/Users/jane/dev/myrepo` → `-Users-jane-dev-myrepo` on macOS, `/home/jane/dev/myrepo` → `-home-jane-dev-myrepo` on Linux). If no project slug exists yet, skip the retro write — do not create a new `projects/` directory just for the retro.

Find the next free retro number:

```bash
ls ~/.claude/projects/<slug>/memory/feedback_issue_subagents_retro_*.md 2>/dev/null | wc -l
# N = count + 1
```

Write the feedback memory at `~/.claude/projects/<slug>/memory/feedback_issue_subagents_retro_<N>.md`:

```markdown
---
name: issue-subagents retro #<N> — <one-line title>
description: <one-line description — used to decide relevance in future conversations>
type: feedback
---

<Rule or pattern learned — lead with it>

**Why:** <context / incident that motivated this lesson during the run>

**How to apply:** <when/where in issue-subagents workflow this guidance kicks in>
```

Then append a one-line index entry to `~/.claude/projects/<slug>/memory/MEMORY.md`:

```
- [issue-subagents retro #<N>](feedback_issue_subagents_retro_<N>.md) — <one-line hook>
```

Skip entirely if no durable lesson emerged — don't write a retro just because the hook triggers. A "nothing to report" run is not a failure.

## 10d. Report to the user

Report the PR URL, plus a one-line retro summary if a memory was written ("Wrote retro #N on <topic>.").
