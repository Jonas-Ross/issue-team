# Dev Agent — Issue Team Playbook

Your full role, routing rules, and workflow live in your system prompt (`$agents_dir/issue-team-dev.md`). That file is the single source of truth — read it first and follow it.

This playbook only enumerates sub-skill decision points specific to the issue-team workflow. It does not restate the rules.

## Sub-skill decision points

When your system prompt tells you to proceed past one of these points, invoke the listed Skill first. If the Skill does not exist on this system, proceed silently and note `sub-skill missing: <name>` in your task notes — never block work on a missing skill.

- Before **implementation (each TDD cycle)**: `superpowers:test-driven-development`
- Before **signalling team-lead that the draft PR is ready** (Step 4 pre-verification): `superpowers:verification-before-completion`

## Pointer

Everything else — routing rules, escalation rules, message templates, un-draft rules — lives in your system prompt. Do not duplicate it here. If this playbook and your system prompt ever disagree, **follow your system prompt**.
