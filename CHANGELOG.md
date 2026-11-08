# Changelog

## [0.5.0] - Unreleased

### Added
- Data-driven knowledge catalog with prerequisite and skill-gated study.
- Nine inventions across agriculture, metallurgy and mechanical engineering.
- Prototype material costs, skill requirements, validation tests and production commissioning.
- Atomic production recipes connected to the settlement resource ledger.
- Knowledge and invention progress included in campaign snapshots.
- Scrollable dashboard sections for knowledge study and invention progression.
- Validation for duplicate IDs, unknown dependencies, invalid quantities and dependency cycles.

### Notes
- Three foundational knowledge entries are known at campaign start; advanced methods must be studied.
- Manual desktop playtesting is a release gate for 1.0.0, not an interim milestone gate.


## [0.4.0] - Unreleased

### Added
- Population aggregate with five individually simulated named NPCs and twenty background residents.
- Deterministic hourly needs, daily schedules, bounded goals and directional relationships.
- Daily population food upkeep connected to the atomic resource ledger.
- Population state included in campaign snapshots and restored with validation.
- Population overview surfaced in the settlement dashboard.

### Notes
- Background residents remain aggregated; named NPCs receive individual needs and schedules.
- NPC decisions remain deterministic and offline; no LLM mutates authoritative state.


All notable project changes are documented here.

## [0.3.0] - Unreleased

### Added
- Deterministic event queue ordered by game minute, priority and stable sequence.
- Atomic integer resource ledger with validated transactions.
- Independent seeded RNG streams for world, economy and NPC simulation.
- Settlement simulation with recurring resource events.
- Save-state capture and restore for resources, pending events, sequence state and RNG streams.
- Dashboard controls to advance one hour or one day and save the campaign.
- Headless tests for event ordering, atomic transactions, deterministic advancement and save restoration.

### Notes
- This is the first functioning settlement simulation slice, not the complete vertical slice.
- Godot headless and Windows export validation must pass before this milestone is considered verified.

## [0.2.0] - Foundation
- Initial Godot 4.7.2 project, settlement dashboard, JSON content, integer-minute clock, JSON save foundation and low-cost GitHub Actions CI/CD.
