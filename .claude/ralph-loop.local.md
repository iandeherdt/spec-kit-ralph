---
active: true
iteration: 1
session_id: 
max_iterations: 30
completion_promise: null
started_at: "2026-03-28T11:48:59Z"
---

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
current_role: planner
analysis_cycle: 1
max_analysis_cycles: 3
design_cycle: 1
max_design_cycles: 3
skip_analysis: false
skip_design: false
existing_spec: ""
feature_dir: ""
design_version: 0
---

## Log

Then proceed to execute the current_role.

## Original Requirement

Build a self-hosted Home Maintenance & Appliance Lifecycle Tracker as a full-stack web application.

## What it does
Track every appliance, device, system and asset in a home - from the fridge to the roof tiles to the car. Know when maintenance is due, when warranties expire, what things cost, and when to budget for replacements. Think of it as "fleet management for your house."

---

## ROLES

(pipeline role definitions follow — planner, analysis_critic, designer, design_critic, presenter)
