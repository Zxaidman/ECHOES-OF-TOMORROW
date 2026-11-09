# Agent Instructions

## Project identity
- Project: Echoes of Tomorrow
- Current project version: 1.0.0-rc.2
- Current phase: First Spark gameplay and visual overhaul
- Engine: Godot 4.7.2-stable (standard build)
- Language: typed GDScript
- Vertical slice: The First Spark

## Product principle
> If a screen needs helper text to make sense, fix the layout. Elevate UX, DX and AX together without breaking existing behavior.

## Mandatory architecture
1. Deterministic simulation owns authoritative game state.
2. LLM output is untrusted and validated before any game command.
3. LLMs never write directly to saves or authoritative state.
4. Core gameplay works offline.
5. Important NPC memory is structured, bounded, versioned and persisted.
6. Randomness uses explicit seeded streams.
7. UI scenes do not own domain rules.
8. Authored content is data-driven and validated at load boundaries.
9. Avoid premature microservices, multiplayer and per-NPC LLM calls.
10. No dependency/plugin without a documented reason, licence and fallback.

## Branch and release policy
- Exactly two long-lived branches: `main` and `develop`.
- Work directly on `develop`; do not create feature, fix, milestone or release branches.
- `main` is the stable release branch. Promote from `develop` to `main` only after explicit release approval.
- The existing CI and Development Release workflows are the only pipelines. Update them in place; do not add parallel workflows.
- Keep only the newest development prerelease and its Windows ZIP/checksum. Older development prereleases and tags are deleted after a new build succeeds.
- Never create GitHub Actions build artifacts.
- Never publish a stable release without explicit approval.

## Visual direction
- Isometric 2.5D settlement presentation.
- Hand-painted, warm medieval art direction with restrained dark contour outlines.
- World view is the primary screen; dashboards are secondary/contextual.
- Buildings and NPCs must be selectable, legible and depth-sorted.
- Prefer authored sprite outlines; use the shared outline shader where appropriate and only when its padded texture bounds prevent clipping.
- Use restrained lighting, ambient animation and purposeful feedback. Avoid expensive full-screen effects without measured benefit.
- Do not ship placeholder rectangles as final game art.

## Engineering workflow
- Inspect relevant docs/contracts before changing code.
- Keep simulation independent from render frames and presentation state.
- Add tests for behavior changes; preserve save compatibility and migrations.
- Run headless import/parse and tests; run Windows export before publishing.
- Update docs/changelog and report exactly what was verified.
- Use semantic versioning. While 1.0.0 is not stable, continue as 1.0.0 release candidates rather than claiming 1.1.0.
- Never claim a build passed unless the workflow run succeeded.

## Current implementation boundary
Implemented: deterministic resources/events/RNG, five named NPCs, aggregate background population, schedules and relationships, bounded NPC memories, validated dialogue DTOs and offline fallback, knowledge and invention lifecycle, historical events/timeline, First Spark objectives, facilities and facility-gated production, campaign save/load and verified backup recovery.
Not implemented: a living settlement scene, NPC world movement/animation, construction placement, work assignment, maintenance, trade, diplomacy, multi-settlement play, live provider integration, Android/Web exports.
