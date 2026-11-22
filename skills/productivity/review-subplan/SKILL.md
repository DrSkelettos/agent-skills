---
name: review-subplan
description: Review the implementation of a single split-plan sub-plan against its acceptance criteria, scope, and verification steps. Use when the user asks to review a sub-plan implementation, check a slice, or says a sub-plan is ready for review. Report-only; never fixes code.
argument-hint: "Path to the sub-plan file (e.g. docs/plans/<slug>/01-<slice>.md)"
disable-model-invocation: true
---

# Review Subplan

Review one implemented slice after a `split-plan` sub-plan was implemented. This skill is review-only: do not edit application code, do not fix findings, do not write new plans, and do not start the next sub-plan. The only output is a review report in the conversation.

Use `review-plan` instead when the user wants the whole plan (parent plus all sub-plans) reviewed including cross-slice integration.

## Inputs

The sub-plan to review, taken from (in order):

1. The sub-plan file path passed as an argument (e.g. `docs/plans/<plan-slug>/02-<sub-slug>.md`, or the `finished/` equivalent).
2. The sub-plan most recently implemented or discussed in this conversation.

If neither identifies a sub-plan, ask the user for the path with the question tool. Read the sub-plan file in full before reviewing. If the file cannot be read, stop and say so.

Also read the parent plan (`## Parent plan` link at the top of the sub-plan) for context on goal, scope boundaries, and shared decisions — but the sub-plan's own `Scope of this slice`, `Acceptance criteria covered here`, `Implementation sub-steps`, and `Definition of done` are the verdict boundary. Do not fail the slice for parent work owned by other sub-plans.

## Source of truth

Two truths, kept separate:

- The sub-plan states what was **asked**: scope, acceptance criteria, sub-steps, verification, definition of done.
- The current working tree (including uncommitted changes) states what was **built**: read the changed code end to end, never trust the plan's `Likely files` alone.

If the plan and the code disagree about what exists, the code wins for facts about the implementation; the plan wins for whether the implementation satisfies the request. Every finding must trace to code read in this session (paths plus symbols or line ranges) or to a named sub-plan section. Do not present plan content as fact about the codebase.

## Workflow

### 1. Establish expected scope

Note exactly what the slice must deliver:

- `What this sub-plan delivers`, `Blocked by` (which earlier sub-plans gate it).
- `Scope of this slice`: Included vs. Excluded (nearby work owned by other sub-plans).
- `Acceptance criteria covered here` (verbatim items — each becomes a row in the report).
- `Implementation sub-steps`: Change, Likely files, Dependencies, Verification, Commit per sub-step.
- `Testing and verification` and `Definition of done`.
- `Branch`: sub-plan 01 creates `<type>/<plan-slug>`; later sub-plans implement on that same branch and never create their own.

If the `Blocked by` dependency is not yet implemented, proceed anyway but flag the ordering risk explicitly.

### 2. Determine the actual change set

1. Current branch: `git branch --show-current` — must be the expected `<type>/<plan-slug>`. A wrong branch or a new branch created by a later sub-plan is a blocking finding.
2. Working tree: `git status --short` — uncommitted work counts as part of the implementation. Review it; flag required work left uncommitted.
3. History: `git log --oneline -15` — expect one commit per sub-step with a short message, plus the plan commit on sub-plan 01. Missing, squashed-together, or unrelated commits are findings (blocking only when they hide unverified work).
4. Diff: resolve the default branch first (`git remote show origin`, falling back to local `main`/`master`), then `git diff <merge-base>...HEAD` for the full branch. Filter to this slice: expected files touched vs. untouched, unexpected files touched outside the slice scope.
5. Never run anything that modifies state: no migrations, no `migrate:fresh` (forbidden anywhere — use `migrate`), no installs, no code edits.

### 3. Inspect the implementation end to end

Read the changed files fully — not just the plan's `Likely files`. Follow the slice's path (e.g. migration → model → authorization → service → route/Livewire or room handler → UI/client → tests). Follow callers and call sites of every changed symbol.

Check, only as it applies to this slice:

- Each acceptance criterion: met, partial, or missing, with evidence.
- Each sub-step: implemented as described or justifiably equivalent; deviations need a reason, not silence.
- Scope adherence: `Excluded` work or other sub-plans' files touched without need is scope creep (blocking when it changes behavior owned elsewhere).
- Authorization, validation, tenant isolation re-checked at save time; client verdict display-only.
- No hardcoded user-facing copy (lang files), Blade/Livewire/modal conventions per `AGENTS.md`, `DESIGN.md`, `docs/frontend.md` where the slice touches UI.
- Migrations guarded and additive with `down()`; no table wipes or drops.
- Tests named in the sub-step `Verification` exist and assert the slice's behavior (success plus relevant edge/failure paths), not just happy-path presence.

### 4. Run the slice's own verification where cheap

Prefer inspection plus the narrowest execution that covers the slice:

- `php artisan test --compact <slice paths> [--filter=...]` using only paths/commands already present in the repo or sub-plan. Never invent commands.
- `vendor/bin/pint --test` for a read-only style check (never `--format agent` in review — that modifies files).
- `npm run build` only when the slice touches JS/Blade and a build proves the change compiles.

Report every command run and its result. If a check cannot run (e.g. pgsql unavailable), mark the criterion `unverified — <reason>`, never `passing`. Do not run the full suite; the full sweep belongs to the last sub-plan and to `review-plan`.

### 5. Classify every finding

- **Blocking**: acceptance criterion missing or partial, implementation contradicts the sub-plan with no justification, auth/validation gap, data-loss or migration risk, forbidden `migrate:fresh`/wipe, required work uncommitted, slice verification failing or absent for promised behavior, wrong branch.
- **Non-blocking**: style or convention nit, missing edge-case test with low risk, minor deviation with equivalent outcome, wording or docblock improvement.
- **Out of scope**: belongs to another sub-plan, the parent's excluded list, or future work — note it, do not expand this slice to cover it.

Keep the list tight. Prioritize findings that change behavior, data integrity, security, funds/ledger correctness, or acceptance — not exhaustive copy-editing.

### 6. Report the verdict

Report in the conversation (do not save a file):

- **Verdict**: one of `Approved`, `Approved with non-blocking notes`, or `Needs fixes`.
- **Slice**: sub-plan path, parent plan path, branch (expected vs. actual).
- **Evidence**: commits inspected, diff base, commands run with results, files read.
- **Acceptance criteria**: each item as met / partial / missing / unverified, with file evidence.
- **Sub-steps**: each as done / partial / missing, including commit presence.
- **Scope adherence**: in-scope files handled, out-of-scope touches (if any).
- **Blocking issues**: numbered, each with sub-plan section reference, file/line evidence, why it blocks, and a concrete fix suggestion.
- **Non-blocking notes**: short list with fix suggestions.
- **Suggested next step**: e.g. "fix items 1–2, then re-invoke `review-subplan` with `<path>`" or "no fixes needed — safe to implement the next sub-plan in dependency order" or, for the last slice, "then invoke `review-plan` for the whole-plan integration check".

## Interaction rules

- Be concise in conversation; the report is the deliverable.
- Review-only: do not edit code, docs, or plans. Do not produce fixed code unless the user explicitly asks for implementation after the review — then apply only the agreed findings.
- Do not start the next sub-plan automatically. Wait for a separate, explicit instruction.
- Do not claim tests pass that were not executed in this session; do not claim behavior in files not read.
- Use the question tool only when blocked on an ambiguity you cannot resolve from the sub-plan, parent plan, or working tree (e.g. sub-plan path unknown, diff base unresolvable). For minor points, record an assumption instead of asking.
