# ADR-0005: Versioned JSON Campaign Saves

- Status: Accepted
- Date: 2026-11-08
- Decision version: 0.1.1

## Context

The first vertical slice has a small settlement and bounded regional state. Saves must be portable, inspectable, easy to migrate and usable across Windows, Android and a possible Web export.

## Decision

Use explicit Save DTOs serialized as versioned JSON snapshots under user://. Use ConfigFile separately for player settings. Implement atomic replacement, a previous known-good backup, validation and sequential migrations. Do not use SQLite for the first vertical slice.

## Consequences

Positive:
- Simple cross-platform persistence path.
- Readable and debuggable saves.
- No database plugin or native dependency.
- Straightforward schema fixtures and migration tests.

Trade-offs:
- Full snapshots may become expensive as campaign history grows.
- JSON requires explicit conversion for non-JSON types.
- Concurrent multi-device cloud synchronization is not solved by this decision.

Revisit SQLite only when measured save size, query complexity or concurrent access justifies it.
