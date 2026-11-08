# Agent Instructions

These instructions apply to coding agents and automated contributors working in this repository.

## Project identity

- Project: Echoes of Tomorrow
- Current project version: 0.2.0
- Current phase: runtime foundation
- Engine: Godot 4.7.2-stable (standard build)
- Language: typed GDScript
- Initial vertical slice: The First Spark

## Mandatory product and engineering principle

> If a screen needs them to make sense, fix the layout. Every decision should elevate the user experience (UX), developer experience (DX) and agent experience (AX) at once, without breaking anything.

Apply to every feature:
- UX: clear hierarchy, understandable state, accessible controls, useful feedback and low interaction friction.
- DX: modular code, explicit contracts, documentation, testability and maintainability.
- AX: machine-readable schemas, stable interfaces, explicit constraints, discoverable context and deterministic tool behavior.
- Stability: protect existing behavior, test changes, document migrations and avoid silent breaking changes.

## Non-negotiable architecture rules

1. Deterministic simulation owns authoritative game state.
2. LLM output is untrusted. Parse, validate, authorize and constrain it before applying a game command.
3. LLMs never write directly to save files, databases or authoritative domain state.
4. Core gameplay remains usable offline and without an LLM provider.
5. Important NPC memory is structured, bounded, versioned and persisted.
6. Randomness uses explicit seeds or injected random sources.
7. UI scenes do not own domain rules. UI calls application commands and renders application state.
8. Authored content is data-driven and validated at load boundaries.
9. Avoid premature microservices, multiplayer, massive open-world simulation and per-NPC LLM calls.
10. No dependency/plugin without a documented reason and fallback plan.

## Workflow requirements

Before changing code, read relevant design/architecture docs, inspect repository state, identify impacted contracts and screens, state assumptions/risks, and prefer small reviewable changes.

After changing code, run headless import/parse and tests, add tests for behavior changes, verify persistence compatibility when affected, update docs/changelog, and report exactly what was and was not verified.

## Compatibility and versioning

- Follow MAJOR.MINOR.PATCH semantic versioning.
- Breaking persisted schema or public contract changes require migration and version increment.
- Never overwrite user work or remove features without authorization.
- Never commit secrets, tokens, credentials or private keys.

## Selected architecture baseline

- Godot 4.7.2-stable; do not upgrade automatically.
- Typed GDScript. No C#, GDExtension or native plugins without an ADR and demonstrated need.
- Authored content: versioned JSON validated at the content boundary.
- Settings: ConfigFile. Campaign saves: versioned JSON snapshots with temporary write and previous-good backup.
- Simulation: integer-minute clock and deterministic scheduled events; never couple simulation to render frames.
- NPC AI: provider-neutral gateway; schema-validated allowlisted intents; no provider secret in a client build.
- Platform order: Windows first, Android second, Web later after explicit compatibility gates.
- Renderer: Compatibility renderer to preserve the Web path; measure performance before locking this as final for all platforms.

## CI/CD contract

- CI is headless validation only; it must not upload Actions artifacts.
- Do not use upload-artifact/download-artifact actions or cache large engine/export-template files.
- Pin engine version and third-party actions.
- develop is the development integration branch; qualifying pushes can publish a Windows GitHub prerelease.
- main is the stable baseline. Stable releases require an explicit release decision.
- Never claim a release build passed unless the corresponding workflow run succeeded.

## Current implementation boundary

This is a foundation, not a complete game. Do not claim unfinished simulation, economy, NPC behavior, LLM integration, or Android/Web exports exist.
