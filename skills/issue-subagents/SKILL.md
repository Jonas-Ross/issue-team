---
name: issue-subagents
description: Use when implementing a GitHub issue with single-session, one-shot sub-agents (no persistent team) — creates an isolated worktree, drives spec → tests → implementation → review → PR. Lightweight; no experimental flag required.
---

# Issue Subagents

Sub-agent variant of `issue-team`. Same git flow (worktree → spec → acceptance tests → implementation → draft PR → review → un-draft → retro), but the orchestrator (this session) drives every step and spawns one-shot sub-agents via the `Agent` tool — no persistent team, no peer messaging.

**Announce:** "I'm using the issue-subagents skill. Driving sub-agents through the issue flow."

<use_parallel_tool_calls>
When independent tool calls can run without waiting on each other's results — e.g. reading `package.json` and `.gitignore` simultaneously, fetching issue details while listing open PRs, or running the three pre-flight gate queries — run them in parallel. Run sequentially only when a later call depends on an earlier result.
</use_parallel_tool_calls>

## How this differs from `issue-team`

| Concern | `issue-team` (team) | `issue-subagents` (this skill) |
|---|---|---|
| Agents | Persistent peers via `TeamCreate` | One-shot sub-agents via `Agent` |
| Coordination | `SendMessage` peer routing through `team-lead` | Orchestrator drives every step; sub-agents return results |
| Approval routing | Single gate at coordinator (prevents crossed signals) | Single gate at orchestrator (only one gate exists by design) |
| Un-draft enforcement | `TaskCompleted` hook + `metadata.requires` | Orchestrator runs `gh pr ready` itself, after review |
| Spec location | `~/.claude/teams/<team>/spec.md` | `<worktree>/.claude/issue-runs/issue-<issue_number>/spec.md` (gitignored on the feature branch) |
| Subagent types | `issue-team-{pm,dev,qa}` + `superpowers:code-reviewer` | `issue-subagents-pm`, `issue-subagents-dev`, `issue-subagents-qa`, `issue-subagents-code-reviewer` (all four ship with this plugin) |

The git flow, classification rules, model-tier guardrails, sub-gates, and retrospective are functionally equivalent.

## Soft dependencies

Sub-agents may invoke optional `superpowers:*` skills if installed: `test-driven-development`, `verification-before-completion`, `writing-good-pr-descriptions`, `code-review-checklist`. None are required — sub-agent returns will include `sub-skill missing: <name>` notes when one is unavailable, and the workflow proceeds.

## Step 0: Workspace Check

You may start from `main`/`master` or from an existing worktree on a feature branch. The worktree is created in Step 2.5 when needed.

```bash
current_branch=$(git branch --show-current)
```

- **On `main` / `master`:** record `needs_worktree=true`. Continue with Step 1.
- **On any other branch:** verify `git worktree list` includes the current directory. Record `needs_worktree=false` and skip Step 2.5.
- **Detached HEAD or unknown state:** stop and ask the user.

## Step 0a: Resolve Skill Location

The skill can run from either project `.claude/skills/` or user-global `~/.claude/skills/`. Resolve once:

```bash
skill_dir=$(ls -d "${CLAUDE_PROJECT_DIR}/.claude/skills/issue-subagents" "$HOME/.claude/skills/issue-subagents" 2>/dev/null | head -1)
[ -z "$skill_dir" ] && { echo "issue-subagents skill not found in either ${CLAUDE_PROJECT_DIR}/.claude/skills/ or ~/.claude/skills/"; exit 1; }
```

`skill_dir` is the orchestrator's own variable, used to read `reference/*.md` and `templates/*.md`. The PM spawn forwards it to PM as a `Templates dir:` field; the other three sub-agent types (`issue-subagents-{dev,qa,code-reviewer}`) carry their playbooks as system prompts and don't need it.

## Step 1: Pick an Issue

```bash
gh issue list --state open --limit 30
```

