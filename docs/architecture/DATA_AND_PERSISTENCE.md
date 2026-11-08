# Data and Persistence Strategy

**Document version:** 0.3.0  
**Status:** Approved baseline for the first vertical slice.

## 1. Three data categories

| Category | Canonical format | Location | Purpose |
|---|---|---|---|
| Authored game content | JSON + JSON Schema | res:// content directory | Buildings, resources, recipes, inventions, NPC templates and events |
| Player settings | ConfigFile | user:// | Audio, display, language and accessibility preferences |
| Campaign progress | Versioned JSON snapshot DTO | user://saves | World, settlement, NPCs, economy, inventions, clock and timeline state |

Do not mix these categories into one file or one persistence service.

## 2. Why JSON for authored content

JSON is portable, diffable, easy for coding agents and external validation tools to read, and independent of Godot scene structure. It is appropriate for balance-critical content and stable data contracts.

Godot Resources and scenes remain appropriate for engine-native assets, visual configuration and editor-authored presentation. They are not the canonical source for simulation balance data.

Every content document must have:
- schema_version
- stable IDs
- explicit units for numeric quantities
- validated references
- no duplicate IDs
- no implicit reliance on file ordering

Content is parsed and validated at load time, then converted into typed domain data. Domain code must not mutate arbitrary parser dictionaries.

## 3. JSON Schema validation

Define a JSON Schema for each content family or a reusable shared schema with discriminated types. Validate in CI and in a headless content-validation command. Runtime loading must still handle parse and validation errors safely; CI validation is not a substitute for runtime checks.

Use a pinned validator version in development tooling. Do not add a runtime dependency solely for schema validation.

## 4. Campaign save format

The first vertical slice uses a versioned JSON snapshot, not SQLite.

The snapshot contains:
- save_schema_version
- game_version
- content_version
- campaign_id
- simulation_clock (integer minute)
- resource balances
- pending scheduled events and next event sequence ID
- random_stream_states
- world_state
- settlement_state
- population_state
- npc_state_and_memory
- economy_state
- technology_state
- scheduled_events
- timeline_and_causal_events

Persist stable IDs and plain data only. Do not serialize live Node references, arbitrary Objects, executable scripts or scene-tree ownership.

## 5. Safe write procedure

1. Build a complete Save DTO from authoritative state.
2. Validate required fields and invariants.
3. Serialize to a temporary file under user://.
4. Flush and close the file.
5. Verify the temporary file can be read and parsed.
6. Retain the previous known-good snapshot as a backup.
7. Replace the active snapshot.
8. Report success only after the final operation succeeds.

On load, validate schema version, content compatibility and required references before creating runtime state. If the active save is corrupt, offer recovery from the previous known-good backup and clearly explain the result.

## 6. Migration policy

- Every save has an explicit schema version.
- Migrations are sequential and deterministic.
- Never silently reinterpret a field with a changed meaning.
- Keep fixture saves for every released schema.
- Test migration and rollback/recovery paths.
- Unknown required fields or unsupported future schema versions must fail safely.
- Optional unknown fields may be ignored only where the schema explicitly allows it.

## 7. Why not SQLite yet?

The vertical slice has 25–30 residents and a bounded regional simulation. SQLite would add schema management, query-layer complexity and platform/export considerations without a demonstrated need. JSON snapshots are easier to inspect, diff and migrate at this scale.

Reconsider SQLite only if profiling or a concrete feature requires indexed queries, large history/event archives, concurrent access or data volumes that make snapshot serialization materially expensive. If introduced later, hide it behind the persistence interface and keep domain logic database-agnostic.

## 8. Settings

Use ConfigFile for small user preferences. Supply safe defaults for missing or invalid settings. Settings must not contain campaign progress or API credentials.

## 9. Future cloud synchronization

Cloud sync is out of scope for the first slice. Keep local save DTOs portable and versioned so a future sync service can be considered. Do not assume that file sync alone safely resolves concurrent campaign edits.
