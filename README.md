# issue-team

Claude Code plugin that drives a GitHub issue from triage to merged PR. Ships **two skills** that share the same git flow (worktree → spec → acceptance tests → implementation → draft PR → review → un-draft → retro) but differ in how they parallelize the work:

| Skill | Concurrency model | When to pick it |
|---|---|---|
| `/issue-team` | Persistent agent team (`TeamCreate` + `SendMessage` peer messaging, single coordinator gate) | Long-running work where parallel agent state matters; you have `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set |
| `/issue-subagents` | One-shot sub-agents (`Agent` tool, orchestrator-driven) | Standard runs; no experimental flag required; simpler to reason about |

Both skills use the same classification rules (`feat:` / `fix:` / `refactor:` / `chore:` / `docs:`), the same model-tier guardrails, the same diff-triggered sub-gates, and the same spec templates.

## Install

Add this repo as a marketplace, then install the plugin:

```
/plugin marketplace add https://github.com/Jonas-Ross/issue-team
/plugin install issue-team
```

`/issue-team` (the team-based skill) requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set in your environment (shell or the "Environment variables" UI of cloud sessions). Without it, `team_name` and inter-agent `SendMessage` are unavailable. The flag is experimental, so the plugin does not try to set it for you. `/issue-subagents` does not need this flag — it only uses the standard `Agent` tool.

## Use

Start a Claude Code session in your repo and invoke either skill:

```
/issue-team        # team-based variant
/issue-subagents   # sub-agent variant
```

Either entry point lists open issues, asks which to implement, classifies by title prefix, creates a worktree if you launched from `main`, and runs the workflow.

## Contents

**Team variant (`/issue-team`):**
- `skills/issue-team/SKILL.md` — orchestration workflow for the coordinator
- `skills/issue-team/agents/code-reviewer.md` — role prompt for the externally-spawned `superpowers:code-reviewer` subagent (feature only)
- `skills/issue-team/reference/*.md` — worktree setup, pre-flight gates, model guardrails, retrospective
- `skills/issue-team/hooks/gate-task-completion.sh` — task-completion gate enforcing review-approved phase
- `skills/issue-team/templates/*.md` — spec skeletons (feat, fix, refactor, chore, docs)
- `agents/issue-team-{dev,pm,qa}.md` — Claude Code subagent definitions spawned as `subagent_type: "issue-team-*"`

**Sub-agent variant (`/issue-subagents`):**
- `skills/issue-subagents/SKILL.md` — orchestration workflow (orchestrator-driven, no peer messaging)
- `agents/issue-subagents-{pm,dev,qa,code-reviewer}.md` — Claude Code subagent definitions spawned as `subagent_type: "issue-subagents-*"`
- `skills/issue-subagents/reference/*.md` — same reference material, retrospective adapted for the no-`TeamDelete` flow
- `skills/issue-subagents/templates/*.md` — same spec skeletons

## Per-repo overrides

Projects can ship their own spec templates at `.claude/spec-templates/<class>.md` in the target repo; both skills' template-lookup order picks the repo-local copy first, then falls back to the plugin's default.