Display the list. Ask the user which issue number to implement. Save it as `issue_number`. Then fetch the title (full body and comments are persisted to disk in Step 3.6, after the worktree exists):

```bash
gh issue view <issue_number> --json title --jq .title
```

Save the title as `title`.

## Step 2: Classify the Issue

Five class strings, each driving template selection and branch prefix. Roster (PM-led vs orchestrator-led) is a separate axis.

| Title prefix | Class string | Roster | Reviewer at PR-review time |
|---|---|---|---|
| `feat:` | **feat** | PM-led (PM writes spec) | code-reviewer |
| `fix:` | **bugfix** | orchestrator-led | qa (review mode) |
| `refactor:` | **refactor** | orchestrator-led | qa (review mode) |
| `chore:` | **chore** | orchestrator-led | qa (review mode) |
| `docs:` | **docs** | orchestrator-led | qa (review mode) |

The class string matches the template file stem in `templates/<class>.md`. If the prefix is missing or ambiguous, ask the user which class applies.

Save the class string — it is passed verbatim to every sub-agent except code-reviewer (feature-only, no `Classification:` line needed).

## Step 2.5: Set Up Worktree (skip if `needs_worktree=false`)

If `needs_worktree=true`, create the worktree and swap into it before continuing. Read `$skill_dir/reference/worktree-setup.md` for branch-name derivation, the `+` separator rule, the `.gitignore` check, and the Node `npm install` requirement. All subsequent steps run from inside the worktree.

## Step 3: Baseline Check

Confirm a clean baseline before spawning sub-agents:

```bash
if grep -q '"check"' package.json 2>/dev/null; then npm run check
elif [ -f package.json ]; then npm test
elif [ -f Cargo.toml ]; then cargo test
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then pytest
elif [ -f go.mod ]; then go test ./...
fi
```

If it fails: report and ask the user whether to proceed or investigate. A red baseline poisons every downstream signal.

## Step 3.5: Pre-Flight Gates

Run the three cheap gates from `$skill_dir/reference/preflight-gates.md` (acceptance criteria present, no conflicting open PRs, referenced dependencies resolved). None auto-aborts — each surfaces a question to the user when it fires, and proceeds on approval. **If none of A/B/C trigger, do not announce — proceed silently to Step 3.6.**

## Step 3.6: Run-State Directory and `.gitignore`

Persist the issue body and comments inside the worktree, and add the run-state directory to `.gitignore` on the feature branch. This step runs unconditionally — it covers both the freshly-created-worktree case and the started-in-an-existing-worktree case. All paths are relative to the current working directory (the worktree).

```bash
mkdir -p .claude/issue-runs/issue-<issue_number>
gh issue view <issue_number> --json body --jq .body > .claude/issue-runs/issue-<issue_number>/body.md
gh issue view <issue_number> --json comments > .claude/issue-runs/issue-<issue_number>/comments.json

if ! grep -qxF '.claude/issue-runs/' .gitignore 2>/dev/null; then
  printf '%s\n' '.claude/issue-runs/' >> .gitignore
  git add .gitignore && git commit -m "chore: ignore .claude/issue-runs/"
fi
```

The spec written in Step 4 lands in the same directory.

Compute and save the absolute worktree path now — sub-agents need an absolute path to read these files reliably regardless of how the harness sets their cwd:

```bash
worktree_abs=$(pwd)
```

Use `$worktree_abs` (substituted to the literal path string) wherever spawn prompts reference run-state files.

## Step 4: Write / Approve the Spec

Spec target path: `<worktree_abs>/.claude/issue-runs/issue-<issue_number>/spec.md`.

**Template lookup order** (used by PM for the `feat` class, by orchestrator for the other four):

1. `<worktree_abs>/.claude/spec-templates/<class>.md` — repo-local override (each project may ship its own)
2. `<skill_dir>/templates/<class>.md` — skill default
3. Inline skeleton in the role's playbook — last-resort fallback

