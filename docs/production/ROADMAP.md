# Production Roadmap

**Roadmap version:** 0.5.0

Milestones are gates, not calendar promises. A milestone is complete only when its acceptance criteria are met.

| Version | Milestone | Exit condition |
|---|---|---|
| 0.1.0 | Pre-production baseline | GDD, architecture, core system specs and standards reviewed |
| 0.1.1 | Architecture baseline | Technology and data decisions accepted in ADRs |
| 0.2.0 | Engine and project foundation | Godot project, initial scene, data loading, save foundation, tests and CI |
| 0.3.0 | World and settlement simulation | Region, settlement, resources, production, event queue and complete save/load |
| 0.4.0 | Population and NPC foundation | Needs, skills, schedules, relationships and deterministic goals |
| 0.5.0 | Knowledge and invention | Three invention chains with study, prototype, validation and production loops |
| 0.6.0 | NPC memory and optional AI | Structured memory, bounded dialogue integration and offline fallback |
| 0.7.0 | Events and timeline | Causal event log and original/altered timeline presentation |
| 0.8.0 | Vertical-slice content complete | End-to-end First Spark playable loop |
| 0.9.0 | UX, balance and reliability | Acceptance tests, playtest fixes and performance validation |
| 1.0.0 | First playable release | Release criteria, documentation and reproducible build |

## Release acceptance policy

- Intermediate milestones are validated with headless import, automated tests, CI and reproducible development exports.
- Manual desktop playtesting, UX walkthrough and save/reload playtesting are intentionally deferred until the 1.0.0 release candidate.
- 1.0.0 cannot be declared ready until the complete manual playtest checklist is passed and critical issues are resolved.

## 0.5.0 implementation status

- [x] Versioned knowledge content with prerequisites and study costs
- [x] Nine inventions across agriculture, metallurgy and mechanical engineering
- [x] Prototype costs and skill gates
- [x] Validation and production commissioning lifecycle
- [x] Production recipes integrated with atomic resource ledger
- [x] Knowledge and invention save/restore
- [x] Knowledge and invention dashboard sections
- [ ] Headless validation and Windows development export

## 0.4.0 implementation status

- [x] Five named NPCs with skills, age, health and needs
- [x] Twenty background residents represented as an aggregate
- [x] Deterministic hourly schedules and bounded goal selection
- [x] Directional trust, cooperation and conflict relationships
- [x] Daily population food upkeep connected to the resource ledger
- [x] Population state included in campaign snapshots
- [x] Population overview in the dashboard
- [x] Godot headless validation and Windows export
- [ ] Manual playtest deferred to 1.0.0 release gate

## 0.3.0 implementation status

- [x] Deterministic event queue with stable ordering
- [x] Atomic typed integer resource ledger
- [x] Independent seeded RNG streams
- [x] Settlement simulation with recurring resource events
- [x] Save-state capture and restore for resources, queue and RNG state
- [x] Dashboard controls for advancing time
- [x] Campaign save action
- [x] Godot 4.7.2 headless validation
- [x] Windows development export verification
- [ ] Manual playtest deferred to 1.0.0 release gate

## Next work queue

1. Add facilities, construction and resource gathering to support repeatable production.
2. Add skill development and time-based knowledge study.
3. Build structured NPC memory and bounded optional AI dialogue.
4. Add causal world events and original/altered timeline presentation.
