---
name: plan-spec
description: Turn feature requests, bug reports, and technical specifications into precise, repository-aware implementation plans. Use when the user invokes plan-spec, asks to plan work before coding, or wants open requirements clarified and a plan saved under docs/plans/. Do not implement the planned changes.
compatibility: Works with repository-aware coding agents that can inspect files and create Markdown documents.
metadata:
  version: "1.0.0"
---

# Plan Spec

Create a concrete implementation plan that another coding agent can execute without guessing. This skill is planning-only: do not implement the feature, modify application code, install dependencies, run migrations, or make other product changes. The only intended write is the final plan document under `docs/plans/` (and, if necessary, creating that directory).

## Inputs

The user may provide a free-form request, acceptance criteria, links, paths to specifications, screenshots, or partial technical notes. Start from the information provided; do not demand a formal spec.

If the user has not yet supplied a task, ask them to describe the feature, bug, or technical change. Then continue through this workflow.

## Workflow

### 1. Establish the task and inspect the repository

1. Restate the intended outcome in one or two sentences and identify the scope you currently understand.
2. Inspect relevant repository instructions, living documentation, and context before planning:
   - `AGENTS.md`, `CLAUDE.md`, `README`, contributor/development guides, and relevant package/build/test configuration.
   - `docs/documentation-guidelines.md` first, then `docs/architecture.md` plus the topic guide(s) and `docs/specs/*.md` entries covering the affected subsystem (list `docs/` and read only what the task touches; treat `docs/plans/` and `docs/mvp.md` as historical context, not system truth).
   - Existing architecture, conventions, nearby implementations, data models, routes, UI components, tests, and migrations relevant to the task.
   - Existing plans in `docs/plans/` if they relate to the same feature or subsystem.
3. Use read-only exploration while investigating. Do not make application-code changes.
4. Distinguish verified facts from assumptions. Cite concrete repository paths and, where useful, symbols or line ranges. Do not claim to have inspected files you have not read.
5. Check whether `docs/plans/` exists and determine the next `NN-` prefix as described under §5 (highest existing `NN-` in `docs/plans/` and `docs/plans/finished/` plus one); follow the repository's established plan conventions otherwise.

### 2. Identify gaps and ask clarification questions

Before writing the final plan, identify ambiguities that could materially change implementation, behavior, scope, data integrity, security, compatibility, or acceptance tests.

Classify each gap:
- **Blocking**: a decision is required before a reliable implementation plan can be produced.
- **Non-blocking**: a reasonable default is safe; document it as an assumption and invite correction.
- **Out of scope**: potentially relevant, but not needed for the requested outcome; do not expand scope without approval.

Ask questions in small, coherent batches. Prefer a short numbered list. Each question must:
- Explain the decision briefly when the consequence is not obvious.
- Be specific and answerable.
- Offer a recommended default where useful, without steering the user deceptively.
- Avoid asking for information already present in the request, repository, or earlier answers.

Prioritize high-impact questions. Do not ask every imaginable question. For minor choices, use established project conventions and record the assumption. If a blocking question remains, stop and wait for the user's answer rather than pretending the plan is implementation-ready. You may provide a brief provisional outline, clearly marked as provisional, but do not save it as a final plan unless the user asks for that.

After the user answers, inspect any newly relevant code or documentation and repeat the gap check. Continue until all blocking questions are resolved or the user explicitly asks you to proceed with documented assumptions.

### 3. Design the implementation

Build the plan from the clarified requirements and verified codebase. Ensure that it is:
- **Specific**: name files and components to create, modify, or remove wherever repository evidence supports doing so.
- **Sequenced**: order tasks by dependencies; make prerequisites explicit.
- **Actionable**: each step describes a concrete change, not a vague instruction such as “implement the backend”.
- **Verifiable**: include tests and observable acceptance criteria.
- **Scoped**: separate required work from optional improvements; avoid unrelated refactors.
- **Safe**: address authorization, validation, privacy, data migration, backwards compatibility, failure handling, and rollback when relevant.
- **Honest about uncertainty**: mark inferred file paths, unverified assumptions, and unresolved decisions clearly.

Do not invent filenames, APIs, schemas, framework capabilities, or existing behavior. If exact implementation details depend on exploration that has not yet happened, include a targeted investigation step rather than asserting a false fact.

