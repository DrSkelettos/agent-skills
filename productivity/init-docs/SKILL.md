---
name: init-docs
description: Perform a comprehensive initial documentation pass of the entire application based on its current implementation. Use when the user asks for initial documentation, a documentation baseline, bootstrapping docs for an undocumented codebase, or a first full documentation pass.
disable-model-invocation: true
---

# Init Docs

Establish a complete, accurate, and consistent documentation baseline that reflects the application's actual current state — as if the Documentation Review Skill (`sync-docs`) had been invoked after every individual implementation phase throughout the application's development.

This skill is documentation-only: it inspects code, creates, updates, consolidates, or removes living docs under `docs/`. It does not implement features, change application code, or write new plans. For a scoped post-implementation sync use `sync-docs` instead; for a report-only full review requiring approval before edits use `audit-docs` instead.

## Inputs

No plan or branch input required. This is a full-baseline pass over the entire working tree, regardless of when individual features were implemented or last documented.

- If the user names a focus area, treat it as a prioritization hint, not a scope limit: still cover everything systematically, report the focus area first.
- Existing documentation, implementation plans (`docs/plans/`, `docs/plans/finished/`), commit messages, and other historical notes are context only. They never override the current implementation.

## Documentation guidelines and architecture

Read `docs/documentation-guidelines.md` before starting. It is authoritative for living vs. historical docs, writing rules, canonical homes per fact, and the architecture snapshot. Do not introduce a separate documentation philosophy or organizational structure.

Relevant canonical references (see the guidelines file for the full list):

- `AGENTS.md` — monorepo layout, service boundaries, coding and realtime rules.
- `docs/README.md` — documentation map.
- `docs/overview/README.md` — topology, service boundaries, deployment model.
- `docs/overview/runtime-flows.md` — end-to-end request and event flows.
- `docs/gateway/channels-and-events.md` — canonical Socket.IO event and Redis channel reference.
- `apps/worker-mission/src/redis/channels.ts` — authoritative Redis channel and IPC definitions.

## Philosophy: docs are a knowledge base for AI agents

Same philosophy as `sync-docs` and `audit-docs`. The audience is a future AI agent that must extend or modify the system without breaking it.

- Optimize for decision speed: overall architecture, system responsibilities and boundaries, interactions and dependencies, conventions and constraints, non-obvious behavior.
- Document what changes implementation choices: ownership boundaries, authorization patterns, validation authority (client hint vs. backend authoritative), atomicity requirements, invalidation flows, contract shapes (websocket events, Redis channels, IPC messages, persisted JSON).
- Prioritize, in order: (1) overall architecture, (2) responsibilities and boundaries of major systems, (3) how systems interact, (4) implementation conventions and constraints, (5) requirements and considerations when extending functionality.
- Apply the long-term-value filter aggressively: if a future agent would implement correctly without this sentence, do not write it. If the sentence prevents an architectural violation, keep it.
- Avoid: per-class/method exhaustiveness, repeating information already documented elsewhere, obvious implementation details, prose that merely reproduces source code, speculative or future functionality.

## Source of truth

The actual current implementation in the working tree (including uncommitted changes) is the sole source of truth — never existing docs, plans, or history.

- Do not assume existing documentation, implementation plans, commit messages, or historical notes accurately describe the current state. Verify every relevant statement against code.
- Inspect directly: overall architecture, major modules and responsibilities, relationships and dependencies, important workflows and business logic, data structures and relationships, conventions and patterns, cross-system interactions, constraints and design decisions.
- Do not document planned or partially implemented functionality as if it were implemented.
- When information is unclear or cannot be verified from the implementation, do not invent an explanation. Mark it as an assumption or unresolved question.
- Every documented claim must trace to code read in this session (cite concrete paths). If the docs and the code disagree, the code wins — unless intent is genuinely unclear, in which case flag the mismatch rather than silently rewriting.

## Scope

Cover the entire application and its living docs systematically — comparable to what would have resulted from invoking `sync-docs` after every implementation phase.

- Living docs (in scope): everything under `docs/` except plans — `docs/README.md`, `docs/overview/`, `docs/web/`, `docs/gateway/`, `docs/worker-mission/`, `packages/shared` contracts as documented, and `docs/documentation-guidelines.md` itself when it contradicts the repo.
- Historical records (out of scope, do not rewrite): `docs/plans/*.md`, `docs/plans/finished/*.md`.
- Code systems to inventory (verify against the tree; do not assume completeness of this list): `apps/web` (Laravel routes, Livewire, Filament, policies, browser JS managers/controllers), `apps/gateway` (socket auth, handler validation, room subscriptions, Redis bridging), `apps/worker-mission` (mission manager vs. child worker processes, simulation logic, patient domain services, action handlers, persistence), `packages/shared` (shared types/constants), PostgreSQL shared by Laravel and Prisma (migrations plus `apps/worker-mission/prisma/schema.prisma`), and all cross-app contracts (websocket events, Redis channels, IPC messages, persisted JSON shapes).
- For each major system capture: responsibilities, boundaries (what it owns vs. explicitly does not own), entry points, data flow, authoritative validation and state ownership, dependencies on other systems, and non-obvious traps.

