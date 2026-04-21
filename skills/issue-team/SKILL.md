---
name: issue-team
description: Use when starting a new Claude Code session to implement a GitHub issue - creates an isolated worktree (if launched from main) and runs a right-sized agent team to deliver a PR
---

# Issue Team

Run a right-sized agent team to implement a GitHub issue and deliver a PR.

**Announce:** "I'm using the issue-team skill. Setting up the team for this issue."

<use_parallel_tool_calls>
Throughout this workflow, when independent tool calls can run without waiting on each other's results — e.g. reading `package.json` and `.gitignore` simultaneously, fetching issue details while listing open PRs, or running the three pre-flight gate queries in Step 3.5 — run them in parallel. Never use placeholders or guess missing parameters. Run sequentially only when a later call depends on an earlier result (e.g., the classification drives the branch-name derivation).
</use_parallel_tool_calls>

## Step 0: Workspace Check

You may start this skill either from `main`/`master` or from an existing worktree on a feature branch. The skill creates the worktree for you in Step 2.5 when needed.

```bash
current_branch=$(git branch --show-current)
```

- **On `main` / `master`:** record `needs_worktree=true`. Continue with Step 1. The worktree will be created in Step 2.5 (after the issue is picked and classified, so the branch name can be derived).
- **On any other branch:** verify `git worktree list` includes the current directory. Record `needs_worktree=false` and skip Step 2.5.
- **Detached HEAD or unknown state:** stop and ask the user.

## Step 0a: Resolve Skill Location

The skill can run from either the project `.claude/skills/` or the user-global `~/.claude/skills/`. Resolve the active location before spawning any agents:

```bash
skill_dir=$(ls -d "${CLAUDE_PROJECT_DIR}/.claude/skills/issue-team" "$HOME/.claude/skills/issue-team" 2>/dev/null | head -1)
agents_dir=$(ls -d "${CLAUDE_PROJECT_DIR}/.claude/agents" "$HOME/.claude/agents" 2>/dev/null | head -1)
```

Record these values. Use them verbatim in every later `Read` call and every `Agent` spawn prompt that references a skill-internal file or a team-member system prompt. Every subagent spawn prompt MUST include the lines:

```
Skill dir (resolved by coordinator): <skill_dir value>
Agents dir (resolved by coordinator): <agents_dir value>
```

Subagents reference these values instead of re-resolving paths themselves.

## Step 1: Pick an Issue

```bash
gh issue list --state open --limit 30
```

Display the list. Ask the user which issue number to implement.

Fetch full details:
```bash
gh issue view <number> --json number,title,body,labels,comments
```

Save the issue number and title.

## Step 2: Classify the Issue

Classification determines the agent roster, the model tier, and which agent owns the PR-review gate. Classify from the issue title prefix:

| Title prefix | Class | Team size |
|---|---|---|
| `feat:` | **feature** | 5 agents (coordinator + PM + dev + QA + code-reviewer) |
| `refactor:`, `chore:`, `docs:` | **refactor** | 3 agents (coordinator + dev + QA) |
| `fix:` | **bugfix** | 3 agents (coordinator + dev + QA) |

If the prefix is missing or ambiguous, ask the user: "feature, refactor, or bugfix?"

Save the classification — it drives Steps 5, 6, and 7.

## Step 2.5: Set Up Worktree (skip if `needs_worktree=false`)

If Step 0 set `needs_worktree=true`, create the worktree and swap into it before continuing. Read `$skill_dir/reference/worktree-setup.md` for branch-name derivation, the flat `+` separator rule, the `.gitignore` check, and the Node `npm install` requirement. All subsequent steps run from inside the worktree.

## Step 3: Baseline Check

Confirm a clean baseline before spawning the team. Prefer the project's strongest check command (typecheck + lint + tests) over just tests:

```bash
if grep -q '"check"' package.json 2>/dev/null; then npm run check
elif [ -f package.json ]; then npm test
elif [ -f Cargo.toml ]; then cargo test
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then pytest
elif [ -f go.mod ]; then go test ./...
fi
```

If it fails: report and ask the user whether to proceed or investigate. Hold off on spawning the team while the baseline is broken — a red baseline poisons every downstream signal.

## Step 3.5: Pre-Flight Gates

