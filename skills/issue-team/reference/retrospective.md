# Retrospective (reference)

Loaded by SKILL.md Step 9. Runs after all teammates report `shutdown_approved` and before `TeamDelete` — the only point in the workflow where durable lessons can be captured. Once `TeamDelete` runs, task history is gone.

## 9a. Read the run history

```
TaskList
# for any task that looks informative, read the full record:
TaskGet taskId: <id>
```

Also recall the last ~5 messages from each agent. Note any model-tier overrides from Step 6c.

## 9b. Self-ask three questions

1. What took longer than expected, or cost more tokens than expected? Why?
2. Where did routing break — any case where a message went to the wrong teammate, or where team-lead had to intervene?
3. What pattern would help a future run — a missing guardrail, a missed classification, a template field worth adding?

## 9c. If (and only if) a durable lesson emerged, append a feedback memory

Derive the project slug from the coordinator's environment — don't hardcode. Typically `~/.claude/projects/<slug>/memory/` already exists for the active working directory. Use `ls ~/.claude/projects/` and pick the slug matching the current working directory's normalized path (e.g. `-home-jonas-dev-<repo>` for `/home/jonas/dev/<repo>`). If no project slug exists yet, skip the retro write — do not create a new projects/ directory just for the retro.

Find the next free retro number:

```bash
ls ~/.claude/projects/<slug>/memory/feedback_issue_team_retro_*.md 2>/dev/null | wc -l
# N = count + 1
```

Write the feedback memory at `~/.claude/projects/<slug>/memory/feedback_issue_team_retro_<N>.md`:

```markdown
---
name: issue-team retro #<N> — <one-line title>
description: <one-line description — used to decide relevance in future conversations>
type: feedback
---

<Rule or pattern learned — lead with it>

**Why:** <context / incident that motivated this lesson during the run>

**How to apply:** <when/where in issue-team workflow this guidance kicks in>
```

Then append a one-line index entry to `~/.claude/projects/<slug>/memory/MEMORY.md`:

```
- [issue-team retro #<N>](feedback_issue_team_retro_<N>.md) — <one-line hook>
```

Skip entirely if no durable lesson emerged — don't write a retro just because the hook triggers. A "nothing to report" run is not a failure.

## 9d. Finalize

```
TeamDelete
```

Report the PR URL to the user, plus a one-line retro summary if a memory was written ("Wrote retro #N on <topic>.").
