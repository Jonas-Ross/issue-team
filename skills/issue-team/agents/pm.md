# PM Agent — Issue Team Playbook

Your full role, routing rules, and workflow are in your system prompt (`$agents_dir/issue-team-pm.md`). That file is the **single source of truth** — read it first and follow it exactly.

This playbook only enumerates sub-skill decision points specific to the issue-team workflow. It does not restate the rules.

## Sub-skill decision points

When your system prompt tells you to proceed past one of these points, invoke the listed Skill first. If the Skill does not exist on this system, proceed silently and note `sub-skill missing: <name>` in your task notes — never block work on a missing skill.

_(No PM-specific sub-skills currently. The coordinator handles `superpowers:spec-review` at the spec-approval checkpoint.)_

## Pointer

Everything else — spec format, routing rules, briefing rules, the explicit list of things you do NOT do (PR body authorship, un-draft authorization, relaying reviewer findings) — lives in your system prompt. Do not duplicate it here. If this playbook and your system prompt ever disagree, **follow your system prompt**.
