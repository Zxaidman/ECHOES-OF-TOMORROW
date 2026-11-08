# Production Roadmap

**Roadmap version:** 1.0.0-rc.1

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
| 0.9.0 | UX, facilities and reliability | Facility-gated production, focused UI, migration and regression validation |
| 1.0.0 | First playable release | Release criteria, documentation and reproducible build |

## Release acceptance policy

- Intermediate milestones are validated with headless import, automated tests, CI and reproducible development exports.
- Manual desktop playtesting, UX walkthrough and save/reload playtesting are intentionally deferred until the 1.0.0 release candidate.
- 1.0.0 cannot be declared ready until the complete manual playtest checklist is passed and critical issues are resolved.

## 0.7.0 implementation status

- [x] Authored, versioned historical event catalog with stable IDs and validated choice definitions
- [x] Deterministic event triggers integrated with the integer-minute simulation queue
- [x] Player choices with resource requirements and atomic resource deltas
- [x] Causal follow-up events scheduled from resolved choices
- [x] NPC relationship updates and event-linked persistent NPC memories
- [x] Original baseline versus preserved/altered outcome records
- [x] Timeline state persistence, strict restore validation and 0.6.0 save migration
- [x] Timeline and pending-decision presentation in the settlement dashboard
- [ ] Manual playtest deferred to 1.0.0 release gate

## 0.6.0 implementation status

- [x] Structured per-NPC memories with stable IDs, event references, provenance, confidence and bounded participants/tags
- [x] Deterministic memory relevance ranking, age-based decay and bounded retention
- [x] NPC-scoped memory retrieval and save/restore validation
- [x] 0.5.0 campaign save migration with empty memory defaults
- [x] Provider-neutral bounded dialogue request/response DTOs and allowlisted intents
- [x] Strict response validation, target and supplied-memory reference checks
- [x] Deterministic offline dialogue fallback; no client-side provider credentials or network dependency
- [ ] Live cloud provider adapter and controlled backend deferred until a secure service is designed
- [ ] Manual playtest deferred to 1.0.0 release gate

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

## 0.8.0 implementation status

- [x] Derived campaign objective chain for the First Spark critical path
- [x] Objective completion tied to authoritative historical, knowledge and invention state
- [x] Successful production run counter persisted in invention save state
- [x] Migration of 0.7.0 invention progress to zero production runs
- [x] Campaign save and load controls with campaign identity and restore validation
- [x] Automated end-to-end objective and save/restore tests
- [ ] Headless validation and Windows development export
- [ ] Manual playtest deferred to 1.0.0 release gate

## 0.9.0 implementation status

- [x] Data-driven farmstead, workshop, forge and watermill definitions
- [x] Atomic construction with knowledge and resource prerequisites
- [x] Facility state persisted in campaign snapshots
- [x] 0.8.0 save migration to the starting farmstead
- [x] Invention production gated by required facility
- [x] Focused tabs and reduced interface copy
- [x] Facility, migration, construction and production-gate tests
- [x] Headless validation and Windows development export
- [x] Manual playtest deferred to 1.0.0 release candidate

## 1.0.0 release candidate status

- [x] Focused settlement, people, history, knowledge and production navigation
- [x] Facility construction and facility-gated invention production
- [x] Memory-aware offline conversations with validated NPC-scoped context
- [x] Save DTO verification and previous-good backup recovery
- [x] Facility and invention content-reference validation
- [x] Automated save-recovery, conversation, migration and simulation regression tests
- [x] Windows development export workflow
- [ ] Manual Windows launch and navigation checklist
- [ ] Full First Spark progression and historical decision playthrough
- [ ] Save, restart, backup recovery and reload playthrough
- [ ] Resolve all critical/high-severity issues
- [ ] Stable 1.0.0 approval

## Next work queue

1. Complete the manual acceptance checklist in PLAYTEST_1.0.0.md.
2. Fix critical/high-severity issues and rerun CI/export.
3. Publish stable 1.0.0 only after acceptance is complete.
