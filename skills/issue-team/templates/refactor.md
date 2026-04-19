# Spec Template — refactor

Copy this template into `${CLAUDE_PROJECT_DIR}/.claude/teams/<team-name>/spec.md` and fill in each section. Delete template-only guidance in italics before finalizing. **Every section is required**.

Refactors change structure without changing observable behaviour. The acceptance criteria should prove that.

---

## Spec: Issue #<number> — <title>

**Classification:** refactor

**Goal:** _One sentence — the structural improvement, and why (readability / duplication / module boundaries / etc)._

**Scope (included):**
- _Specific files / modules to split, rename, move, extract, or consolidate_
- _Any export-surface changes required_

**Out of scope:**
- _Behaviour changes (refactor must not change observable behaviour)_
- _Incidental cleanup that tempts "while I'm here" edits_
- _New features, bug fixes, perf tuning_
- _Dev may NOT add new tests beyond those required to maintain parity_

**Constraints:**
- _Public API / import paths to preserve_
- _Test suite must continue to pass without modification (exception: import-path updates)_
- _Code conventions to respect (CLAUDE.md references)_

**Acceptance criteria:**
- [ ] _Structural outcome: e.g. "src/X.ts is split into src/X/a.ts, src/X/b.ts, src/X/c.ts with a barrel at src/X/index.ts"_
- [ ] _Behavioural parity: "all existing tests pass without modification, except import-path updates"_
- [ ] _`npm run check` passes (or project equivalent)_

**Model hint:** `haiku` — _clean mechanical refactors benefit from Haiku speed._

_Model hint options:_
- _`haiku` — default for mechanical, contained refactors_
- _`sonnet` — cross-module refactor, subtle type gymnastics, non-trivial public API reshaping_
- _`opus` — rare; architecture-level restructure with competing design axes_

_Guardrail: force Sonnet minimum if refactor touches **concurrency, migrations, auth, cryptography, parser edge cases, filesystem race conditions** — even Haiku-clean refactors in these areas mis-land subtle invariants._