Where `<class>` is the saved class string from Step 2 (`feat | refactor | bugfix | chore | docs`). The class string and the template file stem are intentionally identical to avoid drift.

Whoever writes the spec reads the first existing template, copies the fields into the spec path, and fills every section. Every spec needs a `Model hint:` line — used in Step 5 to pick the dev/QA model tier.

### 4a. `feat` class — spawn the PM sub-agent

```
Agent
  subagent_type: "issue-subagents-pm"
  description: "Write spec for issue #<issue_number>"
  model: "opus"
  prompt: |
    Issue number: <issue_number>
    Title: <title>
    Classification: feat
    Body path: <worktree_abs>/.claude/issue-runs/issue-<issue_number>/body.md
    Comments path: <worktree_abs>/.claude/issue-runs/issue-<issue_number>/comments.json
    Worktree: <worktree_abs>
    Base branch: <base_branch>
    Templates dir: <skill_dir>/templates
    Spec target: <worktree_abs>/.claude/issue-runs/issue-<issue_number>/spec.md

    Read the body, comments, and the relevant code paths. Write the spec to the
    target path per your playbook. Return the spec path and a one-paragraph summary.
```

Substitute every `<...>` placeholder with its resolved value before sending. When the agent returns, read the spec file. Approve inline (confirm goal, scope in/out, testable acceptance criteria, `Model hint:` line) or re-spawn the PM with specific feedback. Loop until you approve.

### 4b. `refactor` / `bugfix` / `chore` / `docs` — orchestrator writes the spec

Load the class template per the lookup order above and copy its fields into the spec path. Fill every section yourself, including the `Model hint:` line. Then proceed to Step 5.

## Step 5: Pick Model Tier and Effort from Spec's Model Hint

Read the `Model hint:` line from the approved spec. Hint syntax:

```
Model hint: <tier>[<effort>] — <reason>
```

`<tier>` is `haiku | sonnet | opus`. The bracket `[<effort>]` (`low | medium | high | xhigh | max`) is optional. Examples:

- `Model hint: sonnet — normal feature work` (tier only)
- `Model hint: sonnet[high] — auth flow, needs careful reasoning`
- `Model hint: opus[xhigh] — novel design, long horizon`

The **tier** maps to the `model:` field on Agent spawns. The **effort** is not a parameter on the Agent tool — instead, when the spec specifies an effort bracket, include a `Reasoning effort target: <value>` line in the prompt body of every dev and QA spawn (test-author, review, fix-loop). Sub-agents read the line and self-apply.

**Guardrail:** raise to Sonnet minimum if the spec touches concurrency, migrations, auth, cryptography, parser edge cases, or filesystem race conditions — see `$skill_dir/reference/model-guardrails.md`. If the hint is `haiku` and any of these apply, upgrade to `sonnet` and note the override. `sonnet`/`opus` hints are not downgraded.

Record the tier decision (hint, final value, override reason if any) — surfaces in the Step 10 retro.

## Step 6: Spawn QA — Write Acceptance Tests

```
Agent
  subagent_type: "issue-subagents-qa"
  description: "Write acceptance tests for issue #<issue_number>"
  model: "<tier>"
  prompt: |
    Mode: test-author
    Issue number: <issue_number>
    Classification: <class>
    Worktree: <worktree_abs>
    Base branch: <base_branch>
    Spec path: <worktree_abs>/.claude/issue-runs/issue-<issue_number>/spec.md
    Reasoning effort target: <effort>   # only include if Step 5 produced an effort bracket

    Read the spec, write acceptance tests covering every criterion, commit them,
    and return the test_paths block per your playbook Step 3.
```

When the sub-agent returns: read the test file(s) listed in `test_paths:` and verify coverage of every acceptance criterion. If satisfied, proceed to Step 7. If gaps exist, re-spawn QA with specific feedback. Loop until approved.

Save the returned `test_paths:` (newline-delimited) and `test_command:` — Dev needs both.

## Step 7: Spawn Dev — Implement and Open Draft PR

