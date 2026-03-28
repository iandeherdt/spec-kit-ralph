# Design Response — Cycle 3

## Issues Addressed

### Screen: Dashboard
- **Issue**: Mobile task names still truncate at 375px — white-space:nowrap base rule wins over 480px override.
  **Fix applied**: In `styles.css` @media(max-width:480px), changed `.task-item .task-info` to `flex:1 1 100%` so it takes its own full row. Changed `.task-item .task-name` to `white-space:normal;overflow:visible;text-overflow:unset;font-size:14px`. Added explicit `order` values to status-dot (0), task-info (1), task-due (2), button (3). The task-info now gets the full width of the row, and due-date + button wrap to a second row below.

### Screen: Tasks
- **Issue**: Same mobile task-name truncation.
  **Fix applied**: Same CSS rules apply globally — the 480px breakpoint changes affect both dashboard and tasks screens.

## Preserved (APPROVED screens — not touched)
- assets.html: no changes
- asset-detail.html: no changes
- add-asset.html: no changes
- documents.html: no changes
