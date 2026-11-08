# Changelog

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
