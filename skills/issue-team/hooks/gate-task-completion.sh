#!/usr/bin/env bash
# TaskCompleted hook for issue-team.
#
# Blocks completion of a task if its metadata.requires object lists
# prerequisite tasks that haven't reached the expected phase.
#
# Convention:
#   TaskUpdate metadata = { requires: { "<task_id>": "<required_phase>" } }
#
# Example: coordinator sets this on the "un-draft PR" task:
#   { requires: { "4": "review_approved" } }
# meaning task #4 must be completed with metadata.phase == "review_approved"
# before this task can be marked complete.
#
# Fires on every TaskCompleted. Tasks without metadata.requires pass through.

set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(jq -r '.session_id // empty' <<<"$INPUT")
TASK_ID=$(jq -r '.task_id // empty' <<<"$INPUT")

# No session or task id — allow (not our concern).
[[ -z "$SESSION_ID" || -z "$TASK_ID" ]] && exit 0

TASKS_DIR="$HOME/.claude/tasks/$SESSION_ID"
TASK_FILE="$TASKS_DIR/$TASK_ID.json"

# Task file not on disk — allow (can't enforce).
[[ -f "$TASK_FILE" ]] || exit 0

REQUIRES=$(jq -c '.metadata.requires // empty' "$TASK_FILE" 2>/dev/null || echo "")
[[ -z "$REQUIRES" || "$REQUIRES" == "null" ]] && exit 0

while IFS=$'\t' read -r req_id req_phase; do
    [[ -z "$req_id" ]] && continue
    REQ_FILE="$TASKS_DIR/$req_id.json"
    if [[ ! -f "$REQ_FILE" ]]; then
        echo "Gate blocked: required task #$req_id not found in session tasks. Cannot complete task #$TASK_ID." >&2
        exit 2
    fi
    STATUS=$(jq -r '.status // ""' "$REQ_FILE" 2>/dev/null)
    PHASE=$(jq -r '.metadata.phase // ""' "$REQ_FILE" 2>/dev/null)
    if [[ "$STATUS" != "completed" ]]; then
        echo "Gate blocked: required task #$req_id status is '$STATUS' (need 'completed'). Cannot complete task #$TASK_ID." >&2
        exit 2
    fi
    if [[ -n "$req_phase" && "$PHASE" != "$req_phase" ]]; then
        echo "Gate blocked: required task #$req_id phase is '$PHASE' (need '$req_phase'). Cannot complete task #$TASK_ID." >&2
        exit 2
    fi
done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' <<<"$REQUIRES")

exit 0