Before `TeamCreate`, run three cheap gates against the issue: **A** acceptance criteria present, **B** no conflicting open PRs, **C** referenced dependencies resolved. None auto-aborts — each surfaces a question to the user when it fires, and proceeds on approval. Read `$skill_dir/reference/preflight-gates.md` for the exact trigger rules, the `gh` commands to run, and the user-facing phrasing for each gate.

## Step 4: Create the Team

```
TeamCreate with:
  team_name: "issue-<number>"
  description: "Implementing issue #<number> (<classification>): <title>"
  agent_type: "coordinator"
```

## Step 5: Spawn Spec Authors (pre-spec roster)

**Dev and QA are NOT spawned yet.** They are spawned in Step 6 after spec approval, using the model tier picked from the spec's `Model hint`. This keeps token spend down on broken specs and lets the coordinator size dev/QA to the real task.

**`feature` classification — spawn PM and code-reviewer:**

```
Agent:
  subagent_type: "issue-team-pm"
  team_name: "issue-<number>"
  name: "pm"
  model: "opus"
  mode: "auto"
  prompt: |
    Skill dir (resolved by coordinator): <skill_dir>
    Agents dir (resolved by coordinator): <agents_dir>

Agent:
  subagent_type: "superpowers:code-reviewer"
  team_name: "issue-<number>"
  name: "code-reviewer"
  model: "sonnet"
  mode: "auto"
  prompt: |
    Team: issue-<number>. Branch: <branch>. Worktree: <worktree-path>.
    Skill dir (resolved by coordinator): <skill_dir>
    Agents dir (resolved by coordinator): <agents_dir>
    Read and follow $skill_dir/agents/code-reviewer.md.
    Wait for a task to be assigned before starting.
```

The dev, pm, and qa agents have full system prompts (`agents/issue-team-{dev,pm,qa}.md`) that already contain every rule and decision point. Only `code-reviewer` needs an explicit `Read and follow` line because it reuses the external `superpowers:code-reviewer` subagent type.

**`refactor` / `bugfix` / `chore` / `docs` classification — no agent spawns here.** Coordinator writes the spec inline in Step 6.

## Step 6: Write / Approve Spec, Then Spawn Dev and QA

Read your own name from the team config:

```bash
cat ~/.claude/teams/issue-<number>/config.json
```

Find the entry whose name is not `pm`, `dev`, `qa`, or `code-reviewer`.

### 6a. Write or commission the spec

**Spec template lookup order (used by PM for feature, by coordinator for refactor/bugfix/chore/docs):**

1. `<worktree>/.claude/spec-templates/<class>.md` — repo-local override, if the project ships its own template
2. `$skill_dir/templates/<class>.md` — skill default (`feat`, `refactor`, `bugfix`, `chore`, `docs`)
3. Inline skeleton in the agent's own instructions — last-resort fallback

Whoever writes the spec reads the first existing template in this order, copies the fields into `${CLAUDE_PROJECT_DIR}/.claude/teams/<team-name>/spec.md`, and fills every section. Missing templates fall through silently to the next option — no error.

**`feature` classification — PM writes the spec.**

```
TaskCreate:
  subject: "Implement issue #<number>: <title>"
  description: |
    Issue number: <number>
    Title: <title>
    Classification: feature
    Body: <full issue body>
    Comments: <full comments JSON>

    Team members: pm, dev, qa, code-reviewer
    Coordinator name: <your name>
    Worktree path: <cwd>
    Base branch: <output of git rev-parse --abbrev-ref HEAD>
  metadata:
    issue_number: "<number>"
    classification: "feature"

TaskUpdate: taskId: <id>, owner: "pm"

SendMessage to: "pm"
  summary: "Pick up task and write the spec"
  message: |
    Task #<id> assigned. Issue #<number>, classification: feature.
    Team members: pm, dev, qa, code-reviewer. Coordinator: <your name>.
    Worktree: <cwd>. Base branch: <branch>.

    Write the spec to ${CLAUDE_PROJECT_DIR}/.claude/teams/issue-<number>/spec.md, then message me
    the file path for review. Do not brief dev or qa until I approve.
```

**`refactor` or `bugfix` classification — YOU (coordinator) write the spec.**

Load the class template per the lookup order above and copy its fields into `${CLAUDE_PROJECT_DIR}/.claude/teams/issue-<number>/spec.md`. Fill every section. Every spec produced by this flow needs a `Model hint:` line — used in Step 5 to pick the dev/QA model tier.

