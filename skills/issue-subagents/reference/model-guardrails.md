# Model-tier guardrails (reference)

Loaded by SKILL.md Step 5. The `Model hint:` line in the approved spec picks the default dev/QA tier. This reference lists the domains where Haiku is unsafe even when the spec looks mechanical.

## Force Sonnet minimum when the spec touches any of

- **concurrency** — threads, async race windows, locks, channels
- **migrations** — schema changes, data backfills, irreversible transformations
- **auth** — authentication, authorization, session, token handling
- **cryptography** — hashing, signing, encryption, key handling
- **parser edge cases** — hand-rolled parsers, tokenizers, escape handling
- **filesystem race conditions** — TOCTOU, concurrent writers, lockfile logic

## Rule

- If the hint is `haiku` but the spec touches any of the above, **raise to `sonnet`** and note the override.
- If the hint is `sonnet` or `opus`, the guardrail does not downgrade.

Record the tier decision (hint value, final value, override reason if any) — the retro in Step 10 surfaces it.

## Why these domains

Each domain rewards deliberate reasoning over pattern-matching. A `haiku`-speed change in any of them tends to mis-land subtle invariants — a session check that looks right but timing-leaks, a migration that appears reversible but isn't under load, a lockfile that races only at scale. Sonnet-minimum is the baseline where the model can hold the invariants in its head through the whole diff.
