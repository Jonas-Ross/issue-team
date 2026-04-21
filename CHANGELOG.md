# Changelog

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
