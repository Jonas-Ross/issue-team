# issue-team

Claude Code plugin that runs a right-sized agent team to implement a GitHub issue and deliver a PR.

Spawns a coordinator plus PM, dev, QA, and a code-reviewer (for features; smaller teams for refactor / bugfix / chore / docs) and walks them through spec → acceptance tests → implementation → review → un-draft with explicit checkpoints. The coordinator is the sole decision gate; peer-to-peer agent messaging is allowed for coordination but never for approval.

## Install

Add this repo as a marketplace, then install the plugin:

```
/plugin marketplace add https://github.com/Jonas-Ross/issue-team
/plugin install issue-team
```

One manual step is required per environment: set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in your environment (shell or the "Environment variables" UI of cloud sessions). Without it, the `team_name` parameter and inter-agent `SendMessage` are unavailable and `issue-team` won't run. This flag is experimental, so the plugin does not try to set it for you.

## Use

Start a Claude Code session in your repo and invoke the skill:

```
/issue-team
```

The coordinator lists open issues, asks which to implement, classifies by title prefix (`feat:` / `fix:` / `refactor:` / `chore:` / `docs:`), creates a worktree if you launched from `main`, and spawns the team.

## Contents

- `skills/issue-team/SKILL.md` — orchestration workflow for the coordinator
- `skills/issue-team/agents/*.md` — role prompts read by coordinator-spawned sub-agents (dev, pm, qa, code-reviewer)
- `skills/issue-team/hooks/gate-task-completion.sh` — task-completion gate enforcing review-approved phase
- `skills/issue-team/templates/*.md` — spec skeletons (feat, fix, refactor, chore, docs)
- `agents/issue-team-{dev,pm,qa}.md` — Claude Code subagent definitions spawned as `subagent_type: "issue-team-*"`

## Per-repo overrides

Projects can ship their own spec templates at `.claude/spec-templates/<class>.md` in the target repo; the skill's template-lookup order picks the repo-local copy first, then falls back to the plugin's default.
