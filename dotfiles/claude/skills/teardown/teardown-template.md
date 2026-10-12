Reference shapes for the teardown files and the final report. Rules live in `SKILL.md`.

## Folder shape

```
docs/teardown/<slug>/
├── index.md             overview, screen map, feature table, opportunities, brief for /scope
├── features.md          one section per feature (split into features/<area>.md when large)
├── flows.md             the core user journeys, step by step, with friction
├── data-and-roles.md    entities, relations, lifecycles, roles and permissions matrix
└── design-language.md   layout, visual feel, component inventory, tone, accessibility
```

Format rules:
- Plain language, same output style as the other skills.
- Each fact lives once. `index.md` links to details rather than repeating them.
- Only what is known. No `n/a` or empty fields; leave a field out when there is nothing to say.
- Feature IDs are stable forever. New features get the next free number, never reuse a number. `cut` features stay listed.
- Evidence tag on every feature and on every rule that is not obvious: `seen` (you observed it) or `inferred` (you deduced it; say from what).

## index.md

```markdown
# Teardown: <Product name>

<One or two sentences: what the product is, who uses it, and the job it does for them.>

**Source:** <url> · **Access:** <public | logged in | test account> · **Depth:** <Quick | Standard | Deep> · **Date:** <YYYY-MM-DD>
**Goal of the new version:** <from intake, one line>

## At a glance

| ID | Feature | Area | Verdict |
|----|---------|------|---------|
| F-001 | Sign up with email | Account | improve |
| F-002 | Project board | Projects | keep |
| F-031 | Offline drafts | Editor | new |
| … | … | … | … |

**Counts:** <n> features · <k> keep · <i> improve · <c> cut · <w> new

## Screen map

- **<Area>**: <screen>, <screen>, <screen>
- **<Area>**: …

**Not covered:** <screens or areas skipped, and why (paywall, would cause side effects, out of depth)>

## Observed tech (facts, not recommendations)

<What the original appears to use, from network requests and page source: rendering style (server pages vs single page app), realtime connection, auth provider, payments, analytics, support widget. One line each, marked seen or inferred.>

## Non functional signals

<Speed, realtime, offline, notifications, search, import and export, integrations, mobile and responsive behavior, internationalization, SEO. One line each, with a verdict when it matters.>

## Plans and limits

<From the pricing page: plans, prices, what each unlocks, usage limits.>

## Opportunities

Ranked by payoff for the new version.

1. **<Short name>** (<F-IDs>): <what is wrong today, what to do instead, why it matters>.
2. …

## Brief for /scope

<One paragraph product idea for the new version: what it is, who it serves, the core loop, and what makes it better than the original.>

**First version (must have):** <feature names with IDs>
**Next:** <…>
**Later:** <…>
**Leave out:** <cut features with IDs, one line why>

## Open questions for /architect

- <A load bearing decision the rebuild implies, phrased as a question, no tool names. Example: Do edits need to appear live for other users on the same board (realtime), or is refresh on load enough? Relevant to F-002, F-007.>
- …

## Files

[Features](features.md) · [Flows](flows.md) · [Data and roles](data-and-roles.md) · [Design language](design-language.md)
```

## features.md

Group by area, in nav order. One section per feature:

```markdown
# Features: <Product name>

## <Area>

### F-007 Filter the task list · improve
**Job:** find the tasks that matter right now without scrolling.
**Where:** Projects › Board, filter button in the toolbar; also `F` shortcut.
**How it works:** <what the user does and what happens, step by step, in plain words>.
**Inputs:** status (multi select), assignee, label, due date range. **Output:** the list narrows live; a chip row shows active filters.
**States:** empty result shows "No tasks match" with a clear filters link (seen). No loading state visible.
**Rules:** filters combine with AND (seen). Saved filters limited to 5 on the free plan (seen, pricing page).
**Data:** Task, Label, User.
**Roles:** everyone with view access.
**Evidence:** seen
**Weak spots:** filters reset on every page load; no OR logic; not shareable by link.
**Improve:** keep filters in the URL so they survive reloads and can be shared; allow OR within a field; saved views per user.
```

For `cut`: replace **Improve** with **Why cut:**. For `new`: **Where**, **How it works**, and **Evidence** describe the proposal (evidence: `proposed`, plus which weak spot or flow friction led to it).

## flows.md

```markdown
# Core flows: <Product name>

## 1. <Flow name, e.g. Sign up to first value>
**Who:** <role> · **Goal:** <what they want at the end> · **Features:** F-001, F-002, F-010

1. <step: where, what the user does, what they see>
2. …

**Clicks or screens to done:** <n>
**Friction:** <points where it is slow, confusing, or fails>
**Better version:** <the reshaped flow in 2 to 4 steps>
```

## data-and-roles.md

```markdown
# Data and roles: <Product name>

## Entities

| Entity | Key fields | Belongs to | Has many | Evidence |
|--------|-----------|------------|----------|----------|
| Workspace | name, plan | | Projects, Members | seen |
| Task | title, status, due date, assignee | Project | Comments, Attachments | seen |

## Lifecycles

- **Task:** backlog → todo → in progress → done → archived (seen); deleted items go to trash for 30 days (inferred from the trash page text).

## Roles and permissions

| Action | Owner | Admin | Member | Guest |
|--------|-------|-------|--------|-------|
| Invite people | yes | yes | no | no |
| Delete project | yes | yes | no | no |

<Note which cells are seen and which are inferred.>
```

## design-language.md

```markdown
# Design language: <Product name>

## Layout
<App shell (sidebar, top bar), grid, spacing rhythm, density, how it adapts to narrow screens.>

## Visual feel
<Color roles (background, surface, accent, danger), light and dark mode, type feel (sizes, weights, one family or two), corner radius, shadows, icon style. Describe, don't copy exact brand assets.>

## Components
| Component | Where seen | Variants and states | Notes |
|-----------|-----------|---------------------|-------|
| Button | everywhere | primary, secondary, ghost, danger; loading, disabled | |
| Command palette | Cmd+K | | |

## Motion and feedback
<Transitions, toasts, optimistic updates, skeletons.>

## Tone of voice
<How the copy talks: formal or casual, microcopy examples in short quotes.>

## Accessibility
<Keyboard reachability, visible focus, contrast problems, missing labels, what a screen reader would struggle with.>

## Keep, change
<What to keep from this design language, what to change in the new version.>
```

## The /teardown complete report

```markdown
## /teardown complete

**Product:** <name> (<url>) · **Depth:** <depth> · **Screens covered:** <n> of <m>
**Features:** <n> (<k> keep · <i> improve · <c> cut · <w> new)
**Written to:** `docs/teardown/<slug>/`

**Top opportunities**
1. <name>: <one line>
2. …
3. …

**Not covered:** <areas and why, or "nothing">
**Cleanup:** <items created in the account during the teardown, or "nothing created">

**Next (recommended):**
/scope Build an improved version of <product>. Use docs/teardown/<slug>/index.md as the brief.
```
