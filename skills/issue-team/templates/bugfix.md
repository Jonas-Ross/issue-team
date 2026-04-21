# Spec Template — bugfix

Copy this template into `${CLAUDE_PROJECT_DIR}/.claude/teams/<team-name>/spec.md` and fill in each section. Delete template-only guidance in italics before finalizing. Fill every section with concrete content.

A bugfix spec names the bug precisely and defines the fix by the behaviour that proves it. Root-cause first; workarounds need explicit justification.

---

## Spec: Issue #<number> — <title>

**Classification:** bugfix

**Goal:** _One sentence — the specific incorrect behaviour and what the correct behaviour is._

**Reproducer:**
- _Exact steps to trigger the bug_
- _Expected vs actual_
- _Environment / version if relevant_

**Root cause (hypothesis):** _One sentence — where in the code the bug lives and why it happens. Mark as "unconfirmed" if not yet verified._

**Scope (included):**
- _Files / functions to touch to fix the root cause_
- _Regression test for this specific bug_

**Out of scope:**
- _Adjacent bugs you notice — file separately, do not bundle_
- _Refactoring around the fix — out unless necessary to land the fix correctly_
- _Dev adds only the regression test named in scope; unrelated tests go in a separate issue_

**Constraints:**
- _Fix must be minimal — target the root cause, not symptoms_
- _Existing tests must continue to pass unmodified_
- _Any error-handling conventions to respect (CLAUDE.md)_

**Acceptance criteria:**
- [ ] _Regression test: "given <reproducer steps>, <expected behaviour> holds"_
- [ ] _Full suite passes including the new regression test_
- [ ] _`npm run check` passes (or project equivalent)_

**Model hint:** `sonnet[high]` — _bugfixes almost always need real reasoning about the root cause._

_Syntax: `<tier>[<effort>]` — tier is `haiku | sonnet | opus`; optional bracket is effort `low | medium | high | xhigh | max`. Examples: `sonnet`, `sonnet[high]`, `opus[xhigh]`._

_Tier options:_
- _`haiku` — rare; only for trivially scoped, well-understood bugs with single-file impact_
- _`sonnet` — default; bug diagnosis + fix + regression test_
- _`opus` — deep architectural bug, fix requires judgment about API / invariants_

_For bugfixes, `[high]` or `[xhigh]` is usually the right effort — root-cause reasoning benefits from extra thinking._

_Guardrail: raise to Sonnet minimum if the bug touches **concurrency, migrations, auth, cryptography, parser edge cases, filesystem race conditions** — these domains punish subtle fixes._