For non-trivial work, consider:
- Current behavior and desired behavior.
- Architecture and data flow.
- API contracts and validation.
- Persistence and migrations.
- UI/UX states, errors, and accessibility.
- Authentication, authorization, tenant isolation, and security boundaries.
- Logging, observability, and operational behavior.
- Unit, integration, end-to-end, regression, and manual tests as appropriate.
- Deployment, feature flags, rollout, data backfill, and rollback where applicable.

### 4. Review plan completeness

Before saving, check that:
- Every user requirement maps to at least one planned step or acceptance criterion.
- Acceptance criteria are testable and not merely restatements of the implementation.
- Task order and dependencies make sense.
- The first implementation step creates a new Git branch named `<type>/<NN>-<plan-slug>` from `dev` before any code changes and commits the plan document as the first commit.
- Every step commits its own changes once its verification passes.
- No step wipes the database or drops tables; no step uses `php artisan migrate:fresh` (use `php artisan migrate`, or `php artisan migrate:refresh` when a reset is genuinely needed).
- The last implementation step updates `## Plan status` to `Implemented` once its verification passes, then moves the numbered plan document to `docs/plans/finished/` with `git mv` and commits the move (status update and move may share one commit).
- Tests cover success, relevant edge cases, and failure paths.
- Open questions are either resolved or explicitly marked as blockers.
- Assumptions and decisions are distinguishable from verified facts.
- No implementation work has been performed.
- The plan is appropriately sized for the task; do not inflate a small fix into a large project.

If a blocker remains, return to clarification instead of saving a final plan.

### 5. Save the plan

Once the blocking questions are resolved, create `docs/plans/` if needed and save a Markdown file there.

Naming:
- Use a short, descriptive, kebab-case slug with a 2-digit ascending numeric prefix: `docs/plans/<NN>-<plan-slug>.md`, e.g. `docs/plans/09-city-building-mode.md`.
- Determine `<NN>` by listing `docs/plans/*.md` and `docs/plans/finished/*.md` (plus numbered directories `docs/plans/*/` and `docs/plans/finished/*/`) and taking the highest leading `NN-` prefix found; next number is max + 1, zero-padded to at least 2 digits (`01`, `02`, … `09`, `10`). Legacy plans without a prefix do not count toward the max. If no numbered plan exists yet, start at `01`.
- If a matching plan already exists, read it first. Update it only if it clearly represents the same task and the user has asked to revise/continue it (keeping its existing number); otherwise choose a distinct slug with the next free number. Never silently overwrite unrelated work.
- Do not add dates to filenames unless the repository convention requires them.
- The branch name, sub-plan folder (see `split-plan` skill), archival target, and all path references use the same numbered slug: branch `<type>/<NN>-<plan-slug>`, folder `docs/plans/<NN>-<plan-slug>/`.

Use this template, omitting sections that genuinely do not apply:

# <Plan title>

## Goal
Describe the user-visible or technical outcome and why it is needed.

## Scope
### Included
- Explicit deliverables.

### Excluded
- Related work intentionally not included.

## Requirements and acceptance criteria
List confirmed requirements and observable, testable outcomes. Use checkboxes where useful.

## Current-state findings
Summarize relevant existing behavior and architecture. Link to concrete repository paths; label assumptions.

## Proposed approach
Explain the recommended design, key decisions, data/control flow, and why it fits the existing project.

## Implementation steps
The first step must always be creating a new Git branch before any implementation work, branched from `dev`. Never plan to implement directly on `dev`. Include this as a concrete step in the ordered list. Right after creating the branch commit this plan document as the first commit on the branch (include both in the branch step), so the plan travels with its implementation.

Never plan a database wipe or table deletion. `php artisan migrate:fresh` is forbidden in any step — it drops all tables. Use `php artisan migrate` for forward migrations, or `php artisan migrate:refresh` when a reset is genuinely needed.

The branch name must begin with the type of plan, followed by the numbered plan slug: `<type>/<NN>-<plan-slug>`. Use one of the types `feature`, `fix`, `refactor`, `update`, `chore`, `docs`, `test` — whichever describes the dominant kind of change (e.g. `git checkout -b feature/09-add-inventory dev`, `git checkout -b refactor/10-inventory-system dev`). If the plan mixes types, pick the dominant one and note the mix under Risks and assumptions.