## Workflow

### 1. Read guidelines and inventory docs

1. Read `docs/documentation-guidelines.md`, `docs/README.md`, and `AGENTS.md` first.
2. List every living doc and note which subsystem each covers.
3. Note known duplication, terminology variants, and stale structure up front.

### 2. Inventory the implementation

1. Enumerate the major systems actually present (see Scope). For each, note entry points, authoritative validation, state ownership (Laravel vs. worker-mission vs. transport-only gateway), atomicity, and cross-system dependencies — from code, with paths.
2. Identify major workflows that need sequential understanding (e.g. web UI → gateway validation/forwarding → worker action handler → persistence → broadcast back; mission lifecycle; auth/token flows).
3. Identify shared components, patterns, and abstractions other parts depend on (e.g. browser singleton managers, Redis channel naming, worker action routing).

### 3. Compare implementation against existing docs

1. Check each doc claim against the working tree. Follow callers, routes, migrations, handlers, configs; do not trust doc-to-doc agreement.
2. Record evidence (file paths, symbols, behavior) for each gap.
3. Classify per doc and per system:
   - **Outdated/inaccurate**: contradicts the implementation.
   - **Missing**: major system, interaction, constraint, convention, or workflow with no or superficial coverage.
   - **Duplicated/overlapping**: same behavior described in two places — note the canonical home.
   - **Obsolete/irrelevant**: describes structure or flow that no longer exists.
4. Maintain an explicit coverage checklist (completed vs. remaining systems) so no major area is skipped. If the application is too large for a single pass, divide into logical sections and process incrementally without losing track.

### 4. Decide the doc action per affected doc

For each affected doc or gap, choose exactly what is needed:

- **Update**: existing section describes the system but contradicts the implementation.
- **Extend**: implementation introduces a concept, constraint, or system with long-term value that no doc covers — create or extend a section; prefer updating an existing canonical doc before creating a new file.
- **Correct**: small factual fix (renamed route, moved file, changed default or contract) that would mislead an implementer.
- **Remove or consolidate**: content is obsolete, redundant, or irrelevant. Delete it or merge it into the canonical home with a cross-link. Never leave two competing descriptions. If replacing a doc, retire the stale one in the same change when safe.
- **Leave untouched**: detail is minor, self-evident from code, or has no long-term decision value.

Preserve useful existing information, especially architectural decisions and constraints not inferable from code. Never preserve outdated information merely for historical completeness unless the guidelines explicitly call for it.

### 5. Apply changes directly

1. Edit the living docs in place. Keep changes tight and focused: one edit per doc section, no drive-by reformatting.
2. Preserve doc structure and tone. Match surrounding headings, code-fence style, and repo vocabulary (missions, patients, traits and `trait_standards`, equipment/medication/infusion actions, mission rooms and `patient:{id}` rooms, manager vs. child worker processes, Redis bridging). Do not introduce competing terms.
3. Keep individual documents focused and appropriately scoped. Cross-link instead of copying: one authoritative description, short references elsewhere.
4. When changing event names, Redis channels, or payload shapes in prose, ensure producers, consumers, and the canonical contract doc (`docs/gateway/channels-and-events.md` plus code in `apps/worker-mission/src/redis/channels.ts`) agree.
5. Do not rewrite historical plans. Do not implement code changes as a side effect.

### 6. Final consistency review

1. Re-read every edited section and confirm it matches the inspected code and introduces no contradiction with the canonical references in `docs/documentation-guidelines.md`.
2. Confirm no duplication remains between edited docs and that terminology is consistent across all documentation.
3. Confirm the full coverage checklist from step 3 is addressed — do not stop after the overall architecture or a few prominent modules.

### 7. Report back

Provide a concise summary:

- Which areas and systems were documented.
- Which existing documents were updated or removed (with paths, one line each with reason).
- Which new documents were created (with paths and reason — new files only where no canonical home existed).
- Which docs were deliberately left untouched and why.
- Any significant documentation gaps or unresolved questions that could not be addressed through code inspection, marking assumptions vs. confirmed behavior.

## Interaction rules

- Be concise in conversation; the detail belongs in the doc edits.
- Make the doc edits yourself. Do not produce a review-only report unless you lack write access — in that case, explain the limitation and provide exact proposed edits in the conversation.
- Never present plan, commit, or doc content as fact. Every documented claim must trace to code you read in this session.
- Use the question tool when a docs decision hinges on user intent (e.g. whether an old spec is still the roadmap or should be retired). For minor wording, decide and move on.
- Treat this as a comprehensive baseline effort, not a lightweight review. Do not stop after documenting the overall architecture or a few prominent modules — the entire application must be covered systematically.
