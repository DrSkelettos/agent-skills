---
name: audit-docs
description: Perform a comprehensive, independent audit of the entire living documentation against the current implementation. Use when the user asks for a docs audit, health check, or full review. Report-only first; never edits without explicit approval.
disable-model-invocation: true
---

# Audit Docs

Audit the whole living documentation for accuracy, consistency, coverage, and maintainability. This skill is independent: it needs no implementation plan and is not scoped to a recent change. For a targeted post-implementation sync, use `sync-docs` instead.

This skill is report-only by default. Present findings, get explicit approval, then implement only what was approved. Never modify documentation during the initial audit.

## Inputs

No input required. Audit the documentation as a whole, regardless of when individual features were implemented or last documented.

- If the user names a focus area, treat it as a prioritization hint, not a scope limit: still audit everything, report the focus area first.
- Historical plans (`docs/plans/`, `docs/plans/finished/`), commit messages, and other development artifacts are context only. They never override the current implementation.

## Documentation guidelines

Read `docs/documentation-guidelines.md` before auditing. It is authoritative for both `sync-docs` and this skill. Do not introduce a separate documentation structure or competing conventions.

Same philosophy as `sync-docs`: docs are a practical reference for future AI coding agents.

- Optimize for decision speed: architectural constraints, system relationships, conventions, business logic.
- Document what changes implementation choices: ownership boundaries, authorization patterns, validation authority, atomicity, invalidation flows, dependencies.
- Remain concise. Do not document every class, method, or component. Skip details that are obvious from code and carry no architectural consequence.

## Source of truth

The actual current codebase is the primary source of truth.

- Verify in code which systems exist, how they are implemented, how they interact, which patterns and conventions are used, and which constraints and dependencies matter.
- Compare every documentation claim against the working tree, not against other docs.
- Do not flag documentation as outdated merely because it differs from historical plans. If the plan and the code disagree, the code wins.
- Distinguish verified problems from uncertainties. Do not report speculative issues as confirmed findings.

## Audit scope

Cover the entire application and its living docs:

- Docs: `docs/architecture.md`, topic guides such as `docs/osm.md`, `docs/specs/*.md` entries describing current systems. Never rewrite `docs/plans/` or `docs/plans/finished/`; `docs/mvp.md` only on explicit request.
- Code: `apps/web` (routes, Livewire, Filament, banking, city/company systems), `apps/game-server` (Colyseus rooms), `packages/game-client` (Leaflet/SVG views, Colyseus sync), migrations and PostGIS schema, tile/OSM pipeline.

### A. Accuracy and currency

- Outdated implementations, removed or renamed classes, models, routes, components.
- Documented behavior that no longer matches the code.
- Outdated architectural assumptions, constraints, dependencies, or integrations.
- Documented functionality that no longer exists.
- Architectural changes never reflected in docs.

### B. Consistency

- Contradictions between files; conflicting descriptions of the same system.
- Inconsistent terminology or competing architectural assumptions.
- Duplicated information that risks conflicting future updates.

### C. Coverage

- Major systems or important features with no documentation.
- Undocumented system interactions, constraints, conventions, or workflows.
- Sections too superficial to guide a modification safely.
- Focus on gaps that force unnecessary rediscovery or invite incorrect implementation. No per-class completeness goal.

### D. Relevance and maintainability

- Docs no longer useful; references to obsolete or abandoned concepts.
- Redundant, overlapping, or fragmented documents that should consolidate.
- Excessive implementation detail with no long-term decision value.

## Workflow

### 1. Read guidelines and inventory docs

1. Read the guidelines file above.
2. List every living doc and note which subsystem each covers.
3. Note known duplication and terminology variants up front.

### 2. Inventory the implementation

1. Enumerate the major systems actually present: Laravel app, game server rooms, game-client views, persistence vs. realtime ownership, banking, city/company, OSM/tile pipeline.
2. For each system, note entry points, authoritative validation, atomicity, and cross-system dependencies — from code, with paths.

### 3. Compare docs against code

1. Check each doc claim against the implementation. Follow callers, routes, migrations, and configs; do not trust doc-to-doc agreement.
2. Record evidence (file paths, symbols, behavior) for every finding.
3. Consolidate related issues with a common root cause into one finding.

### 4. Build the audit report — do not edit docs

Group findings into exactly these categories:

1. **Outdated Documentation** — needs correction or updating.
2. **Contradictions and Inconsistencies** — conflicting information.
3. **Missing Documentation** — important functionality or architecture not adequately covered.
4. **Redundancy and Cleanup** — consolidate, simplify, or remove.
5. **Documentation Coverage** — overall assessment per major system (covered / partial / missing).

For each finding provide:

- Title (short, descriptive).
- Affected file(s) and sections.
- Problem (concise).
- Evidence from the implementation (paths, actual behavior).
- Recommendation (concrete resolution).
- Importance: High, Medium, or Low.

Prioritize by impact on future development:

- High: incorrect architectural information likely to cause wrong implementation.
- Medium: missing or outdated information that makes extension unnecessarily hard.
- Low: minor inconsistency, redundancy, or organizational improvement.

Avoid trivial findings. Mark anything unverified as uncertain, not as a confirmed finding.

### 5. Present findings and ask approval

1. Present the structured report in the conversation. No doc edits yet.
2. Use the question tool: approve all, selected findings or categories, reject, or request further investigation. Approval of one finding is never approval of others.
3. Never modify documentation before explicit approval.

### 6. Implement approved changes only

1. Apply only the approved findings: corrections, additions, consolidations, removals.
2. Reflect the actual implementation; follow the guidelines file; no new duplication or contradictions.
3. Review the resulting docs for consistency; verify every approved finding is addressed.
4. Make no code changes. This skill covers documentation only.

### 7. Final summary

Report concisely:

- Findings addressed and files created, updated, consolidated, or removed.
- Findings left unresolved and why.
- Issues needing further investigation.

## Interaction rules

- Non-destructive by default: auditing and reporting never modify files.
- User-controlled changes: every doc edit requires explicit approval, scoped to the approved findings.
- Be concise in conversation; the report is the deliverable until approval.
- Never present plan, commit, or doc content as fact. Every claim traces to code read in this session.
- If the audit finds nothing worth changing, say so and change nothing.
