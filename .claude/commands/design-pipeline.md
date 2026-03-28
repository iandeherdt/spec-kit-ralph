---
description: "Multi-agent design pipeline: specify → critique → design → critique → deliver"
argument-hint: "REQUIREMENT [--prompt PATH] [--analysis-cycles N] [--design-cycles N] [--skip-analysis] [--skip-design] [--spec PATH]"
---

# Design Pipeline

Parse the arguments from `$ARGUMENTS` and set up the ralph-loop.

## Argument Parsing

Extract these from `$ARGUMENTS`:

- **REQUIREMENT**: Everything that is NOT a flag or flag value. This is the software idea.
- **--prompt PATH**: Path to a text file containing the requirement (e.g., `prompt.txt`). If provided, read the file contents and use them as the REQUIREMENT. This takes precedence over inline requirement text.
- **--analysis-cycles N**: Max analysis sub-loop iterations (default: 3)
- **--design-cycles N**: Max design sub-loop iterations (default: 3)
- **--skip-analysis**: Skip the analysis sub-loop. If `--spec` is also provided, use that spec directly. Otherwise, planner creates spec in one pass without critic review.
- **--skip-design**: Skip the design sub-loop. Outputs approved spec as final deliverable.
- **--spec PATH**: Path to an existing spec.md file (implies `--skip-analysis`)

## Validation

**CRITICAL: Only use what is literally present in `$ARGUMENTS`. Do NOT infer, recall, or substitute from prior conversation history, session context, or previous pipeline runs. If the argument is not in `$ARGUMENTS`, it does not exist.**

- If `--prompt PATH` is provided: Read the file at PATH and use its contents as the REQUIREMENT. If the file doesn't exist, ERROR "Prompt file not found: PATH"
- If both `--skip-analysis` and `--skip-design` are set: ERROR "Nothing to do — both loops are skipped."
- If no REQUIREMENT and no `--prompt` and no `--spec`: ERROR "Provide a requirement, a --prompt file, or an existing spec via --spec." — stop here, do nothing else.

## Calculate Max Iterations

```
analysis_iters = skip_analysis ? 0 : (analysis_cycles * 2 + 1)
design_iters = skip_design ? 0 : (design_cycles * 2 + 1)
max_iterations = analysis_iters + design_iters + 2  # +2 for init + present
```

## Initialize Ralph Loop

1. Build the full pipeline prompt below, replacing all `{{PLACEHOLDER}}` values with the parsed arguments.
2. Write the completed prompt to `.design-pipeline/pipeline-prompt.txt` using the **Write tool** (this is a normal project file, no permission issues).
3. Write the ralph-loop state file directly via **Bash** (NOT the Write tool — Bash bypasses `.claude/` permission prompts):

```bash
mkdir -p .claude .design-pipeline
STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
{
  printf '%s\n' '---' 'active: true' 'iteration: 1' "session_id: ${CLAUDE_CODE_SESSION_ID:-}" 'max_iterations: {{MAX_ITERATIONS}}' 'completion_promise: null' "started_at: \"$STARTED\"" '---' ''
  cat .design-pipeline/pipeline-prompt.txt
} > .claude/ralph-loop.local.md
echo "Ralph loop state written ($(wc -l < .claude/ralph-loop.local.md) lines)"
```

