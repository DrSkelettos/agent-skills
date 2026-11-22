---
name: split-plan
description: Break a plan that has grown too big for one agent into self-contained sub-plans, each implementable in a single session.
argument-hint: "Path to the plan to split [recommended]"
disable-model-invocation: true
---

# Split Plan

Split a plan written with `plan-spec` into **sub-plans**: self-contained implementation documents, each sized so one coding agent can implement it in one session and verify it on its own.

This skill splits plans only. Do not implement the planned changes, modify application code, install dependencies, or run migrations. The only intended writes are the sub-plan files under `docs/plans/<NN>-<plan-slug>/` (numbered folder derived from the parent plan filename, e.g. `docs/plans/09-city-building-mode/`), a short `## Sub-plans` section appended to the parent plan, and the `$PlansDirectory` default in `scripts/implement-plans.ps1`.

## Inputs

The plan to split, taken from (in order):

1. The path passed as an argument.
2. The plan most recently created or discussed in this conversation.

If neither identifies a plan, ask the user for the path. The plan must be a `plan-spec` plan (its "Implementation steps" open with a Git branch step). If it still contains blocking open questions, stop and tell the user to resolve them first: splitting freezes gaps into every sub-plan. Use the question tool for asking questions.

**Recommended shortcut:** if the invocation argument or prompt contains the standalone token `recommended` (case-insensitive, e.g. `@split-plan FILENAME recommended`), enter recommended mode: use all defaults with no questions — split-notify = yes, execution-notify = yes, review = no (auto-approve). Skip §0 entirely and never ask for approval in §3.

## When to split

Splitting adds overhead: duplicated context and ordering constraints between sub-plans. Split only when one agent could not implement the plan in a single session:

- The steps span several subsystems, packages, or applications.
- No contiguous run of steps ends in a verifiable state that fits one context window.
- A fresh implementer would not know where to start or what "done" means mid-plan.

If the plan is small enough to implement directly, say so and recommend implementing it as-is. Never split a small plan into ceremony.

## Workflow

### 0. Ask execution preferences first

Skip this section entirely in recommended mode (invocation contained `recommended`): use split-notify = yes, execution-notify = yes, review = no, and proceed directly to §1.

Otherwise, before doing anything else — before reading the parent plan, listing docs, or drafting the split — ask the user these execution preferences with the question tool (all default to yes, first option marked `(Recommended)`):

1. **Notify when split is finished?** (default: yes) — invoke the `ntfy-push` skill once the split itself is finished and ready for review (§7).
2. **Notify when plan execution is finished?** (default: yes) — add an instruction to the last sub-plan to invoke the `ntfy-push` skill once its implementation is finished (§4).
3. **Review the recommended breakdown?** (default: yes = review; no = auto-approve recommended) — yes keeps the current behaviour (§3: present the proposed slices and iterate until approved); no means accept the recommended slice sizes directly and skip confirmation.

Remember the answers for the rest of this run: the split-notify choice controls §7, the execution-notify choice controls §4 and the sub-plan template, the review choice controls §3.

### 1. Read the parent plan in full

Note the goal, scope (included/excluded), acceptance criteria, current-state findings, key decisions, constraints, open questions, and every implementation step. The parent plan stays the source of truth; sub-plans are slices of it and never rewrite it. Then list `docs/` and read the living docs covering the affected subsystem (`docs/documentation-guidelines.md` first for living-vs-historical rules, `docs/architecture.md` plus the relevant topic guides / `docs/specs/*.md`) as background context only.

### 2. Draft the split

Group the parent's implementation steps into consecutive slices, numbered in dependency order. Each slice must:

