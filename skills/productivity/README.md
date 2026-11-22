# Productivity

General workflow tools, not code-specific.

## User-invoked

Reachable only when you type them (Claude Code: `disable-model-invocation: true`; Codex: `policy.allow_implicit_invocation: false` in `agents/openai.yaml`).

- **[grill-me](./grill-me/SKILL.md)**: Get relentlessly interviewed about a plan or design until every branch of the design tree is resolved.
- **[handoff](./handoff/SKILL.md)**: Compact the current conversation into a handoff document so another agent can continue the work.
- **[split-plan](./split-plan/SKILL.md)**: Break a plan created with plan-spec that has grown too big for one agent into self-contained sub-plans, each implementable in a single session.
- **[review-subplan](./review-subplan/SKILL.md)**: Review the implementation of a single split-plan sub-plan against its acceptance criteria and scope. Report-only; never fixes code.
- **[review-plan](./review-plan/SKILL.md)**: Review the implementation of a complete plan-spec plan including all its sub-plans — coverage, cross-slice integration, end-to-end verification. Report-only; never fixes code.
- **[sync-docs](./sync-docs/SKILL.md)**: Review living docs after an implementation phase and sync them to what the codebase actually does (update, extend, correct, or remove).
- **[audit-docs](./audit-docs/SKILL.md)**: Audit the entire living documentation against the current implementation. Report-only first; edits only after explicit approval.
- **[init-docs](./init-docs/SKILL.md)**: Perform a comprehensive initial documentation pass over the entire application and establish the living-docs baseline from the current implementation.
- **[teach](./teach/SKILL.md)**: Teach the user a new skill or concept over multiple sessions, using the current directory as a stateful teaching workspace.
- **[to-questionnaire](./to-questionnaire/SKILL.md)**: Turn a decision you can't answer alone into a Markdown questionnaire for the one person who can (filled in async, or together over a meeting).
- **[wait-what](./wait-what/SKILL.md)**: Fire this the moment a message doesn't land. The agent re-pitches it with the context you're missing, in plain English, using your `GLOSSARY.md` vocabulary.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them).

- **[grilling](./grilling/SKILL.md)**: Interview the user relentlessly about a plan, decision, or idea until every branch of the design tree is resolved.
- **[writing-for-agents](./writing-for-agents/SKILL.md)**: Writing documents for agents: skills, AGENTS.md/CLAUDE.md, and any doc an agent reaches by a pointer.