```
Agent
  subagent_type: "issue-subagents-dev"
  description: "Implement issue #<issue_number>"
  model: "<tier>"
  prompt: |
    Mode: implement
    Issue number: <issue_number>
    Title: <title>
    Classification: <class>
    Worktree: <worktree_abs>
    Base branch: <base_branch>
    Spec path: <worktree_abs>/.claude/issue-runs/issue-<issue_number>/spec.md
    Acceptance test paths (newline-delimited):
    <test_paths from Step 6>
    Test command: <test_command from Step 6>
    Reasoning effort target: <effort>   # only include if Step 5 produced an effort bracket

    Implement against the acceptance tests using TDD per your playbook. Open the
    draft PR (substitute the actual issue number into "Closes #<issue_number>" — do NOT
    leave a literal placeholder). Return the PR URL, PR number, tasks completed, and
    any non-obvious decisions.
```

When the sub-agent returns: save the `PR URL` and `PR number`. Proceed to Step 8.

## Step 8: PR Review (single gate, classification-aware)

### 8a. Diff-triggered sub-gates (orchestrator runs inline, before main review)

Scan the diff:

```bash
gh pr diff <pr_number> --name-only
gh pr diff <pr_number>    # full diff if a sub-gate fires
```

For each pattern below, do the extra scrutiny named on the right. Run the sub-gate synchronously yourself (do not spawn a sub-agent for this). A sub-gate that finds a real concern blocks un-drafting — re-spawn dev with the findings before proceeding.

| Diff pattern | Extra scrutiny needed |
|---|---|
| Any path matching `src/**/auth*` or `**/session*` | auth / session review: authentication and authorization changes, token handling, timing leaks |
| Any `**/*.sql` or `**/migrations/**` change | migration safety review: schema changes, backfills, lock / downtime risk, reversibility |
| New entry added to `package.json` `dependencies` or `devDependencies` | dependency review: license, maintenance health, supply-chain risk |
| Change to `src/index.ts` OR diff introduces a new `server.tool(` call | MCP tool audit: tool surface, input validation, side effects, error paths |

For each fired sub-gate, scan your available-skills list for a skill whose description matches the review type. If one exists, invoke it via the Skill tool and use its verdict. Otherwise inspect inline. Record the outcome (`sub-gate auth: pass (inline)` etc.) — surfaces in the Step 10 retro.

### 8b. Spawn the main review

**Class is `refactor`, `bugfix`, `chore`, or `docs`:** spawn QA in review mode.

```
Agent
  subagent_type: "issue-subagents-qa"
  description: "Review PR #<pr_number> for issue #<issue_number>"
  model: "<tier>"
  prompt: |
    Mode: review
    Issue number: <issue_number>
    Classification: <class>
    Worktree: <worktree_abs>
    Base branch: <base_branch>
    Spec path: <worktree_abs>/.claude/issue-runs/issue-<issue_number>/spec.md
    PR number: <pr_number>
    PR URL: <pr_url>

    Per your playbook Steps 4–5: run the full check, review the diff against the
    spec, smoke-test the changed code, and return the verdict block (approved or
    changes_requested with file:line + what's wrong + what it should do instead).
```

**Class is `feat`:** spawn the code-reviewer.

```
Agent
  subagent_type: "issue-subagents-code-reviewer"
  description: "Code review PR #<pr_number> for issue #<issue_number>"
  model: "sonnet"
  prompt: |
    Issue number: <issue_number>
    Worktree: <worktree_abs>
    Base branch: <base_branch>
    Spec path: <worktree_abs>/.claude/issue-runs/issue-<issue_number>/spec.md
    PR number: <pr_number>
    PR URL: <pr_url>

    Per your playbook: read the spec, fetch the diff, review against the four
    categories (security, correctness, conventions, scope), tag every finding with
    [severity][confidence], and return the verdict block.
```

### 8c. Consume the verdict

