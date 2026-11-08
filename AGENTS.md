# Agent Instructions

## Project identity
- Project: Echoes of Tomorrow
- Current project version: 0.6.0
- Current phase: NPC memory and optional AI
- Engine: Godot 4.7.2-stable (standard build)
- Language: typed GDScript
- Vertical slice: The First Spark

## Mandatory product and engineering principle
> If a screen needs them to make sense, fix the layout. Every decision should elevate UX, DX and AX at once, without breaking anything.

- UX: clear hierarchy, understandable state, accessible controls and useful feedback.
- DX: modular code, explicit contracts, documentation, tests and maintainability.
- AX: machine-readable schemas, stable interfaces, explicit constraints and deterministic behavior.
- Stability: protect existing behavior, test changes and document migrations.

## Non-negotiable architecture rules
1. Deterministic simulation owns authoritative game state.
2. LLM output is untrusted and must be validated before any game command.
3. LLMs never write directly to saves or authoritative state.
4. Core gameplay works offline and without an LLM provider.
5. Important NPC memory is structured, bounded, versioned and persisted; retrieval is deterministic and NPC-scoped.
6. Randomness uses explicit seeded streams.
7. UI scenes do not own domain rules.
8. Authored content is data-driven and validated at load boundaries.
9. Avoid premature microservices, multiplayer and per-NPC LLM calls.
10. No dependency/plugin without a documented reason and fallback.

## Workflow
Before changing code, inspect relevant docs and contracts. After changes, run headless import/parse and tests, add tests for behavior changes, update docs/changelog, and report exactly what was verified. Manual desktop playtesting is a 1.0.0 release gate; do not block intermediate milestones on it.

## Compatibility and versioning
- Follow MAJOR.MINOR.PATCH.
- Breaking persisted schemas or public contracts require migrations and version increments.
- Never overwrite user work or remove features without authorization.
- Never commit secrets.

## Architecture baseline
- Godot 4.7.2-stable, typed GDScript.
- Authored content: versioned JSON.
- Settings: ConfigFile. Campaign saves: versioned JSON snapshots with temp write and backup.
- Simulation: integer-minute clock and deterministic scheduled events; never couple to render frames.
- NPC AI: provider-neutral gateway and schema-validated allowlisted intents.
- Platform order: Windows, Android, then Web after explicit gates.
- Compatibility renderer to preserve Web feasibility.

## CI/CD
- CI is headless validation only; no Actions artifacts or caches.
- Pin engine and third-party actions.
- develop is integration branch; it publishes Windows GitHub prereleases.
- main is stable baseline. Stable releases require explicit approval.
- Never claim a build passed unless the workflow run succeeded.

## Current implementation boundary
Implemented: settlement resources, deterministic events, seeded RNG streams, five named NPCs, aggregate background population, needs, schedules, directional relationships, bounded persistent NPC memories, deterministic memory retrieval and decay, validated dialogue DTOs and offline fallback, data-driven knowledge, nine invention definitions, prototype validation, production commissioning and save restoration. Not implemented: a live provider adapter or secure inference backend, construction systems, Android/Web exports. Manual desktop playtesting is deliberately deferred until the 1.0.0 release candidate.
