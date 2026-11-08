# Knowledge and Invention System

**Document version:** 0.5.0

## Player-facing loop

The protagonist arrives with broad theoretical knowledge, but local capabilities must be developed. Knowledge unlocks possible approaches; it does not create materials, skilled labor, facilities or functioning products.

1. Study an advanced method after its knowledge prerequisites and skill requirements are met.
2. Build a prototype by paying its explicit material cost.
3. Test the prototype against a deterministic skill-based validation threshold.
4. Commission repeatable production after validation.
5. Build the required facility.
6. Execute the production recipe through the atomic resource ledger.

## Authored content

- `content/knowledge.json`: 12 entries, including three foundational concepts known at campaign start and nine advanced study topics.
- `content/inventions.json`: nine inventions across three dependency chains.
- Definitions use stable IDs, prerequisite arrays, integer resource quantities and skill requirements.
- Knowledge and invention dependency graphs are checked for unknown references and cycles during initialization.

## First invention chains

### Agriculture
Selective seed cultivation → planned crop rotation → managed irrigation channels.

### Metallurgy
Improved bloomery furnace → reliable wrought-iron tools → controlled steel process.

### Mechanical engineering
Waterwheel power → geared mill → mechanical water pump.

Each invention defines prototype inputs, minimum local skills, a validation skill threshold, a required facility, production inputs and production outputs.

## Simulation authority

All actions are deterministic. Skills are checked against the best available named-NPC skill. Resource costs and production inputs/outputs are applied as atomic ledger transactions. UI code only issues commands and renders returned state.

Validation failures preserve the prototype and record the reason and attempt count. A player can retry after conditions improve. Production cannot be commissioned before validation.

## Persistence

Known knowledge and per-invention lifecycle state are included in the campaign snapshot. Restore validates IDs, state names and attempt counters before applying state. A content-set mismatch is rejected rather than silently dropping player progress. Saves created by 0.4.0 are migrated by initializing the new knowledge catalog at its starting state; no prior invention progress existed in those saves.

## Current limitations

- Prototype validation is a deterministic skill threshold, not a physical simulation of material tolerances.
- Production recipes alter abstract settlement resources but require a constructed facility. Worker assignment, throughput, wear, quality variation and maintenance remain outside this milestone.
- Study actions are instantaneous and charge their authored resource cost; a time-based research queue is deferred.
- The initial content uses the existing food, wood, stone, iron ore and tools resource vocabulary.
- Manual desktop playtesting is deferred until the 1.0.0 release candidate.