The last step must always update `## Plan status` to `Implemented` and then archive the plan after all implementation and verification pass: edit the status first, then `git mv docs/plans/<NN>-<plan-slug>.md docs/plans/finished/<NN>-<plan-slug>.md` and commit the move (e.g. `git commit -m "docs: archive <NN>-<plan-slug> plan to finished"`; status update and move may share one commit). Include this as a concrete step in the ordered list. Do not leave the plan in `docs/plans/` once its work is done, and never leave a fully implemented plan as `Ready for implementation`.

Use ordered steps. For each step include:
- **Change:** concrete action.
- **Likely files:** paths to create or modify, based on repository evidence; mark uncertain paths as tentative.
- **Dependencies:** earlier steps or prerequisites, if any.
- **Verification:** tests or checks that demonstrate completion.
- **Commit:** commit the step's changes with a short message once its verification passes; no step ends with uncommitted work.

Keep each step independently understandable and small enough to execute and review. Avoid prescribing unnecessary code details when there is a simpler implementation choice.

## Data, API, and compatibility considerations
Include only relevant contracts, schema changes, migrations, versioning, and backwards-compatibility requirements.

## Security and failure handling
Include applicable authorization, validation, privacy, tenant isolation, error states, and recovery behavior.

## Testing and verification
List the test layers, concrete scenarios, relevant commands if verified from project configuration, and manual checks if needed. Do not invent commands.

## Rollout and rollback
Include when deployment, migration, feature flags, or operational risk makes this necessary.

## Risks and assumptions
Separate verified facts, assumptions, and remaining risks.

## Resolved decisions
Record important clarification questions and the user's answers when they affect implementation.

## Open questions
Write `None` if all blocking questions are resolved. Any remaining item must be clearly labeled **blocking** or **non-blocking**. A final plan must not contain unresolved blocking questions unless the user explicitly requested a provisional plan.

## Definition of done
Provide a concise checklist of completion conditions. Always include updating `## Plan status` to `Implemented` and the archival move (`docs/plans/<NN>-<plan-slug>.md` → `docs/plans/finished/<NN>-<plan-slug>.md`, committed) as the final items.

## Plan status
Use one of:
- `Ready for implementation`
- `Provisional — assumptions remain`
- `Implemented`

A plan is `Ready for implementation` only when no blocking questions remain and the steps are sufficiently concrete to execute. The implementing agent sets the status to `Implemented` after all definition-of-done items pass: edit `## Plan status` in the plan file first, then perform the archival `git mv` and commit (status update and move may share one commit). Never leave a fully implemented plan as `Ready for implementation`.

### 6. Report back

After saving, tell the user:
- The exact path of the plan (including the `NN-` prefix, e.g. `docs/plans/09-city-building-mode.md`).
- The goal and the main implementation stages in a short summary.
- The branch name (`<type>/<NN>-<plan-slug>`), created in step 1 from `dev` with the plan committed as the first commit, and that every step commits separately.
- That the last step sets `## Plan status` to `Implemented` and then archives the numbered plan to `docs/plans/finished/` and commits the move.
- Any assumptions or non-blocking open questions.
- Whether the plan is ready for implementation or provisional.
- If the plan is too large for a single agent to implement in one session (spans several subsystems or has no verifiable stopping point that fits one context window), suggest the user invoke the `split-plan` skill to break it into self-contained sub-plans. Do not invoke it yourself — it is user-invoked only.

Do not start implementation automatically. Wait for a separate, explicit user instruction to implement the plan.

## Interaction rules

- Be concise in conversation; put the detailed plan in the file.
- Ask one coherent batch of questions at a time, not an overwhelming questionnaire.
- Do not begin coding merely because the user supplied detailed specs.
- Do not claim tests pass; this skill does not implement the feature.
- If the repository cannot be inspected or the agent lacks write access, explain the limitation and provide the plan in the conversation without claiming it was saved.
- If the user explicitly asks to skip questions, proceed using conservative assumptions and mark the plan `Provisional — assumptions remain` when material uncertainty remains.
- Use the question tool for asking questions.