Both reviewer types return a structured block. Code-reviewer's schema:

```
verdict: <approved | changes_requested>
counts: blockers=<n> majors=<n> minors=<n> nits=<n>

findings:
- [<severity>][<confidence>] <path>:<line> — <issue> — <fix>
...
```

If counts are all zeros, the `findings:` section is omitted — treat as approved with nothing attached.

QA's review-mode schema:

```
mode: review
verdict: <approved | changes_requested>
verified: <list>           # only on approved
test_results: <pass/fail>  # only on changes_requested
issues:                    # only on changes_requested
1. <what's wrong> — <file:line> — <what it should do instead>
...
```

Handle each verdict type:

- **`approved` with minors/nits attached (code-reviewer)** → proceed to Step 9 (un-draft). Forward findings to the user as non-blocking suggestions; the user decides whether to address inline or file follow-up issues.
- **`approved` with nothing attached** → proceed to Step 9 immediately.
- **`changes_requested`** → proceed to Step 8d.
- **Malformed reply** (no schema match) → take the first word of the message as the verdict (`approved` / `changes_requested`); ignore finding tags. Record `sub-gate note: reviewer reply did not match schema` for the retro.

Record the finding counts for the Step 10 retro.

### 8d. Fix loop — re-spawn Dev with required changes

Build the change list:

- Include all `blocker` findings and high-confidence `major` findings as required changes.
- Include low-confidence `major` findings with a note: "reviewer flagged with low confidence — confirm intent, then address or justify dismissal."
- Skip `minor`/`nit` findings unless the reviewer marked them required.
- Include any sub-gate findings from 8a.

Translate each finding into Dev's expected format `<file:line> — <what's wrong> — <what it should do instead>` (code-reviewer's format orders these the same way; QA's review format puts what's-wrong first and needs reordering).

Re-spawn dev:

```
Agent
  subagent_type: "issue-subagents-dev"
  description: "Address review findings on PR #<pr_number>"
  model: "<tier>"
  prompt: |
    Mode: fix-loop
    Issue number: <issue_number>
    Title: <title>
    Worktree: <worktree_abs>
    Base branch: <base_branch>
    Spec path: <worktree_abs>/.claude/issue-runs/issue-<issue_number>/spec.md
    Acceptance test paths (newline-delimited):
    <test_paths from Step 6>
    Test command: <test_command from Step 6>
    PR number: <pr_number>
    Reasoning effort target: <effort>   # only include if Step 5 produced an effort bracket

    Required changes:
    1. <file:line> — <what's wrong> — <what it should do instead>
    2. <file:line> — <what's wrong> — <what it should do instead>

    Fix every required change using TDD where appropriate. Run the full check
    (everything green), git push, and return a one-line-per-issue summary.
```

Loop back to Step 8a (sub-gates may fire again on the new diff) → 8b → 8c. Repeat until the reviewer returns `approved`.

## Step 9: Un-Draft (orchestrator)

Once the review gate is `approved`, do the body-`Closes` check + un-draft inline. No sub-agent is needed — both operations are mechanical.

```bash
# 1. Verify the body has Closes #<issue_number>; append if missing.
current_body=$(gh pr view <pr_number> --json body --jq .body)
if ! printf '%s' "$current_body" | grep -qF "Closes #<issue_number>"; then
  gh pr edit <pr_number> --body "$(printf '%s\n\nCloses #%s\n' "$current_body" "<issue_number>")"
fi

# 2. Un-draft.
gh pr ready <pr_number>

# 3. Confirm.
gh pr view <pr_number> --json isDraft,url
```

Substitute `<pr_number>` and `<issue_number>` with their saved values before running. Only the orchestrator un-drafts — there is no peer-approval routing in this skill, so review-approved → orchestrator un-drafts.

## Step 10: Retrospective

Run the retrospective from `$skill_dir/reference/retrospective.md` — same questions, same memory format. After the retro, report the PR URL to the user, with a one-line retro summary if a memory was written.
