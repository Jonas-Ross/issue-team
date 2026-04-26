# Changelog

## 0.3.1

- Harden `/issue-subagents` orchestration: plugin-aware skill discovery, unconditional base-branch computation, clean-worktree gating, issue-numbered worktree names, and persisted issue context before pre-flight gates.
- Add a low-risk fast path for docs, simple chores, and tightly scoped bugfix/refactor work where the orchestrator can define concrete manual acceptance checks without spawning QA test-author.
- Centralize draft PR creation in the orchestrator so Dev only implements, verifies, and pushes; the orchestrator owns PR body metadata and `Closes #<issue_number>`.
- Improve acceptance verification across review paths: QA and code-reviewer receive test/manual-check context, feature review verifies acceptance criteria, and manual-only checks use `test_command: none`.
- Tighten review-loop handling for malformed reviewer replies, low/medium-confidence findings, diff-triggered sub-gates, and zsh-safe plugin-cache lookup.

## 0.3.0

- Add `/issue-subagents` skill — sub-agent variant of `/issue-team` that uses one-shot sub-agents (via the `Agent` tool) instead of a long-lived agent team. Same git flow (worktree → spec → acceptance tests → implementation → draft PR → review → un-draft → retro), classification rules, model-tier guardrails, diff-triggered sub-gates, and spec templates as `/issue-team`. Differences: orchestrator drives every step (no peer messaging), spec lives at `${CLAUDE_PROJECT_DIR}/.claude/issue-runs/issue-<n>/spec.md` (gitignored), no `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` flag required, no completion-gate hook (orchestrator runs `gh pr ready` itself after review).
- Ship four dedicated subagent definitions at repo root: `agents/issue-subagents-{pm,dev,qa,code-reviewer}.md`, with full system prompts as the role playbook (mirrors the existing `agents/issue-team-*.md` pattern).
- Duplicate (intentional) `reference/{worktree-setup,preflight-gates,model-guardrails}.md` and `templates/*.md` between the two skills so each is self-contained; `reference/retrospective.md` adapted for the no-`TeamDelete` flow.
- Update `README.md` and `.claude-plugin/{plugin,marketplace}.json` to introduce both skills as a pair with a "when to pick" table.
- Audit pass against Anthropic skill + sub-agent best practices folded in before first release: drop invalid `effort:` parameter from Agent spawns (effort communicated as a "Reasoning effort target:" prompt-body line); persist issue body and comments to disk so spawn prompts reference paths instead of inlining megabytes of text; switch from 3-class to 5-class model (feature, refactor, bugfix, chore, docs) with a separate roster axis (PM-led vs orchestrator-led); split `<issue_number>` and `<pr_number>` placeholders; pin acceptance-test paths return contract; document soft-dep `superpowers:*` skills in SKILL.md; copy-edit reference/ and templates/ from team-variant terminology (coordinator/TeamCreate/TeamDelete) to orchestrator-led wording; add empty-guard for `skill_dir` lookup; move `.gitignore` hardening out of Step 2.5 so it runs on every invocation.

## 0.2.0

- Align prompts with Opus 4.7 / Claude prompt-engineering best practices.
- Soften aggressive imperatives (MUST/NEVER/REQUIRED) and convert negative routing rules to positive form across all agent prompts, templates, and `SKILL.md`.
- Remove forced `[pulse]` progress scaffolding in favour of native Opus 4.7 progress updates.
- Add rationale for the single-gate coordinator rule at every enforcement site.
- Wrap distinct content types in XML tags (`<routing_rules>`, `<phase_updates>`, `<message_template>`, etc.) in every role prompt.
- Add `<use_parallel_tool_calls>` and `<investigate_before_answering>` snippets at the right surfaces.
- Replace code-reviewer's qualitative Pass/Changes verdict with a `[severity][confidence]`-tagged findings schema; coordinator filters downstream, reviewer maximizes recall.
- Extend `Model hint` template syntax to `<tier>[<effort>]` so specs can pass an Opus-4.7 effort dial (e.g. `sonnet[high]`).
- Extract `SKILL.md` sections (worktree setup, pre-flight gates, model guardrails, retrospective) into `skills/issue-team/reference/` for progressive disclosure; `SKILL.md` drops from 570 to 435 lines.
- Consolidate role definitions: delete the pointer-stub playbooks at `skills/issue-team/agents/{dev,pm,qa}.md`; each role's system prompt in `agents/issue-team-*.md` is now the single source of truth. `code-reviewer.md` stays in the skill directory because it backs the externally-spawned `superpowers:code-reviewer` subagent.

## 0.1.0

- Initial plugin scaffold extracted from wiki-mcp.
