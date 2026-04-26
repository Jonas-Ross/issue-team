# Spec Template — docs

Copy this template into `<worktree>/.claude/issue-runs/issue-<issue_number>/spec.md` and fill in each section. Delete template-only guidance in italics before finalizing. Fill every section with concrete content.

Docs changes modify documentation only. Acceptance tests for docs are typically an editorial review rather than a unit test — spell that out explicitly if so.

---

## Spec: Issue #<number> — <title>

**Classification:** docs

**Goal:** _One sentence — what documentation is being added, corrected, or restructured._

**Scope (included):**
- _Specific files: README, CLAUDE.md, skill files, schema files, etc._
- _Sections to add / rewrite / delete_

**Out of scope:**
- _Source code changes (if code touches required, re-classify as feat/refactor/bugfix)_
- _Unrelated doc edits (spelling fixes elsewhere, etc.) — file separately_

**Constraints:**
- _Tone / style conventions of the surrounding docs_
- _Any protected files (e.g. CLAUDE.md is write-protected in wiki-mcp)_
- _Accuracy: claims about code behaviour must match actual code_

**Acceptance criteria:**
- [ ] _Content outcome: specific sections exist with specific claims_
- [ ] _Accuracy check: all code references / paths / commands are correct_
- [ ] _Existing links still resolve (no dangling references)_

**Model hint:** `haiku` — _docs work is usually straightforward prose under clear constraints._

_Syntax: `<tier>[<effort>]` — tier is `haiku | sonnet | opus`; optional bracket is effort `low | medium | high | xhigh | max`. Most docs edits run fine without an effort bracket; add `[high]` for docs that synthesize behaviour across modules._

_Tier options:_
- _`haiku` — default for straightforward docs edits_
- _`sonnet` — docs that require synthesizing behaviour across multiple modules; design-decision docs; architecture narratives_
- _`opus` — rare_

_Guardrail: raise to Sonnet minimum if the docs change describes **concurrency, migrations, auth, cryptography, parser edge cases, filesystem race conditions** (accurate prose in these domains requires real understanding, not pattern-matching)._