At minimum a spec contains:
- **Goal** — one sentence
- **Scope** — what is included
- **Out of scope** — what is explicitly excluded, including whether dev may add new tests beyond those implied by the spec
- **Constraints** — conventions, patterns, rules
- **Acceptance criteria** — testable checklist
- **Model hint** — `haiku | sonnet | opus` with a one-sentence reason

Then proceed to Step 6b.

### 6b. Spec approval gate (feature only) — Checkpoint 1

**Optional sub-skill:** scan your available-skills list for any skill whose description matches "spec review" (e.g., evaluating a written spec for completeness, testability, or scope). If one exists, invoke it via the Skill tool before approving. Otherwise do the review inline: confirm the spec has a clear goal, explicit scope in/out, testable acceptance criteria, and a `Model hint` line.

PM writes `spec.md` and messages you with the path. Read the file. Approve or send specific feedback. Do not proceed to 6c until approved.

For refactor/bugfix/chore/docs: skip — you authored the spec.

### 6c. Pick model tier and effort from spec's Model hint (+ guardrails)

Read the `Model hint:` line from the approved spec. The hint syntax is:

```
Model hint: <tier>[<effort>] — <reason>
```

Where `<tier>` is `haiku | sonnet | opus` and `[<effort>]` is an optional bracketed `low | medium | high | xhigh | max` that will be passed to dev and QA at spawn time. Examples:

- `Model hint: sonnet — normal feature work` (tier only; spawn without explicit effort)
- `Model hint: sonnet[high] — auth flow, needs careful reasoning` (tier + effort)
- `Model hint: opus[xhigh] — novel design, long horizon` (max-capability combo)

Parse the tier as the default, and parse the bracket as the effort if present.

**Guardrail — raise to Sonnet minimum if the spec touches concurrency, migrations, auth, cryptography, parser edge cases, or filesystem race conditions.** See `$skill_dir/reference/model-guardrails.md` for the full domain list and the rationale for each. If the hint is `haiku` but the spec touches any of these, upgrade to `sonnet` and note the override. If the hint is `opus`, the guardrail does not downgrade.

Record the tier decision (hint value, final value, override reason if any) — the retro in Step 9 surfaces it.

### 6d. Spawn dev and QA at chosen tier

Use the tier from 6c for both dev and QA:

```
Agent:
  subagent_type: "issue-team-dev"
  team_name: "issue-<number>"
  name: "dev"
  model: "<tier from 6c>"
  effort: "<effort from 6c, if specified>"
  mode: "auto"
  prompt: |
    Skill dir (resolved by coordinator): <skill_dir>
    Agents dir (resolved by coordinator): <agents_dir>

Agent:
  subagent_type: "issue-team-qa"
  team_name: "issue-<number>"
  name: "qa"
  model: "<tier from 6c>"
  effort: "<effort from 6c, if specified>"
  mode: "auto"
  prompt: |
    Skill dir (resolved by coordinator): <skill_dir>
    Agents dir (resolved by coordinator): <agents_dir>
```

Include the `effort:` line only when the spec's `Model hint` specified one in bracket syntax (see 6c). Dev and QA each have full system prompts (`agents/issue-team-{dev,qa}.md`) — they don't need a `Read and follow` line.

### 6e. Brief the team

**`feature` classification:** message PM to brief dev and QA now that both exist:

```
SendMessage to: "pm"
  summary: "Spec approved — dev and QA now spawned, brief them"
  message: |
    Spec approved. I've spawned dev and qa at tier <tier>.
    Proceed with your Step 4: brief qa first (write acceptance tests,
    wait for my approval), then brief dev.
```

**`refactor` / `bugfix` / `chore` / `docs` classification:** brief QA directly — you authored the spec, no PM to relay:

```
TaskCreate (metadata.classification: "<class>")
TaskUpdate: owner: "qa"

SendMessage to: "qa"
  summary: "Spec ready — write acceptance tests"
  message: |
    Task #<id> assigned. Issue #<number>, classification: <class>.
    Coordinator: <your name>. Worktree: <cwd>. Base branch: <branch>.
    Spec: ${CLAUDE_PROJECT_DIR}/.claude/teams/issue-<number>/spec.md — read directly.

    Write acceptance tests, then message me the test file path. Do not brief
    dev until I approve the tests.
```

## Step 7: Monitor as Coordinator

Stay active. Messages from teammates are delivered automatically.

**Peer DM visibility:** teammate-to-teammate DMs surface as brief summaries in idle notifications. Use these to track progress without intervening — unless you see signs of confusion, stalling, or scope creep.

