---
description: "Multi-agent design pipeline: specify → critique → design → critique → code → critique → deliver"
argument-hint: "REQUIREMENT [--prompt PATH] [--analysis-cycles N] [--design-cycles N] [--dev-cycles N] [--skip-analysis] [--skip-design] [--skip-dev] [--spec PATH]"
---

# Design Pipeline

Parse `$ARGUMENTS`, write a small values file, then let bash generate `pipeline-prompt.txt` from the static template. You never copy or rewrite the prompt — Python does that.

## Argument Parsing

Extract these from `$ARGUMENTS`:

- **REQUIREMENT**: Everything that is NOT a flag or flag value. This is the software idea.
- **--prompt PATH**: Path to a text file containing the requirement. If provided, read the file and use its contents as the REQUIREMENT.
- **--analysis-cycles N**: Max analysis sub-loop iterations (default: 3)
- **--design-cycles N**: Max design sub-loop iterations (default: 3)
- **--dev-cycles N**: Max dev sub-loop iterations (default: 3)
- **--skip-analysis**: Skip the analysis sub-loop.
- **--skip-design**: Skip the design sub-loop.
- **--skip-dev**: Skip the development sub-loop.
- **--spec PATH**: Path to an existing spec.md file (implies `--skip-analysis`)

## Validation

**CRITICAL: Only use what is literally present in `$ARGUMENTS`. Do NOT infer, recall, or substitute from prior conversation history.**

- If `--prompt PATH` is provided: read the file and use its contents as REQUIREMENT. ERROR if file not found.
- If `--skip-analysis`, `--skip-design`, and `--skip-dev` are ALL set: ERROR "Nothing to do — all loops are skipped."
- If no REQUIREMENT and no `--prompt` and no `--spec`: ERROR "Provide a requirement, a --prompt file, or an existing spec via --spec." — stop here.

## Calculate Values

```
analysis_cycles = N from --analysis-cycles, default 3
design_cycles   = N from --design-cycles, default 3
dev_cycles      = N from --dev-cycles, default 3
skip_analysis   = true if --skip-analysis or --spec provided, else false
skip_design     = true if --skip-design, else false
skip_dev        = true if --skip-dev, else false
existing_spec   = PATH from --spec, else ""

analysis_iters = skip_analysis ? 0 : (analysis_cycles * 2 + 1)
design_iters   = skip_design   ? 0 : (design_cycles   * 2 + 1)
dev_iters      = skip_dev      ? 0 : (dev_cycles      * 2 + 1)
max_iterations = analysis_iters + design_iters + dev_iters + 2

initial_role:
  - "planner"   if analysis NOT skipped
  - "designer"  if analysis skipped, design NOT skipped
  - "developer" if analysis AND design both skipped, dev NOT skipped
  - "presenter" if all skipped (blocked by validation above)
```

## Initialize the Pipeline

**Step 1** — Write `.design-pipeline/pipeline-values.json` using the Write tool. This is the ONLY thing you write — a small JSON file with the parsed values. Use actual values from `$ARGUMENTS`, not placeholders:

```json
{
  "REQUIREMENT": "<actual requirement text>",
  "ANALYSIS_CYCLES": "<number>",
  "DESIGN_CYCLES": "<number>",
  "DEV_CYCLES": "<number>",
  "SKIP_ANALYSIS": "<true or false>",
  "SKIP_DESIGN": "<true or false>",
  "SKIP_DEV": "<true or false>",
  "EXISTING_SPEC": "<path or empty string>",
  "INITIAL_ROLE": "<role name>",
  "MAX_ITERATIONS": "<number>"
}
```

**Step 2** — Run this bash block (use the Bash tool — do NOT use Write or Edit):

```bash
mkdir -p .claude .design-pipeline

# Substitute template placeholders using the values JSON
python3 - << 'PYEOF'
import json, sys

values = json.load(open('.design-pipeline/pipeline-values.json'))
template = open('.claude/pipeline-prompt-template.md').read()

result = template
for key, val in values.items():
    result = result.replace('{{' + key + '}}', str(val))

with open('.design-pipeline/pipeline-prompt.txt', 'w') as f:
    f.write(result)

lines = len(result.splitlines())
print(f'pipeline-prompt.txt written ({lines} lines)')
if lines < 200:
    print('WARNING: prompt looks too short — check pipeline-prompt-template.md exists')
    sys.exit(1)
PYEOF

# Write the ralph-loop state file
STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MAX_ITER=$(python3 -c "import json; print(json.load(open('.design-pipeline/pipeline-values.json'))['MAX_ITERATIONS'])")
{
  printf '%s\n' '---' 'active: true' 'iteration: 1' \
    "session_id: ${CLAUDE_CODE_SESSION_ID:-}" \
    "max_iterations: $MAX_ITER" \
    'completion_promise: null' \
    "started_at: \"$STARTED\"" \
    '---' ''
  cat .design-pipeline/pipeline-prompt.txt
} > .claude/ralph-loop.local.md

echo "Ralph loop state written ($(wc -l < .claude/ralph-loop.local.md) lines)"
```

**Step 3** — Then immediately read `.design-pipeline/pipeline-state.md` and execute the current role.

---

CRITICAL RULE: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE. Do not output false promises to escape the loop.

Now execute the pipeline. Read `.design-pipeline/pipeline-state.md` to determine your current role and proceed.
