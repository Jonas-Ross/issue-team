# Worktree setup (reference)

Loaded by SKILL.md Step 2.5 when the orchestrator is on `main` / `master` and needs to create a feature-branch worktree before spawning sub-agents.

## Pick the worktree parent directory

Use an existing worktree base if one is present; otherwise default to `.worktrees/`:

```bash
base=
for d in .claude/worktrees .worktrees worktrees; do
  if [ -d "$d" ]; then base="$d"; break; fi
done
: "${base:=.worktrees}"
mkdir -p "$base"
```

If `$base` is `.worktrees` or `worktrees` (project-local, outside `.claude/`), verify it is gitignored before creating the worktree. If not ignored, add it to `.gitignore` and commit before proceeding.

## Derive branch name and worktree path

Map the issue title's conventional-commit prefix to a branch prefix, then slugify the rest. Include the issue number so similarly-titled issues and reruns do not silently collide.

| Title prefix | Branch prefix |
|---|---|
| `feat:` | `feature` |
| `fix:` | `fix` |
| `refactor:` | `refactor` |
| `chore:` | `chore` |
| `docs:` | `docs` |

The worktree-path uses a `+` separator instead of `/` — a literal `/` would nest `$base/feature/<slug>/` and break `git worktree list` tooling that expects one entry per directory. Knowing this rationale before reading the assignment makes the path shape obvious.

```bash
title_prefix=$(printf '%s' "$title" | sed 's/:.*//')
case "$title_prefix" in
  feat)  bp=feature ;;
  *)     bp="$title_prefix" ;;
esac
slug=$(printf '%s' "$title" \
  | sed 's/^[^:]*: *//' \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
branch="$bp/issue-$issue_number-$slug"
wt_path="$base/$bp+issue-$issue_number-$slug"
```

## Create and enter the worktree

```bash
if git show-ref --verify --quiet "refs/heads/$branch" || [ -e "$wt_path" ]; then
  echo "Branch or worktree already exists for issue #$issue_number: $branch / $wt_path"
  echo "Stop and ask the user whether to reuse it, delete it, or pick a different branch name."
  exit 1
fi
git worktree add "$wt_path" -b "$branch"
```

Then call the `EnterWorktree` tool with `path: <wt_path>`. All subsequent steps (baseline check, sub-agent spawns, etc.) run from inside the worktree.

If the project uses Node (`package.json` present), run `npm install` in the new worktree — `node_modules` is not shared across worktrees and the baseline check in Step 3 will fail without it.