- **Deliver something verifiable**: when the slice is done, tests pass and some behaviour works end to end (or is observably complete). Prefer vertical slices over layer-by-layer stretches; horizontal groupings (schema, then UI) are acceptable when the parent plan is built that way and each slice still verifies green.
- **Fill one agent session**: each sub-plan should carry enough work to fill a single session — no more, no less. An over-large sub-plan defeats the purpose; an over-small one wastes a session on handover overhead. If a step or leftover group is too small to stand alone, fold it into the previous or next sub-plan (whichever it belongs with by dependency and subject matter) instead of giving it its own sub-plan. Only cut a step out on its own when it cannot fit in a session together with its neighbours.
- **Split oversized steps into sub-steps**: a single parent step that alone would not fit a session becomes several sub-steps inside the slice.
- **Declare dependencies**: each slice lists the earlier sub-plans that gate it. A slice with no blockers can start immediately.

Wide refactors are the exception to vertical slicing: one mechanical change whose blast radius fans across the codebase (renaming a shared symbol, retyping a column) cannot land green as a slice. Sequence it expand → migrate in batches → contract: add the new form beside the old, move callers over in batches with each batch its own sub-plan, delete the old form last.

Do not invent new requirements and do not drop existing ones. Splitting changes granularity, not scope. If you find a scope gap, raise it with the user instead of quietly absorbing it.

### 3. Confirm the breakdown with the user

Only when review = yes in §0 AND recommended mode is off. Present the proposed split as a numbered list. For each sub-plan show:

- **Title**
- **Parent steps covered** (e.g. "parent steps 2–3" or "parent step 5 split into 3 sub-steps")
- **What it delivers**: the verifiable outcome of the slice
- **Blocked by**: which other sub-plans must finish first

Ask whether the granularity, ordering, and dependency edges are right. Iterate until the user approves.

If review = no (user selected auto-approve, or recommended mode is on), this is a hard skip, not a soft preference:

- Do NOT present the breakdown for approval.
- Do NOT ask any permission question about the split (no question tool, no "shall I proceed?", no "does this look good?").
- Proceed directly to §4 with the recommended slices. The breakdown is reported only afterwards in §7.

### 4. Write the sub-plans

Create `docs/plans/<NN>-<plan-slug>/` (folder name equals the parent plan filename without `.md`, preserving its `NN-` prefix; never assign a new number here) and write one file per sub-plan, numbered from `01` in dependency order (blockers first): `docs/plans/<NN>-<plan-slug>/01-<sub-slug>.md`, `02-<sub-slug>.md`, … E.g. parent `docs/plans/09-city-building-mode.md` → folder `docs/plans/09-city-building-mode/` with `01-foundation.md`, `02-admin-seed.md`, …

- Use the sub-plan template below.
- Every sub-plan must be implementable without reading the other sub-plans: carry over all context, decisions, constraints, and acceptance criteria relevant to its slice. The parent link gives the full picture; it must not be required reading to start work.
- **The Git branch is not a sub-plan.** The parent's step 1 (create the branch) becomes step 1 of sub-plan 01 only: create `<type>/<NN>-<plan-slug>` from `dev` and commit the parent plan and all sub-plan files as well as the implementation script as the first commit. All later sub-plans implement on that same branch and say so explicitly; they must not create a branch of their own.
- **Never wipe the database or drop tables.** `php artisan migrate:fresh` is forbidden in any sub-plan — it drops all tables. Use `php artisan migrate`, or `php artisan migrate:refresh` when a reset is genuinely needed.
- Branch name: `<type>/<NN>-<plan-slug>` (e.g. `feature/09-add-inventory`), matching the parent plan's step 1. If the parent predates the numbered convention (branch step without `NN-` prefix or without a type prefix), adopt the numbered `<type>/<NN>-<plan-slug>` form (keeping the parent's existing `NN-` if present) and note the change in sub-plan 01.
- **Status update and archival: the last implementation sub-step(s) of the last sub-plan only.** After all verification passes, set `## Plan status` to `Implemented` in the parent plan and in every sub-plan file not already marked so (at minimum the last sub-plan and the parent; earlier slices already marked `Implemented` by their own implementers stay untouched), then move both the parent plan and the sub-plan folder to `docs/plans/finished/` with `git mv` and commit the move (e.g. `git commit -m "docs: archive <NN>-<plan-slug> plan to finished"`). Status edits and the move may share one commit. No earlier sub-plan archives anything or touches the parent plan's status.
- **Each non-last sub-plan ends with its own status update.** After its slice verification passes, its implementer sets that sub-plan file's `## Plan status` to `Implemented` and commits the change (may share the final sub-step's commit). It must not touch sibling sub-plans or the parent plan.
- **Execution-complete notification goes after archival, last sub-plan only when opted in.** If the user opted into execution-complete notification in §0 (the default), the last sub-plan ends with a final notify sub-step after the archival sub-step: invoke the `ntfy-push` skill as `Task Completed` for the finished plan execution. No earlier sub-plan notifies.
- Keep the parent step shape inside sub-steps: **Change**, **Likely files**, **Dependencies**, **Verification**, **Commit**. Every sub-step commits its own changes once its verification passes; the final archival sub-step commits the move.