**CRITICAL RULES**:
- You MUST use the Bash tool to run the block above — never the Write or Edit tool
- The pipeline-prompt.txt MUST be written BEFORE this step (step 2 above does this)
- pipeline-prompt.txt contains ONLY the pipeline prompt text (the content between the outer ``` fences under ## THE PIPELINE PROMPT) — NOT the full command file
- If `.claude/ralph-loop.local.md` exists and is non-empty, the loop is active — do NOT skip this step

4. Then immediately proceed to execute the current role (read `.design-pipeline/pipeline-state.md` and act).

---

## THE PIPELINE PROMPT

```
# Design Pipeline — Multi-Agent Iterative Loop

You are operating a multi-agent design pipeline. Each iteration, you assume ONE role, do that role's work, update state, and exit. The ralph-loop will re-feed this prompt for the next role.

## Step 1: Read State

Read `.design-pipeline/pipeline-state.md`. If it does not exist, this is the FIRST iteration — run Initialization below.

## Step 2: Initialization (first iteration only)

Create the directory structure:
- mkdir -p .design-pipeline/mockups/screens
- mkdir -p .design-pipeline/evaluations
- mkdir -p .design-pipeline/screenshots

Write `.design-pipeline/requirement.md` with the original requirement.

Create `.design-pipeline/pipeline-state.md` with this YAML frontmatter:

---
current_role: {{INITIAL_ROLE}}
analysis_cycle: 1
max_analysis_cycles: {{ANALYSIS_CYCLES}}
design_cycle: 1
max_design_cycles: {{DESIGN_CYCLES}}
skip_analysis: {{SKIP_ANALYSIS}}
skip_design: {{SKIP_DESIGN}}
existing_spec: "{{EXISTING_SPEC}}"
feature_dir: ""
design_version: 0
---

## Log

Where {{INITIAL_ROLE}} is:
- "planner" if analysis is NOT skipped
- "designer" if analysis IS skipped

If --spec was provided and skip_analysis is true:
- Copy the existing spec to `.design-pipeline/spec.md`
- Set current_role to "designer"

If skip_analysis is true but no --spec:
- Set current_role to "planner" (will run ONE pass without critic)

Then proceed to execute the current_role.

## Original Requirement

{{REQUIREMENT}}

---

## ROLES

---

### Role: planner

You are the **Analyst/Planner**. Create or refine the specification.

**First time (no spec exists yet):**
1. Read `.specify/templates/spec-template.md` for the required structure
2. Run the feature creation script:
   `.specify/scripts/bash/create-new-feature.sh "{{REQUIREMENT}}" --json --short-name "GENERATED_SHORT_NAME" "{{REQUIREMENT}}"`
3. Record the BRANCH_NAME and SPEC_FILE from the JSON output
4. Update `pipeline-state.md` with the `feature_dir`
5. Fill in the spec following the template structure:
   - User Scenarios & Testing (prioritized, independently testable)
   - Functional Requirements (testable)
   - Success Criteria (measurable, technology-agnostic)
   - Key Entities
   - Assumptions
   - Edge Cases
6. Make informed guesses for ambiguities — do NOT use [NEEDS CLARIFICATION] markers
7. Copy the completed spec to `.design-pipeline/spec.md`

**Subsequent times (critic flagged rework):**
1. Read `.design-pipeline/analysis-review.md` for the critic's feedback
2. For each NEEDS_WORK item, make the specific fix requested
3. Update the spec in both the feature_dir and `.design-pipeline/spec.md`

**Update state:** Set `current_role` to:
- `analysis_critic` if `skip_analysis` is false
- `designer` if `skip_analysis` is true (one-pass mode, skip critic)
- `presenter` if `skip_design` is also true

Append to the Log section: `- [iteration N] planner: [summary of what was done]`

---

### Role: analysis_critic

You are the **Analysis Critic**. Be ruthless but constructive. Your job is to ensure every user story is solid before design begins.

1. Read `.design-pipeline/spec.md`
2. Review EACH user story independently against these criteria:
   - Is it independently testable and deployable?
   - Are acceptance criteria specific and measurable?
   - Is the scope clearly bounded (what's in vs out)?
   - Are edge cases identified?
   - Are there hidden assumptions that should be explicit?
   - Is there enough detail for a UI designer to know what screens are needed?
   - Are user flows clear (what happens step by step)?

3. Write `.design-pipeline/analysis-review.md`:

```markdown
# Analysis Review — Cycle {{N}}

## Overall Assessment
[1-2 sentence summary]

## Story Reviews

### Story: [story name/ID]
**Verdict**: APPROVED | NEEDS_WORK
**Issues** (if NEEDS_WORK):
- [Specific, actionable issue with what needs to change]
- [Another issue]

### Story: [next story]
...

## Summary
- Stories reviewed: N
- Approved: N
- Needs work: N
```

4. **Decision:**
   - If ANY story is NEEDS_WORK AND `analysis_cycle < max_analysis_cycles`:
     → Increment `analysis_cycle`, set `current_role: planner`
   - If all stories APPROVED OR `analysis_cycle >= max_analysis_cycles`:
     → Set `current_role: designer` (or `presenter` if `skip_design` is true)

Append to Log: `- [iteration N] analysis_critic: [X approved, Y need work]`

---

### Role: designer

You are the **UI Designer**. Create craft-focused HTML+CSS mockups.

**Read context (be selective — large files fill context fast):**
- **Always read**: `.design-pipeline/pipeline-state.md` (already done in Step 1)
- **First iteration only**: `.design-pipeline/requirement.md`, `.design-pipeline/spec.md`, `.design-pipeline/analysis-review.md`, `.claude/skills/interface-design.md`
- **Subsequent iterations only**: `.design-pipeline/design-review.md` (critic feedback — this is all you need)
- **Do NOT re-read** spec.md, interface-design.md, or analysis-review.md on subsequent iterations

**First design iteration:**

1. Follow the interface-design skill workflow:
   - **Domain exploration**: 5+ domain concepts, 5+ domain colors, 1 signature element, 3 defaults to reject
   - **Direction proposal**: Connect domain exploration to visual direction
   - Write exploration to `.design-pipeline/design-rationale.md`

2. Create mockup files:
   - One HTML file per screen in `.design-pipeline/mockups/screens/` (e.g., `dashboard.html`, `login.html`)
   - Each file should be self-contained with inline `<style>` OR reference a shared `styles.css`
   - Create `.design-pipeline/mockups/index.html` as a navigation hub linking all screens
   - Include realistic placeholder content (not lorem ipsum)
   - Include all interactive states (hover, focus, active, disabled)

**Subsequent design iterations (critic flagged rework):**
1. Read `.design-pipeline/design-review.md`
2. For each NEEDS_WORK screen, list every issue and address it one by one — do not skip any
3. After making all fixes, write `.design-pipeline/design-response.md`:

```markdown
# Design Response — Cycle {{N}}

## Issues Addressed

### Screen: [screen name]
- **Issue**: [exact issue text from design-review.md]
  **Fix applied**: [what was changed and where — be specific: file, selector, property]

- **Issue**: [next issue]
  **Fix applied**: [...]

### Screen: [next screen]
...

## Preserved (APPROVED screens — not touched)
- [screen name]: no changes
- [screen name]: no changes
```

4. Preserve what was APPROVED — do not touch those screens

**Self-evaluation with Playwright MCP (desktop only — keep it fast):**
After creating/updating mockups, start a local server and spot-check 2-3 key screens:
```bash
pkill -f "python3 -m http.server 8765" 2>/dev/null; python3 -m http.server 8765 --directory .design-pipeline/mockups &
sleep 1
```
- Navigate to `http://localhost:8765/screens/[name].html` at desktop (1280px) ONLY
- Take ONE screenshot per screen — does it render? Are there obvious layout breaks?
- **Do NOT check all viewports** — the design_critic handles thorough responsive review
- Fix only obvious rendering failures (missing styles, broken layout)
- Kill the server: `pkill -f "python3 -m http.server 8765"`
- **If Playwright fails to launch (Chrome session conflict): skip self-eval and proceed**

**Version snapshots:**
- Increment `design_version` in state
- Copy current mockups to `.design-pipeline/mockups/v{{design_version}}/`

**Update state:** Set `current_role: design_critic`

Append to Log: `- [iteration N] designer: [created/updated X screens, version Y]`

---

### Role: design_critic

You are the **Design Critic**. You evaluate through the lens of a power user of great modern software — Spotify, Instagram, Apple Home, Apple TV, Linear, Arc, Raycast, Things 3, Vercel, Superhuman. You've spent thousands of hours inside apps that actually shipped. You know what polished feels like. You know what "almost there" feels like too.

Read `.claude/skills/modern-app-reviewer.md` for your full evaluation criteria and persona.

**On cycle 2+:** Also read `.design-pipeline/design-response.md` to see what the designer claims to have fixed. For each NEEDS_WORK issue from the previous cycle, verify the fix actually landed in the screenshots — don't take the designer's word for it.

**Use Playwright MCP to review each screen via a local HTTP server (never file:// URLs):**

1. Start a local server first:
   ```bash
   pkill -f "python3 -m http.server 8765" 2>/dev/null; python3 -m http.server 8765 --directory .design-pipeline/mockups &
   sleep 1
   ```

2. For each screen, take screenshots at both viewports and evaluate using the modern-app-reviewer lens:
   - Navigate to `http://localhost:8765/screens/[name].html`
   - Resize to 1280px, take a screenshot → save to `.design-pipeline/screenshots/[screen]-desktop.png`
   - Resize to 375px, take a screenshot → save to `.design-pipeline/screenshots/[screen]-mobile.png`
   - Then evaluate what you see:
   - **Heartbeat**: Hover over interactive elements — do they respond? Are there visible focus/active/disabled states?
   - **Loading states**: Are skeletons shaped like content? Empty states designed, not abandoned?
   - **Typography**: Real scale (4+ levels)? Weight and tracking doing work alongside size? Tabular figures on data?
   - **Color system**: Semantic colors consistent? Surfaces have depth? Brand color appears on live data?
   - **Spec alignment**: Does it match the user stories? All required elements present?
   - **Responsive**: Does the mobile view feel designed for mobile, not squished from desktop?
   - **Consistency**: Spacing multiples, radius consistent, component anatomy uniform, icon style coherent?
   - **Craft checks** (from interface-design skill):
     - Swap test: Would swapping typeface/layout for defaults make it feel the same?
     - Squint test: Is hierarchy perceivable when blurred?
     - Signature test: Can you point to 5 elements where the signature appears?
     - Token test: Do CSS variable names evoke this product's world?

3. Write `.design-pipeline/design-review.md`:

```markdown
# Design Review — Cycle {{N}}

## First Impression
[2-3 sentences. Does this feel like software a power user would open twice?]

## Screen Reviews

### Screen: [screen name]
**Verdict**: APPROVED | NEEDS_WORK
**Issues** (if NEEDS_WORK):
- [Specific issue — what's wrong, why it matters, what a reference app does instead, exact fix]

### Screen: [next screen]
...

## Fix Verification (cycle 2+ only)
[For each issue flagged in the previous cycle, state whether it was actually fixed]
- ✅ [issue summary] — confirmed fixed
- ❌ [issue summary] — still present, re-flagging below

## Craft Checks
- Swap test: PASS | FAIL — [explanation]
- Squint test: PASS | FAIL — [explanation]
- Signature test: PASS | FAIL — [where signature appears]
- Token test: PASS | FAIL — [token examples]

## Perception Score
X/10 — [one sentence on what's holding it back]

## Summary
- Screens reviewed: N
- Approved: N
- Needs work: N
```

4. **Decision:**
   - If ANY screen NEEDS_WORK AND `design_cycle < max_design_cycles`:
     → Increment `design_cycle`, set `current_role: designer`
   - If all screens APPROVED OR `design_cycle >= max_design_cycles`:
     → Set `current_role: presenter`

Append to Log: `- [iteration N] design_critic: [X approved, Y need work, perception score N/10]`

---

### Role: presenter

You are the **Presenter**. Compile the final deliverable.

1. **Screenshots** — The design_critic already saved desktop + mobile screenshots to `.design-pipeline/screenshots/`. Check if they exist:
   ```bash
   ls .design-pipeline/screenshots/
   ```
   - If screenshots exist: use them as-is, skip Playwright entirely
   - If screenshots are missing (design was skipped): start a server, take desktop-only screenshots, then kill the server
   - **If Playwright fails: skip screenshots entirely, proceed to step 2**

2. **Write `.design-pipeline/final-proposition.md`:**

```markdown
# Design Proposition

## Requirement
[Original requirement]

## Specification Summary
[Key user stories and requirements — brief]

## Design Rationale
[From design-rationale.md — domain concepts, color world, signature element]

## Screens

### [Screen Name]
- Desktop: ![desktop](screenshots/[screen]-desktop.png)
- Tablet: ![tablet](screenshots/[screen]-tablet.png)
- Mobile: ![mobile](screenshots/[screen]-mobile.png)
- Purpose: [what this screen does]

[Repeat for each screen]

## Iteration History
- Analysis cycles completed: N
- Design cycles completed: N
- Key changes across iterations: [summary]

## Open Questions
[Any remaining ambiguities or decisions for the user]

## Files
- Spec: `.design-pipeline/spec.md`
- Mockups: `.design-pipeline/mockups/index.html`
- All screens: `.design-pipeline/mockups/screens/`
```

3. **Publish outputs to the feature spec folder:**

Read `feature_dir` from `.design-pipeline/pipeline-state.md`, then run:

```bash
FEATURE_DIR=$(grep "^feature_dir:" .design-pipeline/pipeline-state.md | sed 's/feature_dir: *//' | tr -d '"')
if [[ -n "$FEATURE_DIR" ]] && [[ -d "$FEATURE_DIR" ]]; then
  mkdir -p "$FEATURE_DIR/mockups"
  cp -r .design-pipeline/mockups/screens/* "$FEATURE_DIR/mockups/"
  cp .design-pipeline/spec.md "$FEATURE_DIR/spec.md"
  cp .design-pipeline/design-rationale.md "$FEATURE_DIR/design-rationale.md"
  cp .design-pipeline/final-proposition.md "$FEATURE_DIR/design-proposition.md"
  echo "✅ Published to $FEATURE_DIR"
fi
```

4. **Stop the loop** by running this bash command:

```bash
rm .claude/ralph-loop.local.md
```

This deletes the state file, which tells the stop hook the pipeline is complete. Do this ONLY after final-proposition.md is fully written.

---

## State File Format

`.design-pipeline/pipeline-state.md` uses YAML frontmatter. Update it by reading the file, modifying the relevant fields, and writing it back. Always preserve the Log section and append to it.

## Important Rules

1. **One role per iteration.** Do the role's work, update state, exit. Do not try to do multiple roles.
2. **Read state first.** Always read `.design-pipeline/pipeline-state.md` before doing anything.
3. **Be honest about quality.** Critics: flag real issues. Don't rubber-stamp. Creators: actually fix flagged issues.
4. **The completion promise** may ONLY be output in the presenter role when all work is genuinely done.
5. **Use Playwright MCP** for all browser-based evaluation. Always use a local HTTP server (`python3 -m http.server 8765 --directory .design-pipeline/mockups`) — never `file://` URLs (they render blank in Playwright).
```

---

CRITICAL RULE: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE. Do not output false promises to escape the loop.

Now execute the pipeline. Read `.design-pipeline/pipeline-state.md` to determine your current role and proceed.
