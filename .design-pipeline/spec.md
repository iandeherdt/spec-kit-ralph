# Feature Specification: Home Maintenance & Appliance Lifecycle Tracker

**Feature Branch**: `005-home-maintenance-tracker`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "Build a self-hosted Home Maintenance & Appliance Lifecycle Tracker as a full-stack web application."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Register and Catalog a Home Asset (Priority: P1)

As a homeowner, I want to add an appliance or asset to my tracker so I can keep a centralized inventory of everything in my home.

**Why this priority**: Without assets, no other feature works.

**Independent Test**: Add 3-5 different asset types and confirm they appear in the inventory list with correct details.

**Acceptance Scenarios**:

1. **Given** the user is on the dashboard, **When** they click "Add Asset" and fill in required fields (name, category, purchase date), **Then** the asset is saved and appears in the inventory list within 1 second.
2. **Given** the user is adding an asset, **When** they select a category, **Then** the form shows common fields plus category-specific fields as defined in the Category-Specific Fields table below.
3. **Given** an asset has been added, **When** the user views the asset detail page, **Then** they see all entered information including purchase price, warranty end date, expected lifespan, location, and any attached photos.
4. **Given** the user wants to edit an existing asset, **When** they open the asset detail and modify fields, **Then** the changes are persisted and a modification timestamp is recorded.
5. **Given** the user is creating or editing an asset, **When** they attach a photo (JPEG, PNG, max 10MB), **Then** a thumbnail preview appears in the form and the photo is persisted with the asset upon save.
6. **Given** assets exist in the system, **When** the user views the inventory list, **Then** each row displays: asset name, category icon, location, next maintenance due date (or "None scheduled"), and a status indicator (green = healthy, amber = maintenance due soon, red = overdue/past lifespan).

#### Category-Specific Fields

| Category | Additional Fields |
|---|---|
| Kitchen Appliance | Brand, Model, Serial Number, Energy Rating |
| HVAC | Brand, Model, Filter Size, Refrigerant Type |
| Plumbing | Material, Diameter/Size, Connected Fixture |
| Electrical | Amperage/Wattage, Circuit Number |
| Roofing | Material Type, Area (sq ft), Slope/Pitch |
| Exterior | Material, Area/Length, Exposure Direction |
| Vehicle | Make, Model, Year, VIN, Mileage |
| Furniture | Material, Room, Dimensions |
| Electronics | Brand, Model, Serial Number, Connectivity Type |
| Other/Custom | Free-form notes field only |

All categories share common fields: name, purchase date, purchase price, expected lifespan (years), warranty expiration date, location in home, custom tags, notes, photos.

---

### User Story 2 - View Dashboard with Upcoming Maintenance and Alerts (Priority: P1)

As a homeowner, I want to see a dashboard that shows me what needs attention — overdue maintenance, upcoming tasks, expiring warranties, and assets nearing end-of-life. I should scan this in under 10 seconds.

**Why this priority**: The dashboard is the primary interface and the reason users return daily/weekly.

**Independent Test**: Add assets with various schedules/warranty dates, verify dashboard surfaces items in priority order.

**Dashboard Information Architecture** (5 sections):
1. **Action Required** (top) — Overdue tasks sorted by days overdue. Shows: task name, asset name, days overdue, "Complete" quick-action.
2. **Upcoming This Week** — Tasks due within 7 days.
3. **Warranty Alerts** — Warranties expiring within 30 days.
4. **Lifecycle Watch** — Assets >80% of expected lifespan. Age, lifespan, percentage bar.
5. **Quick Stats** (sidebar/top) — Total assets, tasks completed this month, next upcoming task.

Each section collapses or shows "None" when empty. Count badges on populated sections.

**Acceptance Scenarios**:

1. **Given** assets with scheduled maintenance, **When** opening the dashboard, **Then** see five sections with overdue (red), upcoming (amber), and other sections populated accordingly.
2. **Given** warranty expires within 30 days, **Then** "Warranty Alerts" shows asset name, expiry date, days remaining.
3. **Given** asset >80% lifespan, **Then** "Lifecycle Watch" shows age, lifespan, percentage bar.
4. **Given** no overdue or upcoming items, **Then** "You're all caught up" state with Quick Stats and next event date.
5. **Given** zero assets, **Then** welcome/onboarding state with prominent "Add your first asset" CTA.