### Advisory state machine

Each teammate emits a `phase` metadata value on their task via `TaskUpdate({taskId, metadata: {phase: "<value>"}})` at natural transitions. **This is advisory — coordinator reads for situational awareness, never blocks on a missing or late phase.** A teammate that forgets to emit a phase is not broken.

Phase vocabulary (shared across roles):

| Phase | Role emits | Trigger |
|---|---|---|
| `spec_drafting` | pm (or coordinator for refactor/bugfix) | Started writing the spec |
| `spec_approved` | pm (or coordinator) | team-lead approved the spec |
| `tests_writing` | qa | Started writing acceptance tests |
| `tests_approved` | qa | team-lead approved the acceptance tests |
| `impl_started` | dev | Claimed first implementation task |
| `impl_blocked` | dev | Raised a blocker that requires external input |
| `pr_opened` | dev | `gh pr create --draft` succeeded |
| `review_requested` | reviewer (qa or code-reviewer) | Began reviewing |
| `review_approved` | reviewer | Report sent to team-lead |
| `review_changes_requested` | reviewer | Changes-needed report sent to team-lead |
| `undrafted` | dev | `gh pr ready` succeeded |
| `failed` | any | Giving up / unresolvable blocker |

The coordinator may scan `TaskList` at any time to see current phases across the team. Phase checks are advisory; fall back to explicit messages when routing decisions matter.

### Progress updates

Share progress with the user at natural inflection points — spec approved, tests approved, PR opened, review complete, un-drafted. Opus 4.7 calibrates the cadence and length of these updates natively; a single short sentence per inflection point is usually the right shape. Avoid fixed counters or format templates — they over-fire on short runs and under-fire on long ones.

### Checkpoint 2 — Acceptance test review

QA writes tests and messages you with the file path. Read the file and verify coverage of every acceptance criterion. If satisfied, tell QA to notify dev to begin implementation. Otherwise, send feedback first.

### Checkpoint 3 — PR review (single gate, classification-aware)

Dev will notify YOU (and only you) that the draft PR is open. Before assigning a review task, scan the diff for sub-gate triggers (below), then assign **one** review task based on classification — do not assign review to multiple agents in parallel.

**3a. Diff-triggered sub-gates (coordinator runs these inline, before the main review).**

Scan the diff:

```bash
gh pr diff <number> --name-only
gh pr diff <number>    # full diff if dependency review fires
```

For each diff pattern below, do the extra scrutiny named in the right-hand column. Run the sub-gate synchronously by the coordinator (NOT delegated to a spawned agent). A sub-gate that finds a real concern **blocks un-drafting** — relay the findings to dev via SendMessage before proceeding.

| Diff pattern | Extra scrutiny needed |
|---|---|
| Any path matching `src/**/auth*` or `**/session*` | auth / session review: authentication and authorization changes, token handling, timing leaks |
| Any `**/*.sql` or `**/migrations/**` change | migration safety review: schema changes, backfills, lock / downtime risk, reversibility |
| New entry added to `package.json` `dependencies` or `devDependencies` | dependency review: license, maintenance health, supply-chain risk |
| Change to `src/index.ts` OR diff introduces a new `server.tool(` call | MCP tool audit: tool surface, input validation, side effects, error paths |

**How to run each sub-gate:** scan your available-skills list for a skill whose description matches the review type (e.g., a skill named or described as reviewing auth, migrations, dependencies, or MCP tools). If one exists, invoke it via the Skill tool and use its `pass` / `changes_requested` verdict. Otherwise do the check inline — inspect the diff against the concern named in the table and produce your own verdict. Either way, record the outcome in your task notes (e.g., `sub-gate auth: pass (inline)` or `sub-gate deps: changes_requested via skill <name>`).

**3b. Assign the main review.**

**`refactor` / `bugfix`:** QA is the gate.

```
TaskCreate: "PR review for issue #<number>" → TaskUpdate owner: "qa"
SendMessage to: "qa" — review the draft PR, report pass/changes to me
```

**`feature`:** code-reviewer is the gate. QA's job is done — their acceptance tests already gate correctness via `npm run check`.

```
TaskCreate: "Code review PR for issue #<number>" → TaskUpdate owner: "code-reviewer"
SendMessage to: "code-reviewer" — review the draft PR, report verdict + findings to me
```

**3c. Consume the reviewer verdict.**

