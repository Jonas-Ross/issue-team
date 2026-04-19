# Spec Template — bugfix

Copy this template into `${CLAUDE_PROJECT_DIR}/.claude/teams/<team-name>/spec.md` and fill in each section. Delete template-only guidance in italics before finalizing. **Every section is required**.

A bugfix spec must name the bug precisely and define the fix by the behaviour that proves it. Root-cause first; workarounds need explicit justification.

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
- _Dev may NOT add unrelated tests_

**Constraints:**
- _Fix must be minimal — target the root cause, not symptoms_
- _Existing tests must continue to pass unmodified_
- _Any error-handling conventions to respect (CLAUDE.md)_

**Acceptance criteria:**
- [ ] _Regression test: "given <reproducer steps>, <expected behaviour> holds"_
- [ ] _Full suite passes including the new regression test_
- [ ] _`npm run check` passes (or project equivalent)_

**Model hint:** `sonnet` — _bugfixes almost always need real reasoning about the root cause._

_Model hint options:_
- _`haiku` — rare; only for trivially scoped, well-understood bugs with single-file impact_
- _`sonnet` — default; bug diagnosis + fix + regression test_
- _`opus` — deep architectural bug, fix requires judgment about API / invariants_

_Guardrail: force Sonnet minimum if the bug touches **concurrency, migrations, auth, cryptography, parser edge cases, filesystem race conditions** — these domains punish subtle fixes._
