# Spec Template — chore

Copy this template into `<worktree>/.claude/issue-runs/issue-<issue_number>/spec.md` and fill in each section. Delete template-only guidance in italics before finalizing. Fill every section with concrete content.

Chores are housekeeping changes with no observable user-facing behaviour (tooling, CI, config, lockfile updates, dep bumps, formatter config, etc.).

---

## Spec: Issue #<number> — <title>

**Classification:** chore

**Goal:** _One sentence — what housekeeping outcome._

**Scope (included):**
- _Specific files / configs to change_
- _Dep versions / tool versions if applicable_

**Out of scope:**
- _Source code behaviour changes_
- _Incidental refactors_
- _Dev keeps application tests unchanged; test-config updates are fine when required to complete the chore._

**Constraints:**
- _All existing tests must continue to pass_
- _Lockfile / build artifacts handled per repo convention_
- _CI contract preserved (no command renames / flag removals without updating the CI config in the same PR)_

**Acceptance criteria:**
- [ ] _Housekeeping outcome observable: e.g. "biome upgraded to 1.X.Y, `npm run format` output unchanged on src/"_
- [ ] _`npm run check` passes (or project equivalent)_
- [ ] _CI green_

**Model hint:** `haiku` — _chores are usually mechanical._

_Syntax: `<tier>[<effort>]` — tier is `haiku | sonnet | opus`; optional bracket is effort `low | medium | high | xhigh | max`. Most chores run fine without an effort bracket; add one if the chore touches non-trivial call-site updates._

_Tier options:_
- _`haiku` — default for mechanical chores_
- _`sonnet` — dep bumps with breaking changes that require call-site updates; multi-tool chores_
- _`opus` — rare_

_Guardrail: raise to Sonnet minimum if the chore touches **concurrency, migrations, auth, cryptography, parser edge cases, filesystem race conditions** (e.g. a dep bump for a crypto library) even if the mechanical change looks small._