Code-reviewer reports with the schema defined in `$skill_dir/agents/code-reviewer.md` — verdict + counts + finding list, each finding tagged `[severity][confidence]`. QA (refactor/bugfix) reports with a prose pass/changes verdict. Handle each verdict type:

- **`approved` with minors/nits attached** → authorize un-drafting (Checkpoint 4) and forward the finding list to Dev as non-blocking suggestions in the un-draft message. Dev decides whether to address inline or file follow-up issues.
- **`approved` with nothing attached** → authorize un-drafting immediately; nothing to forward.
- **`changes_requested`** → relay `blocker` findings and high-confidence `major` findings to Dev as required changes. For low-confidence `major` findings, relay with: "reviewer flagged with low confidence — confirm intent, then address or justify dismissal." Do not forward `minor`/`nit` findings in a changes-requested loop unless Dev asks.
- **Malformed reply** (no schema match) → parse the first word of the message as the verdict (`approved` / `changes_requested`); ignore finding tags. Record `sub-gate note: reviewer reply did not match schema` in your task notes.

Record the finding counts in your Step 9 retro notes.

Loop until the reviewer returns `approved`.

### Checkpoint 4 — Authorize un-draft (coordinator-only)

Once the PR review gate approves:

1. Verify the PR body contains `Closes #<number>`. If missing, tell dev to add it; do not un-draft yet.
2. Create a dedicated un-draft task for dev and gate it on the review task's phase via `metadata.requires`:

   ```
   TaskCreate: "Un-draft PR #<number>" → TaskUpdate
     owner: "dev"
     addBlockedBy: [<review task id>]
     metadata: { requires: { "<review task id>": "review_approved" } }
   ```

   Two layers of defense:
   - `addBlockedBy` prevents dev from claiming it until the review task is completed.
   - `metadata.requires` — enforced by the `TaskCompleted` hook (`$skill_dir/hooks/gate-task-completion.sh`) — blocks completion unless the review task reached `phase: review_approved` (not just `status: completed`).
3. Send dev the un-draft authorization: *"PR review approved. Un-draft PR #<number> via `gh pr ready <number>`, then mark the un-draft task complete."*
4. Dev un-drafts once and completes the task. If the hook blocks, the reviewer hasn't emitted `review_approved` — investigate before overriding.

Only the coordinator authorizes un-drafting. Peer-to-peer approval messages can cross in flight — a single gate prevents Dev from un-drafting on a premature "approved" signal from QA before code-reviewer finishes, or vice versa. If PM, QA, or code-reviewer suggests un-drafting to Dev, correct them. Draft state is the review gate; one linear flip to non-draft.

### General

**Escalations:** if a teammate asks something that needs the user, surface to the user with: what's blocked, what's tried, a specific question. Relay the answer back via SendMessage (include a `summary` field).

**Re-sends:** agents may re-send a completion message if your acknowledgment crosses theirs. If you already replied, re-confirm briefly and move on.

**Stale check:** long gap without messages from an owning teammate → send a check-in. If still no response, surface to the user.

## Step 8: Shutdown

When dev confirms the PR is un-drafted and linked to the issue, send `shutdown_request` to the agents you actually spawned — address only those present on the team (refactor/bugfix teams have no PM or code-reviewer):

```
SendMessage to: "dev"           message: {type: "shutdown_request", reason: "PR open and linked — work complete"}
SendMessage to: "qa"            message: {type: "shutdown_request", reason: "PR open and linked — work complete"}
# feature only:
SendMessage to: "pm"            message: {type: "shutdown_request", reason: "PR open and linked — work complete"}
SendMessage to: "code-reviewer" message: {type: "shutdown_request", reason: "PR open and linked — work complete"}
```

Wait for all `shutdown_approved` + `teammate_terminated` notifications, then proceed to Step 9.

## Step 9: Retrospective (before TeamDelete)

After all teammates report `shutdown_approved` and before calling `TeamDelete`, run the retrospective defined in `$skill_dir/reference/retrospective.md` — it's the only point in the workflow where durable lessons can be captured, because `TeamDelete` clears the task history.

The retro is short: read run history (`TaskList` + targeted `TaskGet`), self-ask three questions (what cost more than expected, where did routing break, what pattern would help next time), and only write a feedback memory if a durable lesson emerged. After the retro, call `TeamDelete` and report the PR URL to the user, with a one-line retro summary if a memory was written.
