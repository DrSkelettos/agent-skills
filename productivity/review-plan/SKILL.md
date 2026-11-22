---
name: review-plan
description: Review the implementation of a complete plan-spec plan including all its split-plan sub-plans — coverage, cross-slice integration, and end-to-end verification. Use when the user asks to review a full plan implementation or says all sub-plans are done. Report-only; never fixes code.
argument-hint: "Path to the parent plan (e.g. docs/plans/<slug>.md)"
disable-model-invocation: true
---

# Review Plan

Review a complete plan implementation after all its `split-plan` sub-plans were implemented. This skill is review-only: do not edit application code, do not fix findings, do not write new plans, and do not archive anything. The only output is a review report in the conversation.

Use `review-subplan` instead for a single slice in isolation. This skill checks everything `review-subplan` checks per slice, plus the integration layer only a whole-plan view can catch: coverage gaps, overlaps, interface mismatches, ordering violations, and end-to-end behavior across slices.

## Inputs

The parent plan to review, taken from (in order):

1. The parent plan path passed as an argument (e.g. `docs/plans/<plan-slug>.md`, or `docs/plans/finished/<plan-slug>.md` after archival).
2. The plan most recently implemented or discussed in this conversation.

If neither identifies a plan, ask the user for the path with the question tool. Read the parent plan in full before reviewing. If the file cannot be read, stop and say so.

Then load all sub-plans:

- If the parent has a `## Sub-plans` section, treat it as the manifest and read every listed sub-plan in dependency order.
- Otherwise discover `docs/plans/<plan-slug>/*.md` (or `docs/plans/finished/<plan-slug>/*.md` when archived) sorted by filename and read each in full.
- If no sub-plan directory exists, the plan was small enough to implement as-is (per `split-plan`): review the parent's `Implementation steps` directly and say so in the report. Nothing else changes.

## Source of truth

Two truths, kept separate:

- The parent plan plus its sub-plans state what was **asked**: goal, scope, every requirement and acceptance criterion, key decisions, and each slice's definition of done.
- The current working tree (including uncommitted changes) states what was **built**: read the changed code end to end, never trust `Likely files` alone.

If the plan and the code disagree about what exists, the code wins for facts about the implementation; the plans win for whether the implementation satisfies the request. Every finding must trace to code read in this session (paths plus symbols or line ranges) or to a named plan section. Do not present plan content as fact about the codebase.

## Workflow

### 1. Build the coverage map

From the parent plan, list every requirement and acceptance-criterion checkbox, plus scope `Included` / `Excluded`. For each item record:

- Owning sub-plan(s) per the `## Sub-plans` manifest and each slice's `Acceptance criteria covered here`.
- Status: which slice claims it, and whether any item is owned by no slice (gap) or by two slices with conflicting intent (overlap).

Gaps and overlaps are findings against the whole plan even when every individual slice looks green in isolation.

### 2. Determine the actual change set

1. Current branch: `git branch --show-current` — must be the parent's `<type>/<plan-slug>` (step 1 of the parent, step 1 of sub-plan 01). A wrong branch is a blocking finding.
2. Working tree: `git status --short` — uncommitted work counts. Review it; flag required work left uncommitted.
3. History: `git log --oneline -30` (or enough to cover the branch) — expect the plan commit first, then one commit per sub-step in dependency order, and the archival move (`git mv` to `docs/plans/finished/`) only as the last sub-step of the last sub-plan. Archival in any earlier slice, a missing plan commit, or implementation commits before the branch step are findings.
4. Diff: resolve the default branch first (`git remote show origin`, falling back to local `main`/`master`), then `git diff <merge-base>...HEAD` for the full branch. This is the integration surface: every slice's files plus their interactions.
5. Never run anything that modifies state: no migrations, no `migrate:fresh` (forbidden anywhere — use `migrate`), no installs, no code edits.

### 3. Review per slice, then integration

For each sub-plan in dependency order, apply the `review-subplan` lens in compressed form: acceptance items met / partial / missing, sub-steps done, scope respected (no untouched `Excluded` work, no creep into sibling slices), slice verification present. Summarize per slice — do not repeat the full per-slice report when a `review-subplan` pass already exists; cite it and focus on what changed since.