### 5. Update the parent plan

Append a `## Sub-plans` section to the parent plan: the branch name and each sub-plan in order with a one-line summary and a relative link (`<NN>-<plan-slug>/01-<sub-slug>.md`, e.g. `09-city-building-mode/01-foundation.md`). Change nothing else in the parent plan.

### 6. Point the implementation script at the sub-plans

Set the `$PlansDirectory` default in the `param` block of `scripts/implement-plans.ps1` to the new numbered sub-plan directory, keeping the existing `Join-Path $PSScriptRoot` form:

```powershell
[string] $PlansDirectory = (Join-Path $PSScriptRoot '..\docs\plans\<NN>-<plan-slug>'),
```

E.g. `(Join-Path $PSScriptRoot '..\docs\plans\09-city-building-mode')`.

Change only that default. Leave `$Model` and the rest of the script untouched. If `scripts/implement-plans.ps1` does not exist, skip this step and say so in the report.

### 7. Report back

Tell the user:

- The sub-plan paths in implementation order and what each delivers (e.g. `docs/plans/09-city-building-mode/01-foundation.md`, …).
- The branch name, and that it is created in sub-plan 01 from `dev`.
- The dependency edges between sub-plans — what can start immediately.
- That the last sub-plan ends with setting `## Plan status` to `Implemented` (own file plus parent), archiving the numbered parent plan and the numbered sub-plan folder to `docs/plans/finished/` and committing the move.
- That `scripts/implement-plans.ps1` now defaults `$PlansDirectory` to `docs/plans/<NN>-<plan-slug>/` (or that it was skipped).
- Any assumptions or scope questions the split surfaced.

If the user opted into split notifications in §0 (the default), invoke the `ntfy-push` skill after reporting, as `Task Completed` for the finished split. This notification is for the split itself being done, not for plan execution.

Do not start implementation automatically. Wait for a separate, explicit user instruction to implement a sub-plan.

## Interaction rules

- Be concise in conversation; the detail belongs in the sub-plan files.
- Do not implement code while splitting; this skill only writes the sub-plan files, the parent plan's `## Sub-plans` section, and the `$PlansDirectory` default in `scripts/implement-plans.ps1`.
- If the repository cannot be inspected or you lack write access, explain the limitation and provide the breakdown in the conversation without claiming it was saved.

## Sub-plan template

Omit sections that genuinely do not apply.

<sub-plan-template>

# <NN>: <Sub-plan title>

## Parent plan

`docs/plans/<NN>-<plan-slug>.md` — *<Plan title>*. It is the source of truth for the goal, full scope, and background. Implement only this slice.

## Branch

- **Sub-plan 01:** step 1 creates `<type>/<NN>-<plan-slug>` from `dev` (e.g. `git checkout -b <type>/<NN>-<plan-slug> dev`) and commits the parent plan, the updated implement script, and all sub-plan files as the first commit.
- **Later sub-plans:** implement on `<type>/<NN>-<plan-slug>`, created in sub-plan 01. Verify you are on it before starting; do not create a new branch.
- **Never wipe the database or drop tables.** `php artisan migrate:fresh` is forbidden. Use `php artisan migrate`, or `php artisan migrate:refresh` when a reset is genuinely needed.

