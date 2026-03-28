# Design Rationale — HomeBase

## Intent

**Who**: A homeowner, 30-55. Standing in their garage on Saturday morning with coffee. Just noticed the HVAC hasn't been serviced. Wondering if that dishwasher warranty expired. Five minutes, in and out. They want to feel like they have their house under control.

**What must they accomplish**: Triage. Scan what needs attention. Log that they did the thing. Occasionally look up a warranty or see if it's time to budget for a new roof.

**How should it feel**: Like a well-organized workshop pegboard. Everything has its place. You can see at a glance what's where, what's missing, what needs attention. Not sterile. Not playful. Grounded, sturdy, trustworthy — like a good toolbox when you open it.

## Domain Exploration

### Domain Concepts
1. **The workshop** — pegboards, labeled drawers, hand tools hanging in order
2. **The maintenance log** — spiral-bound notebook by the furnace with dates and notes in pencil
3. **The appliance label** — stamped metal plates, serial numbers, manufacturing dates
4. **The seasonal rhythm** — spring cleaning, winterizing, fall gutter clearing
5. **The home inspector's clipboard** — checklists, condition ratings, room-by-room walkthroughs
6. **The warranty card** — thick card stock in a drawer, expiry dates circled in pen
7. **The hardware store** — aisle markers, part numbers, bins of screws and washers

### Color World
1. **Workshop wood** — warm honey oak of a workbench (#B8956A)
2. **Toolbox red** — deep, slightly dusty red of a Craftsman toolbox (#C54B3C)
3. **Concrete gray** — garage floor, foundation walls (#8B8D8F)
4. **Furnace amber** — warm glow of a pilot light, warning labels (#D4913D)
5. **Blueprint slate** — blue-gray of technical drawings (#5B7B94)
6. **Garden sage** — muted green of weathered copper, garden hose (#7A9E7E)
7. **Duct silver** — HVAC ductwork, brushed metal (#A8B0B8)

### Signature Element
**The maintenance timeline strip** — a horizontal strip on asset cards and detail pages showing the asset's life as a physical timeline. Purchase on the left, expected end-of-life on the right, maintenance events as notches. Fills with a gradient (sage → amber → red) showing lifecycle progress. This could only exist for a lifecycle tracker.

### Defaults to Reject
1. **Card grid dashboard with icon-number-label metrics** → Replace with task-first stacked-section layout. Dashboard leads with actionable items, not vanity metrics.
2. **Generic sans-serif (Inter/system-ui) everywhere** → Use DM Sans (condensed industrial headings) + Inter (body) + JetBrains Mono (data — serial numbers, dates, costs)
3. **Pure white cards on gray background** → Warm stone surfaces with border-only depth (no shadows). Cards sit flat on the bench, differentiated by background, not elevation.

## Direction: Workshop Ledger

Warm stone surfaces. Condensed industrial type for structure. Monospace for data. Timeline strip signature on every asset. Toolbox red for overdue, furnace amber for upcoming, garden sage for healthy. Blueprint slate anchors navigation. No shadows — borders only, low-opacity. Inputs are inset (darker). Medium density — not cramped, not wasteful.

## Token Architecture

```
--bench: #F5F0EA           /* warm stone base */
--bench-raised: #FAF7F3    /* card surface */
--bench-inset: #EDE7DF     /* input backgrounds */
--bench-deep: #E3DBD1      /* sidebar, separation */
--ink-primary: #2C2824     /* workshop charcoal */
--ink-secondary: #6B6560   /* pencil gray */
--ink-tertiary: #9B9590    /* faded notes */
--ink-muted: #C5BFB8       /* disabled, placeholder */
--rule: rgba(44,40,36,0.08)       /* standard border */
--rule-soft: rgba(44,40,36,0.04)  /* whisper border */
--rule-emphasis: rgba(44,40,36,0.15) /* section dividers */
--rule-focus: #5B7B94              /* focus rings */
--alert-overdue: #C54B3C   /* toolbox red */
--alert-upcoming: #D4913D  /* furnace amber */
--status-healthy: #7A9E7E  /* garden sage */
--accent-primary: #5B7B94  /* blueprint slate */
```
