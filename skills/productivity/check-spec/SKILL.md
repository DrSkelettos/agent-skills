---
name: check-spec
description: Review a single specification Markdown file for internal consistency, clarity, and completeness before planning. Use when the user asks to check, review, validate, or vet a spec, or says a spec should be ready for plan-spec.
compatibility: Works with repository-aware coding agents that can read Markdown documents.
metadata:
  version: "1.0.0"
---

# Check Spec

Give a fast, document-only verdict on whether a spec is ready to be passed to `plan-spec`. This skill is review-only: do not implement anything, do not write a plan, and do not rewrite the spec. The only output is a review report in the conversation.

## Inputs

The spec to check, taken from (in order):

1. The Markdown file path passed as an argument.
2. The spec most recently created or discussed in this conversation.

If neither identifies a spec, ask the user for the path. Read the spec file in full before reviewing. If the file cannot be read, stop and say so.

## Boundaries

- Review the spec document itself only. Do not perform the repository-wide exploration that `plan-spec` does: no codebase crawl, no architecture review, no verification of claims against code, migrations, routes, or UI components.
- The single exception is noting dangling references inside the spec (e.g. `XXX` placeholders, TODOs, paths or links that are named but not resolved). Flag them as spec defects; do not go resolve them in the codebase.
- Do not edit the spec file. Propose fixes as recommendations, and apply them only on explicit user request.
- Do not create a plan document and do not start implementation.

## Workflow

### 1. Read the spec end to end

Note the stated goal, scope, requirements, acceptance signals, constraints, terminology, and open items exactly as written. Quote or cite spec sections when reporting issues so the user can find them.

### 2. Check internal consistency

- Contradictions between sections (e.g. a requirement stated in one place and negated or altered in another).
- Terminology drift: the same concept called by different names, or one term used for different concepts.
- Numbering, cross-reference, and structural errors (broken section references, duplicated items, conflicting lists or tables).
- Conflicting rules for the same behavior (e.g. validation, authorization, data handling described differently in two places).

### 3. Check understandability

A `plan-spec` run must be able to turn this spec into tasks without guessing. Flag anything a fresh implementer could reasonably misread:

- Vague verbs or untestable adjectives ("fast", "user-friendly", "appropriate", "handle correctly") with no observable definition.
- Ambiguous actors, scope, or triggers (who does what, when, under which condition).
- Undefined domain terms or unexplained abbreviations.
- Placeholder or hand-wavy passages (`XXX`, `TBD`, "etc.", "as usual", "similar to X" without saying what carries over).

### 4. Check completeness

Do not demand a fixed template, but flag missing information that `plan-spec` would have to guess at or bounce back as blocking questions:

- Goal: is the user-visible or technical outcome stated?
- Scope: are included deliverables distinguishable from explicitly excluded work?
- Requirements: are functional behaviors, constraints, and non-goals concrete enough to derive acceptance criteria from?
- Acceptance signals: can success be observed or tested, or is it only restated effort?
- Edge cases and failure paths relevant to what the spec itself promises (validation failures, authorization denials, empty states, conflicts).
- Open decisions: are unresolved points marked as such, or silently left ambiguous?

Where the spec intentionally defers a detail to implementation or to `plan-spec` discovery, that is acceptable only if the spec says so explicitly. Otherwise flag it as missing.

### 5. Classify every finding

- **Blocking**: `plan-spec` cannot produce a reliable plan without this being fixed or decided (contradiction, untestable core requirement, missing scope boundary, unresolved decision on promised behavior).
- **Non-blocking**: worth fixing, but `plan-spec` can proceed with a documented assumption (minor ambiguity, missing nice-to-have detail, style or structure nit).
- **Out of scope**: potentially relevant but not needed for this spec's stated goal; do not expand scope, just note it.

Keep the list tight. Prioritize findings that change scope, behavior, data integrity, security, or acceptance — not exhaustive copy-editing.

### 6. Ask only if needed

If a blocking finding hinges on a decision only the user can make, ask a small, coherent batch of questions with the question tool: specific, answerable, each with a recommended default where useful. Do not re-ask anything the spec already answers. For minor points, record an assumption instead of asking.

### 7. Report the verdict

Report in the conversation (do not save a file):

- **Verdict**: one of `Ready for plan-spec`, `Ready with non-blocking notes`, or `Needs revision`.
- **Blocking issues**: numbered list, each with spec section reference, why it blocks planning, and a concrete fix suggestion.
- **Non-blocking notes**: short list with fix suggestions.
- **Missing / unclear**: grouped under consistency, understandability, completeness.
- **Suggested next step**: e.g. "fix items 1–3, then invoke `plan-spec` with `<spec path>`" or "no changes needed before `plan-spec`".

## Interaction rules

- Be concise in conversation; the report is the deliverable.
- Do not claim the spec matches or contradicts the codebase; this skill evaluates the document standalone.
- Do not rewrite the spec, create `docs/plans/` output, or start implementation.
- If the user explicitly asks to fix the spec after the review, apply only the agreed findings and keep edits minimal.
- Use the question tool for asking questions.
