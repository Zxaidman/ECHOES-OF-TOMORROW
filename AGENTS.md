# Agent Instructions

These instructions apply to coding agents and automated contributors working in this repository.

## Project identity

- Project: Echoes of Tomorrow
- Current project version: 0.1.0
- Current phase: pre-production documentation
- Game direction: one-way time travel from a collapsed future to a medieval past; broad future knowledge; civilization reconstruction; important AI-assisted NPCs.
- Initial vertical slice: The First Spark.

## Mandatory product and engineering principle

> If a screen needs them to make sense, fix the layout. Every decision should elevate the user experience (UX), developer experience (DX) and agent experience (AX) at once, without breaking anything.

Apply this to every feature:
- UX: clear hierarchy, understandable state, accessible controls, useful feedback and low interaction friction.
- DX: modular code, explicit contracts, documentation, testability and maintainability.
- AX: machine-readable schemas, stable interfaces, explicit constraints, discoverable context and deterministic tool behavior.
- Stability: protect existing behavior, test changes, document migrations and avoid silent breaking changes.

## Non-negotiable architecture rules

1. The deterministic simulation is the authority for game state.
2. LLM output is untrusted input. Parse, validate, authorize and constrain it before applying any game command.
3. LLMs must never write directly to save files, databases or authoritative domain state.
4. Core simulation must remain playable without network access or an LLM provider.
5. Important NPC memory must be structured, bounded, versioned and persisted.
6. Randomness must use explicit seeds or injected random sources so tests and replays can be deterministic.
7. UI scenes must not own domain rules. UI calls application commands and renders application state.
8. Content definitions (resources, buildings, inventions, events and characters) should be data-driven where practical.
9. Avoid premature microservices, multiplayer, massive open-world simulation and per-NPC LLM calls in the first vertical slice.
10. No dependency or plugin is added without a documented reason and removal/fallback plan.

## Workflow requirements

Before changing code:
1. Read the relevant design and architecture documents.
2. Inspect the existing repository and current branch state.
3. Identify impacted modules, data contracts and user-visible screens.
4. State assumptions and risks.
5. Prefer small, reviewable changes.

After changing code:
1. Run relevant formatting, static checks and tests.
2. Add or update tests for behavior changes.
3. Verify save/load compatibility when persistence is affected.
4. Update documentation and version/changelog records.
5. Report exactly what changed, what was tested, what was not tested and any known limitations.

## Compatibility and versioning

- Follow MAJOR.MINOR.PATCH semantic versioning.
- Do not label incomplete work as complete.
- Breaking changes to public interfaces or persisted schemas require an explicit migration plan and version increment.
- Never overwrite user work or remove existing features without explicit authorization.
- Do not commit secrets, tokens, credentials, private keys or personal data.

## Current implementation boundary

The repository is currently documentation-only. Do not invent an existing Godot project structure or claim that a playable build exists. Runtime implementation should start only after the architecture baseline and first-slice acceptance criteria are reviewed.