Then check what per-slice review cannot:

- **Interfaces between slices**: APIs, services, schemas, or UI contracts created in one slice used as documented in the next (e.g. service method, migration column, session payload shape, bootstrap field). Mismatched names, shapes, or units across slices are blocking.
- **Ordering**: a slice relying on a later slice's work, or a `Blocked by` edge violated in the commit order.
- **Shared concerns**: authorization re-checked at every save path, funds/ledger atomicity across the whole transaction (not just one slice's happy path), lock enforcement not bypassable via another slice's edit path, migrations jointly guarded with `down()` rollbacks.
- **No duplication or contradiction**: the same behavior implemented twice with different rules, or two slices describing one fact differently in code.
- **Archival correctness**: nothing archived early; when the last slice claims completion, both parent and sub-plan folder moved via `git mv` and committed — otherwise note `archival pending` as expected, not as failure.

### 4. Verify end to end where cheap

Prefer inspection plus the narrowest execution covering the affected areas:

- `php artisan test --compact <affected paths>` using only paths/commands already present in the repo or plans. Never invent commands.
- `vendor/bin/pint --test` for a read-only style check (never `--format agent` in review — that modifies files).
- `npm run build` only when the plan touches JS/Blade and a build proves compilation.
- Node unit tests via the repo's existing runners only when the plan touches `tools/` or the game client/server.

Report every command run and its result. If a check cannot run, mark it `unverified — <reason>`, never `passing`. Run the narrowest set that covers the change; ask the user to run the complete suite (`php artisan test --compact`) on final approval per project test rules.

### 5. Classify every finding

- **Blocking**: parent acceptance criterion with no owning slice or no implementation, implemented behavior contradicting the parent with no justification, cross-slice interface mismatch, auth/validation/funds/atomicity gap on any end-to-end path, data-loss or migration risk, forbidden `migrate:fresh`/wipe, verification failing or absent for promised behavior, wrong branch, premature or missing archival move when the plan claims completion.
- **Non-blocking**: style or convention nit, missing edge-case test with low risk, minor deviation with equivalent outcome, docblock or living-docs wording improvement.
- **Out of scope**: parent `Excluded` work correctly untouched (confirm, do not flag), or behavior outside the plan entirely — note it, do not expand scope.

Keep the list tight. Prioritize findings that change behavior, data integrity, security, funds/ledger correctness, or acceptance.

### 6. Report the verdict

Report in the conversation (do not save a file):

- **Verdict**: one of `Approved`, `Approved with non-blocking notes`, or `Needs fixes` — for the plan as a whole.
- **Plan**: parent path, sub-plan paths in dependency order, branch (expected vs. actual), archival state (`in progress` vs. `archived to finished/`).
- **Evidence**: commits inspected, diff base, commands run with results, files read.
- **Coverage map**: each parent acceptance item → owning sub-plan(s) → met / partial / missing / unverified, with file evidence.
- **Per-slice status**: one line per sub-plan (approved / needs fixes with slice reference), plus any slice never implemented.
- **Cross-slice issues**: interface, ordering, duplication, atomicity, and archival findings that no single-slice review would catch.
- **Blocking issues**: numbered, each with plan section reference, file/line evidence, why it blocks, and a concrete fix suggestion.
- **Non-blocking notes**: short list with fix suggestions.
- **Suggested next step**: e.g. "fix items 1–3, then re-invoke `review-plan` with `<parent path>`" or "no fixes needed — safe to run `sync-docs` for the touched subsystems" or "archival pending: complete the last sub-plan's move step and commit".

## Interaction rules

- Be concise in conversation; the report is the deliverable.
- Review-only: do not edit code, docs, or plans, and do not perform the archival move. Do not produce fixed code unless the user explicitly asks for implementation after the review — then apply only the agreed findings.
- Do not start new implementation work. Wait for a separate, explicit instruction.
- Do not claim tests pass that were not executed in this session; do not claim behavior in files not read.
- Use the question tool only when blocked on an ambiguity you cannot resolve from the plans or working tree (e.g. parent path unknown, sub-plan manifest contradicts the directory, diff base unresolvable). For minor points, record an assumption instead of asking.