---

### User Story 3 - Schedule and Track Maintenance Tasks (Priority: P1)

As a homeowner, I want to create maintenance schedules — both recurring and one-time. When I complete a task, I log date, cost, and notes.

**Why this priority**: Maintenance scheduling is the core value proposition.

**Independent Test**: Create recurring/one-time tasks, mark complete, verify auto-scheduling and history accuracy.

**Task Creation Entry Points**:
1. **Asset Detail Page** — "Add Maintenance Task" (pre-fills asset).
2. **Top-level Tasks page** — "Add Task" (requires asset selection).

**Task Views**: Per-asset list + All Tasks page (top-level nav, sortable by due date/asset/status).

**Task Completion Flow**: "Complete" opens inline expansion below task row — completion date (defaults today), cost (defaults $0), notes (optional). "Save Completion" confirms and collapses. No modal or page navigation.

**Acceptance Scenarios**:

1. **Given** asset detail page, **When** clicking "Add Maintenance Task" and filling in name/type/interval, **Then** task created with calculated due date.
2. **Given** Tasks page, **When** clicking "Add Task," selecting asset, filling details, **Then** task appears in both All Tasks and asset's list.
3. **Given** task is due, **When** clicking "Complete," **Then** inline expansion opens. **When** "Save Completion," **Then** logged to history, next occurrence scheduled for recurring.
4. **Given** recurring task, **When** viewing asset detail, **Then** full maintenance history with dates, costs, notes.
5. **Given** task overdue >7 days, **Then** flagged with days past due.
6. **Given** sorting All Tasks by due date, **Then** overdue first, then upcoming, then completed.

---

### User Story 4 - Track Costs and Budget for Replacements (Priority: P2)

As a homeowner, I want to see lifetime spending per asset and replacement projections.

**Why this priority**: Turns maintenance data into financial insight.

**Independent Test**: Add asset with price, log 3-4 maintenance events, verify TCO and replacement timeline.

**Acceptance Scenarios**:

1. **Given** asset with price and maintenance history, **When** viewing cost summary, **Then** see purchase price, total maintenance, TCO, avg annual cost.
2. **Given** asset with purchase date and lifespan, **When** viewing replacement forecast, **Then** see replacement year, age percentage, estimated cost (original + 3% annual inflation).
3. **Given** multiple assets, **When** viewing budget overview, **Then** see replacement timeline for 1/5/10 years with costs.
4. **Given** annual maintenance >50% of annual depreciation, **Then** "consider replacement" indicator appears.

---

### User Story 5 - Search, Filter, and Organize Assets (Priority: P2)

As a homeowner with 30+ assets, I want quick search, filtering, and sorting.

**Why this priority**: Usability depends on efficient navigation at scale.

**Acceptance Scenarios**:

1. **Given** 30 assets, **When** searching "Samsung," **Then** matches shown within 500ms.
2. **Given** filtering by category "HVAC" and location "Basement," **Then** only matching assets shown with active filters visible.
3. **Given** sorting by "next maintenance due," **Then** most urgent first, no-maintenance last.
4. **Given** custom tags assigned, **Then** filterable by those tags.

---

### User Story 6 - Manage Documents and Manuals (Priority: P3)

As a homeowner, I want to attach documents (warranties, receipts, manuals) to assets.

**Navigation**: Per-asset "Documents" tab + top-level Documents page (filterable by type/asset).

**Acceptance Scenarios**:

1. **Given** asset detail, **When** uploading document, **Then** stored with label, upload date, file type indicator.
2. **Given** asset has documents, **Then** documents section shows thumbnails/icons.
3. **Given** top-level Documents filtered by "Warranty," **Then** all warranty docs listed with asset names.
4. **Given** document attached, **When** deleting (with confirmation) or re-labeling, **Then** change reflected immediately.

---

