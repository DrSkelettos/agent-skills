# Documentation Guidelines

How to write and maintain living documentation in this repo. Referenced by the `sync-docs` and `audit-docs` skills. `AGENTS.md` is authoritative and overrides this file on any conflict.

## Canonical references

- `AGENTS.md` — monorepo layout, service boundaries, coding and realtime rules.
- `docs/README.md` — documentation map and canonical-reference pointers.
- `docs/overview/README.md` — repository topology, service boundaries, deployment model.
- `docs/overview/runtime-flows.md` — end-to-end request and event flows.
- `docs/gateway/channels-and-events.md` — canonical Socket.IO event and Redis channel reference for gateway-facing traffic.
- `apps/worker-mission/src/redis/channels.ts` — authoritative Redis channel and IPC message definitions.
- The implementation itself — Laravel routes, Livewire components, policies, Filament resources, gateway handlers, worker manager/process code, Prisma schema plus Laravel migrations.

## Living docs vs. historical records

- Living docs (in scope, must match code): everything under `docs/` except plans, i.e. `docs/README.md`, `docs/overview/`, `docs/web/`, `docs/gateway/`, `docs/worker-mission/`, and this file.
- Historical records (out of scope, do not rewrite): `docs/plans/*.md` and `docs/plans/finished/*.md` record what was intended at planning time. Leave them as-is; if the plan and the code disagree, the code wins and the living docs follow the code.

## How to write docs in this repo

- Structure docs around systems and decisions, not files: goal, responsibilities, boundaries, data flow, key constraints, failure modes.
- Write for implementers: concrete paths, commands, and contracts over prose. Link to code (`apps/web/app/...`, `apps/gateway/src/...`, `apps/worker-mission/src/...`) instead of pasting it.
- Keep one home per fact. Cross-link instead of duplicating. If two docs describe the same behavior, consolidate and leave a pointer. Current canonical homes:
  - event/channel surface → `docs/gateway/channels-and-events.md`
  - cross-app flows → `docs/overview/runtime-flows.md`
  - topology and infra → `docs/overview/README.md`
- Use the repo's vocabulary (missions, patients, traits and `trait_standards`, equipment/medication/infusion actions, mission rooms and `patient:{id}` rooms, manager vs. child worker processes, Redis bridging). Do not introduce competing terms.
- Treat cross-app contracts as first-class: websocket events, Redis channels, IPC messages, and persisted JSON shapes have producers and consumers in different apps — update producers, consumers, tests, and docs together.
- Follow existing doc tone: short sections, code fences for flows and commands, no hardcoded UI copy, no marketing language.
- Prefer updating an existing canonical doc before creating a new one. Never leave overlapping docs that disagree with each other.

## Architecture snapshot

Summary only — `AGENTS.md` and `docs/overview/` are authoritative.

```text
Browser (Blade + Livewire + Vite JS)
  -> Laravel web app (apps/web: auth, routes, policies, Filament, HTML)
  -> Socket.IO gateway (apps/gateway: auth, rooms, Redis bridging)
  -> Redis pub/sub
  -> worker-mission manager (spawns and supervises one child worker per mission)
  -> mission worker child process (authoritative simulation state, ticks, persistence)
  -> PostgreSQL shared by Laravel and Prisma (durable state store)
```

- Web owns auth, route authorization, admin/content management, and browser orchestration. It does not own simulation state.
- The gateway owns websocket transport, validation, and Redis bridging. It does not own simulation logic or persistent data.
- The worker owns authoritative simulation state and mission lifecycle execution. Browser-only state changes for simulation behavior are incomplete without worker support.
- Patient and mission details live largely in JSON columns; the worker treats those blobs as live simulation state.
