---
description: "Multi-agent design pipeline: specify → critique → design → critique → deliver"
argument-hint: "REQUIREMENT [--prompt PATH] [--analysis-cycles N] [--design-cycles N] [--skip-analysis] [--skip-design] [--spec PATH]"
allowed-tools: ["Bash(setup-ralph-loop:*)"]
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

- If `--prompt PATH` is provided: Read the file at PATH and use its contents as the REQUIREMENT. If the file doesn't exist, ERROR "Prompt file not found: PATH"
- If both `--skip-analysis` and `--skip-design` are set: ERROR "Nothing to do — both loops are skipped."
- If no REQUIREMENT and no `--prompt` and no `--spec`: ERROR "Provide a requirement, a --prompt file, or an existing spec via --spec."

## Calculate Max Iterations

```
analysis_iters = skip_analysis ? 0 : (analysis_cycles * 2 + 1)
design_iters = skip_design ? 0 : (design_cycles * 2 + 1)
max_iterations = analysis_iters + design_iters + 2  # +2 for init + present
```

## Initialize Ralph Loop

Build the prompt below, replacing `{{REQUIREMENT}}`, `{{ANALYSIS_CYCLES}}`, `{{DESIGN_CYCLES}}`, `{{SKIP_ANALYSIS}}`, `{{SKIP_DESIGN}}`, and `{{EXISTING_SPEC}}` with the parsed values.

Then execute:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-loop.sh" "DESIGN_PIPELINE_PROMPT" --max-iterations {{MAX_ITERATIONS}} --completion-promise "DESIGN COMPLETE"
```

Where `DESIGN_PIPELINE_PROMPT` is the full prompt text below with all placeholders resolved.

---

## THE PIPELINE PROMPT

```
# Design Pipeline — Multi-Agent Iterative Loop

You are operating a multi-agent design pipeline. Each iteration, you assume ONE role, do that role's work, update state, and exit. The ralph-loop will re-feed this prompt for the next role.

## Step 1: Read State

Read `.claude/pipeline-state.md`. If it does not exist, this is the FIRST iteration — run Initialization below.

## Step 2: Initialization (first iteration only)

Create the directory structure:
- mkdir -p .design-pipeline/mockups/screens
- mkdir -p .design-pipeline/evaluations
- mkdir -p .design-pipeline/screenshots

Write `.design-pipeline/requirement.md` with the original requirement.

Create `.claude/pipeline-state.md` with this YAML frontmatter:

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

**Read context:**
- `.design-pipeline/requirement.md`
- `.design-pipeline/spec.md`
- `.design-pipeline/analysis-review.md` (if exists)
- `.design-pipeline/design-review.md` (if exists — previous critic feedback)
- `.claude/skills/interface-design.md` — Read this file and follow its workflow

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
1. Read `.design-pipeline/design-review.md` for specific issues
2. Fix each NEEDS_WORK item
3. Preserve what was APPROVED

**Self-evaluation with Playwright MCP:**
After creating/updating mockups, use the Playwright MCP tools to check your own work:
- Navigate to each screen file (use file:// URLs or start a local server)
- Take a screenshot — does it look right?
- Check responsive behavior at different viewport sizes
- Fix any issues you find BEFORE handing off to the design critic

**Version snapshots:**
- Increment `design_version` in state
- Copy current mockups to `.design-pipeline/mockups/v{{design_version}}/`

**Update state:** Set `current_role: design_critic`

Append to Log: `- [iteration N] designer: [created/updated X screens, version Y]`

---

### Role: design_critic

You are the **Design Critic**. Be demanding about visual quality and spec alignment.

**Use Playwright MCP to review each screen:**

1. Navigate to each HTML file in `.design-pipeline/mockups/screens/`
2. For each screen, evaluate:
   - **Spec alignment**: Does it match the user stories? Are all required elements present?
   - **Visual hierarchy**: Is the most important content prominent? Can you scan it quickly?
   - **Consistency**: Same spacing scale, typography, colors throughout?
   - **Interactive elements**: Are buttons, links, inputs obvious and consistent?
   - **Responsive**: Check at desktop (1280px), tablet (768px), mobile (375px)
   - **Craft checks** (from interface-design skill):
     - Swap test: Would swapping typeface/layout for defaults make it feel the same?
     - Squint test: Is hierarchy perceivable when blurred?
     - Signature test: Can you point to 5 elements where the signature appears?
     - Token test: Do CSS variable names evoke this product's world?

3. Write `.design-pipeline/design-review.md`:

```markdown
# Design Review — Cycle {{N}}

## Overall Assessment
[1-2 sentence summary of design quality]

## Screen Reviews

### Screen: [screen name]
**Verdict**: APPROVED | NEEDS_WORK
**Issues** (if NEEDS_WORK):
- [Specific visual/UX issue with concrete fix suggestion]
- [Another issue]

### Screen: [next screen]
...

## Craft Checks
- Swap test: PASS | FAIL — [explanation]
- Squint test: PASS | FAIL — [explanation]
- Signature test: PASS | FAIL — [where signature appears]
- Token test: PASS | FAIL — [token examples]

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

Append to Log: `- [iteration N] design_critic: [X approved, Y need work]`

---

### Role: presenter

You are the **Presenter**. Compile the final deliverable.

1. **Take final screenshots** using Playwright MCP:
   - For each screen: desktop (1280px), tablet (768px), mobile (375px)
   - Save to `.design-pipeline/screenshots/[screen]-[viewport].png`
   - For each user story: capture the key interaction/screen
   - Save to `.design-pipeline/screenshots/story-[id].png`

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

3. **Output the completion promise:**

<promise>DESIGN COMPLETE</promise>

---

## State File Format

`.claude/pipeline-state.md` uses YAML frontmatter. Update it by reading the file, modifying the relevant fields, and writing it back. Always preserve the Log section and append to it.

## Important Rules

1. **One role per iteration.** Do the role's work, update state, exit. Do not try to do multiple roles.
2. **Read state first.** Always read `.claude/pipeline-state.md` before doing anything.
3. **Be honest about quality.** Critics: flag real issues. Don't rubber-stamp. Creators: actually fix flagged issues.
4. **The completion promise** may ONLY be output in the presenter role when all work is genuinely done.
5. **Use Playwright MCP** for all browser-based evaluation. Navigate to file:// URLs or start a local HTTP server.
```

---

CRITICAL RULE: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE. Do not output false promises to escape the loop.

Now execute the pipeline. Read `.claude/pipeline-state.md` to determine your current role and proceed.
