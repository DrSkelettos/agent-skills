---
name: implement-plan
description: Implement a single plan-spec plan or split-plan sub-plan exactly as written, including git branch management, verification, and commits. Use when the user asks to implement or execute a plan or sub-plan.
argument-hint: "Path to the plan or sub-plan file (e.g. docs/plans/<NN>-<slug>.md)"
disable-model-invocation: true
---

# Implement Plan

Implement one `plan-spec` plan or one `split-plan` sub-plan exactly as written. The plan is the source of truth for what to build and in which order. Do not redesign, re-scope, or skip steps.

## Inputs

The plan to implement, taken from (in order):

1. The plan/sub-plan path passed as an argument.
2. The plan/sub-plan most recently created or discussed in this conversation.

If neither identifies a file, ask the user for the path with the question tool. Read the file in full before doing anything else. If it is a sub-plan, also read its `## Parent plan` link for goal, scope boundaries, and shared decisions — but implement only this slice.

If the file still contains blocking open questions, stop and ask the user to resolve them first. Never implement around a blocker by guessing.

## Workflow

### 1. Git setup first, exactly as the plan says

- Full plan: step 1 creates `<type>/<NN>-<plan-slug>` from `dev` (e.g. `git checkout -b feature/09-add-inventory dev`) before any code changes, then commits the plan document as the first commit.
- Sub-plan 01: step 1 creates `<type>/<NN>-<plan-slug>` from `dev` and commits the parent plan, all sub-plan files, and the implementation script as the first commit.
- Later sub-plans: implement on `<type>/<NN>-<plan-slug>` created in sub-plan 01. Verify with `git branch --show-current` before starting; do not create a new branch.
- Never implement directly on `dev` or `main`. If already on the wrong branch, stop and ask before moving work.

### 2. Execute the steps in order

Follow `Implementation steps` (full plan) or `Implementation sub-steps` (sub-plan) top to bottom:

- **Change** exactly what the step says; stay inside its scope and its `Included` list. Do not touch `Excluded` work, sibling sub-plans, or unrelated refactors.
- **Likely files** are hints, not truth: read the actual code paths before editing and follow existing patterns in `AGENTS.md` and the living docs.
- **Verification** must actually run. Use only commands the repo or plan provides. Never claim tests pass without running them; if a check cannot run, report it as `unverified — <reason>`.
- **Commit** once per step after its verification passes, with a short message. No step ends with uncommitted work. The final archival step commits the move.

### 3. Ask instead of guessing

If anything is unclear, stop and ask with the question tool. This includes:

- An ambiguous, missing, or contradictory step, file path, or acceptance criterion.
- Code that contradicts the plan with no obviously correct resolution.
- A failing verification where the fix would change the plan's intent or scope.
- Any choice that affects behavior, data integrity, auth, migration safety, or rollout.

Ask in one small batch, explain why each question blocks progress, and offer a recommended default where one exists. Wait for the answer. For trivial wording or style points, record the assumption in the commit message instead of asking.

### 4. Forbidden

- `php artisan migrate:fresh`, table wipes or drops.
- Skipping, reordering, or merging steps to save time.
- Adding requirements, expanding scope, or "improving" nearby code.
- Archiving early: only the full plan's last step (or the last sub-plan's last sub-steps) sets `## Plan status` to `Implemented` and moves files with `git mv` to `docs/plans/finished/`. Non-last sub-plans only set their own file's status to `Implemented` and never touch the parent or siblings.

### 5. Finish and report

Complete the plan's own status/archival step, then report in the conversation:

- Branch (expected vs. actual), commits made, files touched.
- Each acceptance criterion: met / partial / missing / unverified, with evidence.
- Commands run and results.
- Any deviations from the plan with justification, or `None`.
- Suggested next step (e.g. "ready for `review-plan` / `review-subplan`" or "next sub-plan in dependency order").

Do not start another plan or sub-plan automatically. Wait for a separate, explicit instruction.
