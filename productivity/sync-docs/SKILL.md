---
name: sync-docs
description: Review and maintain living documentation after an implementation phase so it matches what the codebase actually does. Use when the user finishes a development plan or branch, or asks to sync, update, correct, or clean up docs.
argument-hint: "Finished plan path or branch summary (optional)"
disable-model-invocation: true
---

# Sync Docs

Bring the living documentation back in line with the implementation after a development phase. This skill is maintenance-only: it updates existing docs, it does not implement features, change application code, or write new plans. The only intended writes are targeted edits to living docs under `docs/`.

## Inputs

The completed work, taken from (in order):

1. The plan or branch summary passed as an argument (e.g. `docs/plans/finished/<plan-slug>.md`).
2. The plan or branch most recently implemented or discussed in this conversation.
3. The current Git state (`git status`, `git log`, `git diff`) when no plan is named.

If none identifies the work, ask the user what was implemented. Read any named plan in full before starting, but treat it as context only (see Source of truth).

## Source of truth

The actual current state of the codebase is the sole source of truth — never the original implementation plan.

- The plan explains intended scope and helps locate the affected subsystem. It does not describe what was actually built.
- Additional changes may have landed on the same branch after the plan was implemented. The final code may differ from what the plan describes.
- Independently inspect the current implementation: read the changed files, follow callers and call sites, check migrations, routes, components, and configs. Cite concrete paths.
- Every documentation decision must reflect what is actually implemented. If the plan and the code disagree, the code wins. If the code is ambiguous, read more code; do not fall back to plan assertions.
- Do not claim behavior you have not verified in the current working tree (including uncommitted changes).

## Documentation guidelines and architecture

Read `docs/documentation-guidelines.md` before editing. It defines living vs. historical docs, writing rules, and the authoritative architecture snapshot.

## Philosophy: docs are a knowledge base for AI agents

The audience is a future AI agent that must extend or refactor the system without breaking it.

- Optimize for decision speed: constraints, conventions, dependencies, and non-obvious traps for each major system.
- Document what changes implementation choices: ownership boundaries, authorization patterns, validation authority (client hint vs. backend authoritative), atomicity requirements, invalidation flows, lookup and accessor conventions.
- Avoid documentation bloat. Do not document every class, method, file, or minor change. If a detail is obvious from the code and carries no architectural consequence, leave it out.
- Prefer updating an existing section over adding a new one, and deleting or merging over keeping stale parallels.

## Workflow

### 1. Establish scope and read canonical context

1. Restate the implemented change in one or two sentences, based on the user's pointer.
2. Read `docs/documentation-guidelines.md`, then the docs most likely affected (see step 3).
3. Note the subsystem: Laravel app, game server, game client, database, OSM/tile pipeline, banking, city/company systems, or a cross-cutting flow.

### 2. Inspect the actual implementation

1. Determine the real change set: `git status`, recent commits, and diff against the default branch. Include uncommitted work.
2. Read the changed code end to end — not just the plan's "likely files". Follow the full path: migration → model → authorization → route/controller or room handler → UI or client sync → invalidation or side effects.
3. List verified facts with paths: what was added, changed, or removed, and what stayed the same. Mark anything inferred but unverified as an assumption and verify it before documenting it.
4. Note follow-up changes on the same branch that the plan does not mention. These still count.

### 3. Inventory docs and map impact

1. List living docs under `docs/` (`architecture.md`, topic guides, `specs/*.md`) and note which subsystem each covers.
2. For each doc, decide: directly affected, indirectly affected (a boundary or dependency changed), or unaffected.
3. Check for duplication: if the same behavior is described in two places, note the canonical home and the redundant copy.
4. Skip unaffected docs entirely. Do not touch historical plans.

### 4. Decide the doc action per affected doc

For each affected doc, choose exactly what is needed:

- **Update**: existing section describes the system but contradicts the implementation (wrong flow, path, owner, validation rule).
- **Extend**: implementation introduces a new concept, constraint, or system with long-term value that no doc covers.
- **Correct**: small factual fix (renamed route, moved file, changed default) that would mislead an implementer.
- **Remove or consolidate**: content is obsolete, redundant, or irrelevant after the change. Delete it or merge it into the canonical home. Never leave two competing descriptions.
- **Leave untouched**: change is minor, self-evident from code, or has no long-term decision value.

Apply the long-term-value filter aggressively: if a future agent would implement correctly without this sentence, do not write it. If the sentence prevents an architectural violation, keep it.

### 5. Apply changes directly

1. Edit the living docs in place. Keep changes tight: update the affected section, add the missing constraint, delete or merge the stale part.
2. Preserve doc structure and tone. Match surrounding headings, code-fence style, and terminology.
3. Cross-link instead of copying: one authoritative description, short references elsewhere.
4. Do not rewrite historical plans, do not create new top-level doc files without user approval, and do not implement code changes as a side effect.
5. Keep the diff reviewable: one focused edit per doc section, no drive-by reformatting.

### 6. Verify and report back

1. Re-read every edited section and confirm it matches the inspected code and introduces no contradiction with the canonical references in `docs/documentation-guidelines.md`.
2. Confirm no duplication remains between the edited docs.
3. Tell the user:
   - Which docs were inspected and which were changed (with paths).
   - For each change: update / extend / correct / remove-or-consolidate, in one line with the reason.
   - Which docs were deliberately left untouched and why.
   - Any stale or contradictory content found that was left alone (and why), plus anything that needs a user decision.
4. Do not start new implementation work. Wait for a separate instruction.

## Interaction rules

- Be concise in conversation; the detail belongs in the doc edits.
- Make the doc edits yourself. Do not produce a review-only report unless you lack write access — in that case, explain the limitation and provide exact proposed edits in the conversation.
- Never present plan content as fact. Every documented claim must trace to code you read in this session.
- Use the question tool when a docs decision hinges on user intent (e.g. whether an old spec is still the roadmap or should be retired). For minor wording, decide and move on.
- If the change is too small to justify any doc edit, say so and change nothing. No ceremony edits.
