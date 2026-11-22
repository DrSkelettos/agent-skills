---
name: redesign-from-template
description: Redesign an existing Blade/Livewire page from an external template, mockup, or pasted HTML/image/URL. Use when the user asks to redesign, restyle, rebuild, or port a page or section based on a template, mock, wireframe, or reference layout.
compatibility: Works with repository-aware coding agents that can inspect Blade views, Tailwind classes, and language files.
metadata:
  version: "1.0.0"
---

# Redesign From Template

Rebuild a target page or section using an external template as the visual/structural base. Carry over only the content and elements the target actually needs; skip everything else. Reuse existing Blade components wherever possible; expand or create components only when no suitable component or variant exists.

This skill performs implementation: it edits Blade views (and, when needed, their Livewire backing, language files, and Blade components).

## Inputs

Taken from (in order):

1. Arguments or message content naming the template source and the redesign target.
2. Files or references most recently discussed in this conversation.

If either side is missing, ask before starting. Required:

- **Template source**: pasted HTML, image/screenshot, URL, or file path. Read it in full. If it cannot be read or fetched, stop and say so.
- **Redesign target**: existing Blade view path (e.g. `apps/web/resources/views/...blade.php`) plus its Livewire component if any. If the target does not exist yet, confirm the exact path to create.
- **Needed vs. skipped**: which template sections carry over and which do not. If the user has not said, derive a proposed keep/skip list (step 3) and confirm it.

## Boundaries

- The template is a base only. Never port it 1:1. Every template section must earn its place against the target's real data and actions.
- Do not invent data, routes, actions, or copy. Bind only to data and routes the target already provides; flag gaps instead of guessing.
- Do not introduce new dependencies, build tooling, or CSS frameworks.
- Do not rewrite unrelated pages or refactor the design system as a side effect.

## Canonical references

Read before implementing:

- `DESIGN.md` — authoritative visual system (Executive Simulation theme, Tailwind v4 tokens, frosted surfaces, tabular numerals, `label-sm` uppercase metadata, 6px status beacons).
- `docs/frontend.md` — Blade component catalog, modal system, language-file and Vite conventions.
- `apps/web/resources/views/components/*` — the reusable component inventory (`button/card/surface/section-card/badge/tab`, `status-beacon`, `empty`, `progress`, `pill-choice`, `segmented-control`, `action-tile`, `modal/*`, `simulation/*`, form inputs).
- `apps/web/lang/en/*.php` — every user-facing string lives here via `__('domain.key')`; never hardcode copy in views or UI.

## Workflow

### 1. Establish target and template

1. Restate in one or two sentences: which target is being redesigned from which template.
2. Read the target view end to end plus its Livewire class, routes, and language file entries. Note real data, actions, states (loading/empty/error), and authorization.
3. Read the template end to end. Break it into sections (header/hero, nav, cards, tables, forms, footers, decorative blocks).

### 2. Inventory existing components first

Before writing any markup:

1. List `apps/web/resources/views/components/*` and read the candidates that match the template patterns (props, variants, slots such as `header`/`footer`).
2. For each template pattern, record: reuse as-is, reuse with different props/slots, needs new variant on existing component, or no match.
3. Prefer existing components even if the match is approximate; adapt with props and Tailwind/DESIGN.md tokens rather than ad-hoc markup.

### 3. Map content: keep vs. skip

Build an explicit table and confirm it when anything is ambiguous:

- **Keep**: template section → target data/action it serves. Drop placeholder content; rebind to real target data.
- **Skip**: template sections with no target equivalent (marketing filler, fake stats, irrelevant CTAs, decorative panels). Name each skipped section so the omission is deliberate, not accidental.
- **Adapt**: template structure kept but content replaced (e.g. template pricing table becomes the target's real ledger table).

Use the question tool for blocking keep/skip decisions. For minor choices, assume skip-the-filler and record the assumption.

### 4. Propose component changes before creating

Per repo convention, never silently add ad-hoc markup or new components:

1. Present a short proposal: existing candidates checked (with paths), why none fits, and what you intend — either a new `variant`/prop on an existing component (e.g. new `variant` in `button.blade.php`, `badge.blade.php`) or a new Blade component (name, props, slots, following sibling `@props` + `match` conventions).
2. Wait for user approval before creating or expanding components.
3. After approval, implement following sibling conventions exactly (prop defaults, `match` for variants, `$attributes->class([...])` merging, `DESIGN.md` tokens, no hardcoded copy).

### 5. Implement the redesign

1. Rebuild the target view from the template skeleton, inserting only kept/adapted sections bound to real data.
2. Follow `DESIGN.md` + Tailwind v4: frosted surface tiers, hairline borders, `rounded-lg` cards / `rounded-xl` command windows, `space-*` spacing scale, `type-*` typography, tabular numerals for numbers/balances.
3. Use `__('domain.key')` for every user-facing string; add keys to the correct `apps/web/lang/en/*.php` file (extend existing files, do not create new domains without approval).
4. Keep Livewire behavior intact: preserve state, validation, and authorization; keep modal triggers on the shared system (`<x-modal-trigger :component="..." :params="[...]">` in Blade or `openModal()` via `InteractsWithModals` in Livewire for components extending `App\Livewire\Modal`). Full-page screens stay plain components, never modals.
5. Keep changes scoped to the target view (+ approved component/language-file edits). Do not touch unrelated views.

### 6. Verify and report

1. Re-read the edited view and every touched component/lang file; confirm no hardcoded copy, no ad-hoc duplicate of an existing component, and no skipped-template content crept back in.
2. If PHP was modified, run `vendor/bin/pint --dirty` from `apps/web` before finishing.
3. Pure copy/styling/layout-only changes need no new tests. If behavior or logic changed, run the narrowest affected Pest scope first (`php artisan test --compact <path> --filter=...` from `apps/web`).
4. If the frontend change does not appear, remind the user to run `npm run build`, `npm run dev`, or `composer run dev`.
5. Report back: target path, template source, keep/skip summary (sections kept, sections deliberately skipped), components reused vs. expanded/created (with paths), lang keys added, and verification performed.

## Interaction rules

- Be concise in conversation; the diff is the deliverable.
- Confirm blocking keep/skip and all component create/expand decisions with the question tool; decide minor styling details yourself per `DESIGN.md`.
- Never present template placeholder copy, data, or routes as real. Flag anything the target cannot supply.
- If the template or target cannot be inspected, explain the limitation and do not claim the redesign was completed.