## What this sub-plan delivers

The verifiable end-to-end outcome of this slice, from the user's perspective.

## Blocked by

Sub-plan 01 — or "None (can start immediately)".

## Scope of this slice

### Included

- The parent plan steps covered by this sub-plan, and the deliverables they produce.

### Excluded

- Nearby work owned by other sub-plans. Do not touch it here.

## Acceptance criteria covered here

- [ ] The parent plan's acceptance criteria this slice satisfies (verbatim where possible).

## Context and decisions

Everything needed to implement this slice without re-deriving it: relevant current-state findings, key decisions, conventions, and constraints from the parent plan, plus anything new the split surfaced. Cite concrete repository paths and the living-doc paths consulted; label assumptions.

## Implementation sub-steps

Ordered. For each sub-step:

- **Change:** concrete action.
- **Likely files:** paths to create or modify, based on repository evidence; mark uncertain paths as tentative.
- **Dependencies:** earlier sub-steps or sub-plans, if any.
- **Verification:** tests or checks that demonstrate completion.
- **Commit:** commit the sub-step's changes with a short message once its verification passes; no sub-step ends with uncommitted work.

In the last sub-plan only, add final status-update and archival sub-steps after all verification passes:

- **Change:** set `## Plan status` to `Implemented` in the parent plan (`docs/plans/<NN>-<plan-slug>.md`) and in this sub-plan file (plus any sibling sub-plan file not already marked so), then move the parent plan and the sub-plan folder to `docs/plans/finished/` (`git mv docs/plans/<NN>-<plan-slug>.md docs/plans/finished/<NN>-<plan-slug>.md` and `git mv docs/plans/<NN>-<plan-slug>/ docs/plans/finished/<NN>-<plan-slug>/`).
- **Verification:** every sub-plan file and the parent plan show `## Plan status` `Implemented`; both paths exist under `docs/plans/finished/` and nothing for this plan remains in `docs/plans/`.
- **Commit:** commit the status updates and the move together (e.g. `docs: archive <NN>-<plan-slug> plan to finished`).

In every non-last sub-plan, add a final status-update sub-step after all verification passes:

- **Change:** set that sub-plan file's `## Plan status` to `Implemented`. Do not touch sibling sub-plans or the parent plan.
- **Verification:** the sub-plan file shows `Implemented`; slice acceptance criteria and checks pass.
- **Commit:** commit the status update (may share the final sub-step's commit); no sub-step ends with uncommitted work.

In the last sub-plan only, when execution-complete notification was opted in (§0), add a final notify sub-step after the archival sub-step:

- **Change:** invoke the `ntfy-push` skill as `Task Completed` for the finished plan execution.
- **Verification:** notification send attempted (failures swallowed, workflow continues regardless).
- **Commit:** none — no file changes; do not amend the archival commit for this.

## Testing and verification

The test layers, concrete scenarios, and commands for this slice (use only commands verified from the repository), plus manual checks if needed.

## Definition of done

- [ ] Acceptance criteria above are met.
- [ ] Tests and checks for this slice pass.
- [ ] Work is committed to `<type>/<NN>-<plan-slug>`.
- [ ] This sub-plan's `## Plan status` is set to `Implemented` and committed.
- [ ] (Last sub-plan only) Parent plan's `## Plan status` is set to `Implemented`, then numbered parent plan and numbered sub-plan folder are archived to `docs/plans/finished/` and the move is committed.
- [ ] (Last sub-plan only, when opted in) `ntfy-push` invoked as `Task Completed` for the finished plan execution.

## Plan status

Use one of:

- `Ready for implementation`
- `Provisional — assumptions remain`
- `Implemented`

The implementing agent sets this sub-plan's status to `Implemented` after its definition-of-done items pass and commits the change (may share the final sub-step's commit). The last sub-plan's implementer additionally sets the parent plan's status to `Implemented` before the archival `git mv`. Never leave a fully implemented sub-plan (or the parent plan, once all slices are done) as `Ready for implementation`.

</sub-plan-template>
