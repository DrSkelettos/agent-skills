---
name: redesign-from-template-triage
description: Redesign a Blade/Livewire page from an external template with full triage of unused content. Use when the user asks to redesign from a template and decide per section whether to skip it, keep it as placeholder, or implement it properly, or mentions triage, review unused sections, or placeholders.
compatibility: Works with repository-aware coding agents that can inspect Blade views, Tailwind classes, and language files.
metadata:
  version: "1.0.0"
---

# Redesign From Template (Triage)

Rebuild a target page or section using an external template as the visual/structural base. Like `redesign-from-template`, except nothing unmatched is silently skipped: every template section with no target equivalent is triaged with the user as **skip**, **placeholder**, or **implement properly**. Reuse existing Blade components wherever possible; expand or create components only when no suitable component or variant exists.

This skill performs implementation: it edits Blade views (and, when needed, their Livewire backing, language files, and Blade components).

## Inputs

Taken from (in order):

1. Arguments or message content naming the template source and the redesign target.
2. Files or references most recently discussed in this conversation.

If either side is missing, ask before starting. Required:

- **Template source**: pasted HTML, image/screenshot, URL, or file path. Read it in full. If it cannot be read or fetched, stop and say so.
- **Redesign target**: existing Blade view path (e.g. `apps/web/resources/views/...blade.php`) plus its Livewire component if any. If the target does not exist yet, confirm the exact path to create.
- **Triage decisions**: per unmatched section, one of skip / placeholder / implement. Collect these in step 3; do not start step 5 until every unmatched section has an explicit decision.

## Boundaries

- The template is a base only. Never port it 1:1.
- Nothing unmatched is dropped by default. An unmatched section without a recorded user decision is a blocker, not an assumed skip.
- Do not invent data, routes, actions, or copy. Bind kept and implemented sections only to data and routes the target already provides; flag gaps instead of guessing.
- `Implement properly` may expand scope (new query, action, route, or Livewire state). Treat that scope as part of the proposal in step 4 and confirm it before building.
- Do not introduce new dependencies, build tooling, or CSS frameworks.
- Do not rewrite unrelated pages or refactor the design system as a side effect.

## Canonical references

Read before implementing:

- `DESIGN.md` — authoritative visual system (Executive Simulation theme, Tailwind v4 tokens, frosted surfaces, tabular numerals, `label-sm` uppercase metadata, 6px status beacons).
- `docs/frontend.md` — Blade component catalog, modal system, language-file and Vite conventions.
- `apps/web/resources/views/components/*` — the reusable component inventory (`button/card/surface/section-card/badge/tab`, `status-beacon`, `empty`, `progress`, `pill-choice`, `segmented-control`, `action-tile`, `modal/*`, `simulation/*`, form inputs).
- `apps/web/lang/en/*.php` — every user-facing string lives here via `__('domain.key')`; never hardcode copy in views or UI, including placeholders.

## Workflow

### 1. Establish target and template

1. Restate in one or two sentences: which target is being redesigned from which template.
2. Read the target view end to end plus its Livewire class, routes, and language file entries. Note real data, actions, states (loading/empty/error), and authorization.
3. Read the template end to end. Break it into numbered sections (header/hero, nav, cards, tables, forms, footers, decorative blocks) so each can be triaged.

### 2. Inventory existing components first

Before writing any markup:

1. List `apps/web/resources/views/components/*` and read the candidates that match the template patterns (props, variants, slots such as `header`/`footer`).
2. For each template pattern, record: reuse as-is, reuse with different props/slots, needs new variant on existing component, or no match.
3. Prefer existing components even if the match is approximate; adapt with props and Tailwind/DESIGN.md tokens rather than ad-hoc markup.

### 3. Triage every unmatched section

1. Build the mapping table first:
   - **Matched**: template section → target data/action it serves (keep, rebinding placeholder copy to real data).
   - **Unmatched**: template sections with no target equivalent. Number each one and quote or describe it precisely enough that the user can identify it.