### User Story 7 - Receive Notifications (Priority: P3)

As a homeowner, I want email reminders for due maintenance and expiring warranties.

**Acceptance Scenarios**:

1. **Given** task due in 3 days, **Then** notification with task name, asset name, due date.
2. **Given** warranty expires in 30 days, **Then** notification at configured lead times (30/7/1 day).
3. **Given** notification settings, **Then** toggle email on/off, set lead times, set preferred time.

---

### Application Navigation Structure

Sidebar (desktop) / bottom tab bar (mobile):
1. **Dashboard** 2. **Assets** 3. **Tasks** 4. **Documents** (under "More" on mobile) 5. **Settings**

Asset detail tabs: Overview, Maintenance Tasks, Maintenance History, Documents, Cost Summary (P2).

---

### Edge Cases

- Maintenance interval of 0 days → rejected with validation error.
- Asset lifespan exceeded → "past expected lifespan" alert, not auto-archived.
- No purchase date → defaults to date added. Lifespan uses this date.
- File >10MB → rejected with compression suggestion.
- Dates stored UTC, displayed local timezone, calculated at day level.
- Recurring task interval changed → future recalculated from last completion. History unmodified.
- Asset deleted → confirmation, soft-delete (30 days recoverable).
- Task without asset (from All Tasks) → asset required, save disabled until selected.
- Empty inventory → "No assets yet" + prominent "Add Asset" button.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: CRUD + soft-delete for assets with name, category, purchase date/price, lifespan, warranty, location.
- **FR-002**: 10 categories with defined additional fields per table.
- **FR-003**: Recurring maintenance schedules (days/weeks/months/years) with auto-scheduling.
- **FR-004**: One-time maintenance tasks with due date.
- **FR-005**: Completion logging with date, optional cost (default $0), optional notes.
- **FR-006**: TCO per asset (purchase + cumulative maintenance).
- **FR-007**: Replacement timeline projection.
- **FR-008**: Full-text search across names, brands, notes, tags.
- **FR-009**: Filter by category, location, status, custom tags.
- **FR-010**: File uploads (images/PDFs, max 10MB) with label/re-label/delete.
- **FR-011**: Dashboard with 5 sections (Action Required, Upcoming, Warranty, Lifecycle, Stats).
- **FR-012**: Self-hostable via Docker (`docker-compose up`).
- **FR-013**: Email/password auth, session-based. Single-user mode supported.
- **FR-014**: Optional email notifications via configurable SMTP.
- **FR-015**: Local database, no external dependencies beyond optional SMTP.
- **FR-016**: Responsive web (sidebar desktop, bottom tab bar mobile).
- **FR-017**: Top-level Tasks page (all tasks, sortable).
- **FR-018**: Top-level Documents page (all docs, filterable).

### Key Entities

- **Asset**: name, category, brand, model, serial, purchase date/price, lifespan, warranty, location, status, tags, photos, notes + category-specific fields.
- **MaintenanceSchedule**: task name, description, interval type/value/unit, start date, last completed, next due.
- **MaintenanceLog**: completion date, cost, notes, linked schedule, linked asset.
- **Document**: file name, type, size, upload date, label, storage path.
- **User**: email, password hash, display name, notification prefs, timezone.
- **NotificationPreference**: email enabled, lead times per alert type, send time.

## Success Criteria *(mandatory)*

- **SC-001**: Add asset in under 60 seconds.
- **SC-002**: Dashboard loads within 2 seconds for 200 assets.
- **SC-003**: Search finds asset in under 3 seconds.
- **SC-004**: Next recurring occurrence scheduled within 1 second of completion.
- **SC-005**: TCO accurate to the cent.
- **SC-006**: Deploys via `docker-compose up` with env vars only.
- **SC-007**: P1-P2 usable on 375px without horizontal scroll.

## Assumptions

- Single property, 1-5 concurrent users. Multi-property out of scope.
- Self-hosted on user's server with Docker.
- Responsive web, not native mobile app.
- Email-only notifications for v1.
- No external service integrations in v1.
- Data import/export desirable but not required.
- Single currency configured at setup.
