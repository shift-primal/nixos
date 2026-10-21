---
name: teardown
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, ToolSearch
description: 'Run /teardown <url> to reverse engineer an existing website or web app into a full feature teardown in docs/teardown/<product>/: every screen, every feature, what it is for, how it behaves, its rules, data, flows, design language, weak spots, and how a better version would do it. Drives the real site in Chrome. The output is the input for /scope (and later /architect) to rebuild a new, improved version of the product. Use it whenever you want to clone, rebuild, replace, compete with, modernize, or "do a better version of" an existing site or app, or ask for a feature breakdown, product teardown, competitor analysis, or design sheet of a live website, even if you do not say teardown.'
---

## Output style (plain words, no dashes, no hyphens)

<!-- OUTPUT-STYLE:START -->

Write everything this skill produces, files and messages alike, in plain simple language. Talk to the reader as `you`, warm and direct like a colleague, and present every step as a recommendation they may run or skip, never an order. Keep technical terms that carry real meaning; explain each in plain words. Never use a dash or a hyphen as punctuation: no em dash, no en dash, and no hyphenated compounds. Write `read only`, not `read-only`. Say it in simple words, or reword the sentence. Code, file paths, command flags, and values other skills match on keep their hyphens. Use short sentences, commas, or parentheses. Clear beats clever.
<!-- OUTPUT-STYLE:END -->

## What this skill does

Takes a live product (a URL, optionally a logged in session) and produces a teardown: a complete, structured inventory of what the product does, written so someone who has never seen it could rebuild it, plus an honest read of where it falls short and what a better version would change.

It answers **what exists and what should exist instead**. It does not plan build order (that is `/scope`), and it does not pick tools or design the build (that is `/architect`). The teardown is the evidence both of them read.

Pipeline position:

```
/teardown <url>  →  docs/teardown/<product>/   (what the old product does + what to improve)
/scope           →  docs/scope/                (what to build, in what order)
/architect       →  docs/specs/                (how to build each feature)
```

## Why the output looks the way it does

- **Stable feature IDs (`F-001`, …)** so `/scope`, `/architect`, and you can point at one feature without ambiguity, across sessions.
- **Seen vs inferred.** You can only observe the UI. Anything about the backend (limits, permissions, data rules, jobs that run on a schedule) is a guess. Mark each fact `seen` or `inferred` so later skills know what is proven and what still needs a decision.
- **Tool agnostic recommendations.** The teardown may _record_ what the original uses (observed tech, third party services) as a fact, but it never _recommends_ a library, framework, host, or provider. That choice belongs to `/architect`, and naming tools here makes the scope rot.
- **A verdict on every feature** (`keep`, `improve`, `cut`, `new`) so the improved version is a set of explicit calls, not a copy.
- **A brief for /scope** at the end of `index.md`, written as a product idea, because `/scope` takes a product idea as input.

## Asks vs acts

Senior product engineer doing competitive research. INFER what the site shows. ASK only what the site cannot tell you, in one batched round (use `AskUserQuestion` on Claude Code, else plain text with the same options; up to 4 questions; each with 2 to 4 concrete options, exactly one marked `(recommended)` with a one line why; never add your own Other option):

1. **Access**: public pages only · you are already logged in in Chrome (recommended when the app is behind a login) · you will give test credentials.
2. **Depth**: Quick (landing, pricing, 3 to 5 core flows, about 15 screens) · Standard (every main nav area and its key sub screens, about 40 screens, recommended) · Deep (every reachable screen, setting, modal, and state).
3. **Goal of the new version** (shapes the verdicts): faithful rebuild with polish · same job, sharper for a narrower audience · leapfrog (rethink the core flow) · internal tool version for my own team.
4. **Who it is for** (only if not obvious from the site or the conversation).

Skip any question already answered in the request or conversation. If no URL was given, ask for it first in one line.

## Safety and good manners while crawling

You drive a real browser, often inside the user's real account. Treat it like someone else's house.

- Only tear down products the user has a right to use. Use their own account or a test account.
- **Never do anything with real side effects**: no payments or checkout, no sending messages, invites, or emails to real people, no deleting or overwriting real data, no changing account or billing settings, no publishing. Open the form or dialog, record what it contains and what it would do, then cancel. If a flow can only be understood by completing it, ask first, and suggest a test account or throwaway data.
- Creating throwaway items (a test project called `teardown test`) is fine when the user said the account is a test account; ask otherwise. List anything you created in the report so the user can clean up.
- Avoid browser dialogs (`alert`, `confirm`): they freeze the Chrome extension. Before clicking something labelled delete, remove, or leave, assume it opens one and do not click it.
- Browse at human pace. No bulk scraping, no hammering endpoints, no bypassing paywalls, captchas, or rate limits. If a captcha or login wall appears, stop and ask.
- Do not copy the original's copyrighted text, images, or brand assets into the teardown beyond short quotes needed to describe a feature. Describe; don't clone content.
- Never write passwords or tokens into the teardown files.

## Artifact ownership

`docs/teardown/<product-slug>/` is owned by this skill. It writes nothing else: no scope rows, no specs, no code, no `AGENTS.md`. Artifact base: `docs/` by default; if `docs/` is a published docs site (`docusaurus.config.*`, `.vitepress/`, `mkdocs.yml`, Astro Starlight, or Nextra detected) or `.workflow/` already exists, use `.workflow/teardown/<product-slug>/`.

Running `/teardown` again on the same product updates the folder in place (add new findings, correct wrong ones, keep feature IDs stable, never renumber). Mark the refresh date in `index.md`.

## Reference files

- `teardown-template.md`: the exact shape of every output file and the final report. Read it before Step 4, not earlier.

## Execution

### Step 0: Tools and intake

