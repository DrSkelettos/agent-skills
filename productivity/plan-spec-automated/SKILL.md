---
name: plan-spec-automated
description: Run plan-spec, then split-plan with defaults, then ntfy-push on completion. Use when the user invokes plan-spec-automated or asks for fully automated planning from request to sub-plans with a completion notification. Do not implement the planned changes.
disable-model-invocation: true
---

# Plan Spec Automated

Fully automated planning pipeline. Chain three existing skills in order without extra user prompts between stages. This skill plans only: do not implement the planned changes, modify application code, install dependencies, run migrations, or make other product changes.

## Inputs

The user's feature request, bug report, or technical change, taken from (in order):

1. The arguments passed to this skill.
2. The request most recently described in this conversation.

If neither identifies a task, ask the user for it with the question tool, then continue.

## Workflow

Execute the stages strictly in order. Wait for each stage to finish before starting the next. Do not skip a stage and do not run stages in parallel.

### 1. Plan

Call the Skill tool with `plan-specs` (`plan-spec`) on the user's request.

- Follow that skill's workflow exactly, including its clarification questions and its plan template under `docs/plans/`.
- Capture the saved parent plan path when it finishes.
- If planning blocks on unanswered blocking questions, invoke `ntfy-push` once as `Input Required`, then wait for the user's answer.

### 2. Split with defaults

Call the Skill tool with `split-plan` on the parent plan path from §1.

Do not ask the §0 execution preferences — use these fixed answers (all defaults):

1. **Notify when split is finished?** → yes.
2. **Notify when plan execution is finished?** → yes — the last sub-plan ends with a notify sub-step after archival (§4 / sub-plan template).
3. **Review the recommended breakdown?** → no — accept the recommended slices directly and skip confirmation (recommended split size).

- If `split-plan` reports the plan is small enough to implement as-is, accept that verdict and continue to §3 without sub-plans.
- Capture the sub-plan paths (or the small-plan verdict) when it finishes.

### 3. Notify completion

Call the Skill tool with `ntfy-push` as `Task Completed` for the finished automated pipeline.

- Body states the parent plan path and, when created, the sub-plan directory.
- Never let a notification failure interrupt the workflow; continue regardless of the result.

### 4. Report back

Tell the user:

- The parent plan path and its goal in one or two sentences.
- Whether it was split (sub-plan paths in order) or kept as-is.
- That `scripts/implement-plans.ps1` now defaults to the sub-plan directory when a split happened (per `split-plan` §6).
- That the last sub-plan carries the execution-complete `ntfy-push` step after archival (per `split-plan` §4).
- That a pipeline completion notification was sent.

Do not start implementation automatically. Wait for a separate, explicit user instruction.

## Interaction rules

- Be concise in conversation; detail belongs in the plan and sub-plan files.
- Ask the user nothing between stages except what the invoked skills themselves require (e.g. `plan-spec` blocking questions).
- If the pipeline blocks waiting on the user, invoke `ntfy-push` as `Input Required` once for that blocking event, then wait.
- Send at most one pipeline completion notification per run (§3). This is separate from `split-plan`'s own split notification and from the future execution-complete notification embedded in the last sub-plan.
- Use the question tool for asking questions and the Skill tool for invoking `plan-specs`, `split-plan`, and `ntfy-push`.