2. Ask the user for a decision on **every** unmatched section using the question tool, in small coherent batches (3–5 sections per batch). Each question must offer the same three options:
   - **Skip**: omit the section entirely. Record it in the report as deliberately omitted.
   - **Placeholder**: render the template structure with honest empty state (e.g. `<x-empty>` with `title`/`description` via `__('domain.key')`, or a `section-card`/`card` shell with an empty body). Never present fake numbers, names, or statuses as real data. Placeholders must still follow `DESIGN.md` and use lang keys.
   - **Implement properly**: wire the section to real data/actions. If the target backend does not supply them, state what is missing (query, route, action, Livewire state) and confirm the extra scope before building; do not invent it.
3. Recommend a default per section where the consequence is clear (e.g. marketing filler → skip; roadmap widget with no backend → placeholder), without steering deceptively. Never apply the default silently — record the user's explicit choice.
4. Do not proceed to implementation while any unmatched section lacks a decision. If the user defers a section, mark it **deferred → treat as placeholder** or stop and wait, and say which you did.

### 4. Propose component and scope changes before creating

Per repo convention, never silently add ad-hoc markup, new components, or new backend scope:

1. Present a short proposal: existing candidates checked (with paths), why none fits, and what you intend — either a new `variant`/prop on an existing component (e.g. new `variant` in `button.blade.php`, `badge.blade.php`) or a new Blade component (name, props, slots, following sibling `@props` + `match` conventions). Include any `implement properly` scope (new data, actions, lang domains).
2. Wait for user approval before creating or expanding components or backend scope.
3. After approval, implement following sibling conventions exactly (prop defaults, `match` for variants, `$attributes->class([...])` merging, `DESIGN.md` tokens, no hardcoded copy).

### 5. Implement the redesign

1. Rebuild the target view from the template skeleton, inserting matched sections bound to real data plus triaged sections per their recorded decisions.
2. Follow `DESIGN.md` + Tailwind v4: frosted surface tiers, hairline borders, `rounded-lg` cards / `rounded-xl` command windows, `space-*` spacing scale, `type-*` typography, tabular numerals for numbers/balances.
3. Use `__('domain.key')` for every user-facing string, including placeholder titles and descriptions; add keys to the correct `apps/web/lang/en/*.php` file (extend existing files, do not create new domains without approval).
4. Keep Livewire behavior intact: preserve state, validation, and authorization; keep modal triggers on the shared system (`<x-modal-trigger :component="..." :params="[...]">` in Blade or `openModal()` via `InteractsWithModals` in Livewire for components extending `App\Livewire\Modal`). Full-page screens stay plain components, never modals.
5. Keep changes scoped to the target view (+ approved component/language-file/backing edits). Do not touch unrelated views.

### 6. Verify and report

1. Re-read the edited view and every touched component/lang file; confirm no hardcoded copy, no ad-hoc duplicate of an existing component, and every unmatched section matches its triage decision (no silent skips, no fake data presented as real).
2. If PHP was modified, run `vendor/bin/pint --dirty` from `apps/web` before finishing.
3. Pure copy/styling/layout-only changes need no new tests. If behavior or logic changed (expected for `implement properly`), run the narrowest affected Pest scope first (`php artisan test --compact <path> --filter=...` from `apps/web`).
4. If the frontend change does not appear, remind the user to run `npm run build`, `npm run dev`, or `composer run dev`.
5. Report back with the full triage table: target path, template source, and for every section its decision (kept / skipped / placeholder / implemented) plus components reused vs. expanded/created (with paths), lang keys added, and verification performed.

## Interaction rules

- Be concise in conversation; the diff plus the triage table are the deliverables.
- Ask for every unmatched section via the question tool; batch 3–5 per round. Decide minor styling details yourself per `DESIGN.md`.
- Never present template placeholder copy, data, or routes as real. Flag anything the target cannot supply.
- If the template or target cannot be inspected, explain the limitation and do not claim the redesign was completed.