1. Load the Chrome tools in one call (skip if already loaded): `ToolSearch` with `select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__get_page_text,mcp__claude-in-chrome__find,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__read_network_requests,mcp__claude-in-chrome__resize_window,mcp__claude-in-chrome__javascript_tool`. If the `claude-in-chrome` skill is available, invoke it first as it requires.
2. If Chrome is not connected, say so and offer the fallback: `WebFetch` on public pages only. Be clear that a fallback teardown of a JavaScript app will miss most interactive behavior, and mark it `Coverage: public pages via fetch` in `index.md`.
3. Ask the intake round (above). Pick the product slug from the product name (`linear`, `notion-calendar`).
4. Check for an existing `docs/teardown/<slug>/`. If it exists, read `index.md` and `features.md` first; this run refreshes them.

### Step 1: Recon (map before you walk)

Open a new tab (never reuse the user's tabs). Then build a screen map before going deep:

- Home page, top nav, footer links, user menu, sidebar. `read_page` gives the structure; `find` locates menus.
- `/sitemap.xml` and `/robots.txt` for public URL patterns (read them, respect disallowed paths).
- Pricing page and docs or help center: these state plans, limits, and features in plain words, often more reliably than the UI. Record plan limits here.
- Changelog or "what's new" if present: shows what the makers consider important and recent.
- `read_network_requests` on a couple of screens to note observed tech and third party services (analytics, payments, auth, chat widgets, realtime connections). Record as facts only.

Write the screen map as a working list (areas → screens). Size it against the chosen depth. If Standard or Deep would exceed about 60 screens, tell the user the size and propose which areas to cover first rather than silently skipping.

### Step 2: Walk every screen

For each screen on the map, in nav order:

1. Navigate. Take one screenshot to see it (layout, hierarchy, visual language), then use `read_page` or `get_page_text` for exact labels, fields, and structure (cheaper and more precise than reading pixels).
2. Reveal the hidden parts: open menus, dropdowns, tabs, context (right click / `…`) menus, hover tooltips, keyboard shortcut panels (try `?` and `Cmd/Ctrl+K`), and empty states. Open create and edit forms and read every field, its validation, and defaults; then cancel.
3. Test states where it is safe: empty, loading, error (submit an obviously invalid value in a form, then cancel), long content, and a narrow window (`resize_window` to about 390px wide) for responsive behavior.
4. Capture per screen: purpose, entry points, what the user can do here, and every feature on it.

Take notes into a scratch file as you go (in the scratchpad directory if one exists) so nothing is lost if the context is summarized. Group findings by area.

For a Deep teardown of a large product, you may hand whole areas to `general-purpose` subagents only if they can drive their own browser tab; the Chrome extension is shared, so run them one at a time, never in parallel. Default to doing it inline.

### Step 3: Extract features and cross cutting sheets

Turn screen notes into features. A feature is one user job (for example "invite a teammate", "filter the list by status", "export to CSV"), not one button. For each feature record the fields in the template: ID, name, area, user job, where it lives, how it works, inputs and outputs, states, rules, data touched, roles, evidence (`seen` / `inferred`), weak spots, verdict, and improvement.

Then write the cross cutting sheets from everything you saw:

- **Roles and permissions**: who can do what (a matrix).
- **Data model**: entities, key fields, relations, and lifecycle (states an item moves through). Tool agnostic: entities and relations, not tables and column types.
- **Core flows**: the 3 to 8 journeys that matter most (signup to first value, the main daily loop, collaboration, billing), step by step, with friction points.
- **Design language**: layout system, color and type feel, component inventory (list every reusable UI component you saw), density, motion, tone of voice, accessibility observations (keyboard use, focus, contrast, labels).
- **Non functional signals**: speed, realtime updates, offline behavior, notifications, integrations, import and export, search, SEO, internationalization.

### Step 4: Judge and improve

Read `teardown-template.md` now. Then take the product goal from intake and give every feature a verdict:

- `keep`: works well, rebuild as is.
- `improve`: the job matters, the execution is weak; say concretely what changes.
- `cut`: rarely useful, confusing, or legacy; say why.
- `new`: a feature the original lacks that the improved version should have (from gaps you noticed, friction in the flows, or the goal). Give it an ID too.

Improvements must be specific and grounded in what you saw ("the filter resets on every page load; persist it in the URL") not generic ("improve UX"). Then write the **Opportunities** list: the 5 to 10 changes with the biggest payoff, ranked.

Finally write the **Brief for /scope** section: one paragraph product idea for the new version, who it serves, the core loop, and the feature list grouped as must have for a first version, next, and later, each line pointing to its feature IDs. Add **Open questions for /architect**: the load bearing technical decisions the rebuild implies (realtime or not, offline, multi tenant, file storage, search, permissions model, integrations), phrased as questions, no tool names.

### Step 5: Write the files

Write the files in the shape `teardown-template.md` gives. One folder per product. Keep `index.md` scannable: someone should grasp the product and the rebuild plan in two minutes from it alone. For a large product (roughly 60 or more features), split `features.md` into `features/<area>.md` with `index.md` linking each.

Before finishing, check your own output:

- Every screen on the map is either covered or listed under **Not covered** with the reason.
- Every feature has a verdict and an evidence tag.
- No tool, library, framework, or provider is recommended anywhere (observed tech in the Observed tech section is fine).
- No credentials, no personal data of real people from the account, no long copied text.

### Step 6: Report

Close with the report block from `teardown-template.md`: coverage, counts by verdict, top 3 opportunities, anything you created in the account that needs cleanup, and the recommended next command:

```
/scope Build an improved version of <product>. Use docs/teardown/<slug>/index.md as the brief.
```

Close the tab you opened.
