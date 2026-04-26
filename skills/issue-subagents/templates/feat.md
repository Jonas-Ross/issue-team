# Spec Template — feat

Copy this template into `<worktree>/.claude/issue-runs/issue-<issue_number>/spec.md` and fill in each section. Delete template-only guidance in italics before finalizing. Fill every section with concrete content — vague or incomplete fields degrade every downstream decision.

---

## Spec: Issue #<number> — <title>

**Classification:** feat

**Goal:** _One sentence — the observable behaviour this change adds._

**Scope (included):**
- _Specific feature surface the user gains_
- _Specific components / modules that MUST change_

**Out of scope:**
- _Specific thing that is NOT included — be explicit to prevent scope creep_
- _Whether Dev may add tests beyond QA's acceptance tests (default: no)_

**Constraints:**
- _Existing patterns to follow (e.g. "MCP tool registration in src/tools/, use shared errorResponse")_
- _APIs or interfaces to use or avoid_
- _Things that must not break_
- _Security invariants to preserve (path traversal, write protection, etc.)_

**Acceptance criteria:**
- [ ] _Concrete, testable, observable criterion_
- [ ] _Concrete, testable, observable criterion_
- [ ] _Concrete, testable, observable criterion_

_Each criterion should be something QA can write a test for. "Returns 404 when resource does not exist" is testable; "Works correctly" is not._

**Model hint:** `sonnet` — _one-sentence reason._

_Syntax: `<tier>[<effort>]` — tier is `haiku | sonnet | opus`; optional bracket is effort `low | medium | high | xhigh | max`. Examples: `sonnet`, `sonnet[high]`, `opus[xhigh]`. Effort defaults to the harness default when the bracket is omitted._

_Tier options (guidance, not binding):_
- _`haiku` — clean, contained surface; mechanical glue code; no subtle invariants_
- _`sonnet` — normal feature work; multiple files; moderate judgment required_
- _`opus` — novel design; deep domain entanglement; architecture-shifting_

_Effort options (optional; affects reasoning depth and latency):_
- _`low | medium` — short, scoped tasks; cost-sensitive workloads_
- _`high` — default for intelligence-sensitive coding (recommended minimum for feature work)_
- _`xhigh` — best setting for most coding and agentic use cases_
- _`max` — intelligence-demanding tasks; risk of overthinking_

_Guardrail: if the change touches any of **concurrency, migrations, auth, cryptography, parser edge cases, filesystem race conditions**, the orchestrator raises to Sonnet minimum regardless of this hint._
