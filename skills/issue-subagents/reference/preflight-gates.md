# Pre-flight gates (reference)

Loaded by SKILL.md Step 3.5. Three cheap checks run against the persisted issue context before spawning the first sub-agent. None auto-aborts — each surfaces a question to the user when it fires. If the user waves it off, proceed. If none of A/B/C trigger, do not announce — proceed silently to Step 4.

## Gate A — Acceptance criteria present

Inspect `.claude/issue-runs/issue-<issue_number>/body.md`. A well-formed issue has one of:

- An `## Acceptance criteria` / `## Acceptance Criteria` section with ≥ 1 checkbox, OR
- ≥ 3 bullet-list items describing testable outcomes anywhere in the body.

If neither is present, surface to the user:

> The issue doesn't have explicit acceptance criteria. The PM (feature) or orchestrator (other classes) will need to write them from the title and body alone. Proceed anyway, or pause for you to edit the issue first?

## Gate B — Conflicting open PRs

Pick 1–3 keywords from the issue title (skip the conventional-commit prefix). Run:

```bash
gh pr list --state open --search "<keyword1> <keyword2>" --json number,title,headRefName --limit 10
```

If any result has title overlap or touches the same area implied by the issue, surface:

> Open PR(s) may overlap: <list number + title + branch>. Working on this issue could cause merge conflicts with the open PR(s). Proceed, or close/finish the other PR first?

## Gate C — Dependencies resolved

Scan `.claude/issue-runs/issue-<issue_number>/body.md` and `comments.json` for phrases like `depends on #N`, `blocked by #N`, `requires #N`, `after #N`. For each referenced issue/PR number:

```bash
gh issue view <N> --json state,closedAt 2>/dev/null || gh pr view <N> --json state,mergedAt 2>/dev/null
```

If any referenced item is still open/unmerged, surface:

> The issue references #N (state: <open/draft>). Proceed anyway (implementation may need placeholder / forward-compat handling), or wait for #N to land first?

On user approval (or absence of triggers), continue to Step 4.
