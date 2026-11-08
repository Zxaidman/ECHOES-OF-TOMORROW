# Production Roadmap

**Roadmap version:** 0.3.0

Milestones are gates, not calendar promises. A milestone is complete only when its acceptance criteria are met.

| Version | Milestone | Exit condition |
|---|---|---|
| 0.1.0 | Pre-production baseline | GDD, architecture, core system specs and standards reviewed |
| 0.1.1 | Architecture baseline | Technology and data decisions accepted in ADRs |
| 0.2.0 | Engine and project foundation | Godot project, initial scene, data loading, save foundation, tests and CI |
| 0.3.0 | World and settlement simulation | Region, settlement, resources, production, event queue and complete save/load |
| 0.4.0 | Population and NPC foundation | Needs, skills, schedules, relationships and deterministic goals |
| 0.5.0 | Knowledge and invention | Three invention chains with validated prerequisites |
| 0.6.0 | NPC memory and optional AI | Structured memory, bounded dialogue integration and offline fallback |
| 0.7.0 | Events and timeline | Causal event log and original/altered timeline presentation |
| 0.8.0 | Vertical-slice content complete | End-to-end First Spark playable loop |
| 0.9.0 | UX, balance and reliability | Acceptance tests, playtest fixes and performance validation |
| 1.0.0 | First playable release | Release criteria, documentation and reproducible build |

## 0.3.0 implementation status

- [x] Deterministic event queue with stable ordering
- [x] Atomic typed integer resource ledger
- [x] Independent seeded RNG streams
- [x] Settlement simulation with recurring resource events
- [x] Save-state capture and restore for resources, queue and RNG state
- [x] Dashboard controls for advancing time
- [x] Campaign save action
- [ ] Godot 4.7.2 headless validation
- [ ] Windows development export verification
- [ ] Manual Windows UX and save/reload playtest

## Next work queue

1. Complete population needs, skills, schedules and deterministic NPC goals.
2. Add building definitions and construction completion events.
3. Connect invention prerequisites to resource and production constraints.
4. Add save/load campaign selection and recovery UI.
