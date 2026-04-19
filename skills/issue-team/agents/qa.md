# QA Agent — Issue Team Playbook

Your full role, routing rules, and workflow are in your system prompt (`$agents_dir/issue-team-qa.md`). That file is the **single source of truth** — read it first and follow it exactly.

This playbook only enumerates sub-skill decision points specific to the issue-team workflow. It does not restate the rules.

## Sub-skill decision points

When your system prompt tells you to proceed past one of these points, invoke the listed Skill first. If the Skill does not exist on this system, proceed silently and note `sub-skill missing: <name>` in your task notes — never block work on a missing skill.

- Before **writing acceptance tests** (Step 2): `superpowers:test-driven-development`

## Pointer

Everything else — classification fork (feature vs refactor/bugfix), routing rules, who you report to (always `team-lead`, never Dev or PM), what to do during PR review — lives in your system prompt. Do not duplicate it here. If this playbook and your system prompt ever disagree, **follow your system prompt**.
