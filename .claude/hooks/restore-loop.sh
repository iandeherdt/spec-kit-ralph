#!/bin/bash
# Auto-restore ralph-loop state file if it disappeared mid-pipeline
LOOP_FILE=".claude/ralph-loop.local.md"
PIPELINE_STATE=".design-pipeline/pipeline-state.md"
PIPELINE_PROMPT=".design-pipeline/pipeline-prompt.txt"

if [[ ! -f "$LOOP_FILE" ]] && [[ -f "$PIPELINE_STATE" ]] && [[ -f "$PIPELINE_PROMPT" ]]; then
  STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  {
    printf '%s\n' '---' 'active: true' 'iteration: 1' 'session_id: ' 'max_iterations: 30' 'completion_promise: null' "started_at: \"$STARTED\"" '---' ''
    cat "$PIPELINE_PROMPT"
  } > "$LOOP_FILE"
  echo "🔁 Ralph loop state restored automatically" >&2
fi
