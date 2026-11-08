# Production Roadmap

**Roadmap version:** 0.1.1

Architecture decisions for engine/language, content data, persistence, simulation scheduling and NPC AI boundaries are recorded in ADR-0003 through ADR-0008.

Milestones are gates, not calendar promises. A milestone is complete only when its acceptance criteria are met.

| Version | Milestone | Exit condition |
|---|---|---|
| 0.1.0 | Pre-production baseline | GDD, architecture, core system specs and standards reviewed |
| 0.2.0 | Engine and project foundation | Reproducible project, CI/checks, initial scene and test harness |
| 0.3.0 | World and settlement simulation | Region, settlement, resources, production and save/load |
| 0.4.0 | Population and NPC foundation | Needs, skills, schedules, relationships and deterministic goals |
| 0.5.0 | Knowledge and invention | Three invention chains with validated prerequisites |
| 0.6.0 | NPC memory and optional AI | Structured memory, bounded dialogue integration and offline fallback |
| 0.7.0 | Events and timeline | Causal event log and original/altered timeline presentation |
| 0.8.0 | Vertical-slice content complete | End-to-end First Spark playable loop |
| 0.9.0 | UX, balance and reliability | Acceptance tests, playtest fixes and performance validation |
| 1.0.0 | First playable release | Release criteria, documentation and reproducible build |

## Near-term work queue

1. Review and resolve architecture decisions through ADRs.
2. Choose exact Godot version and language through a small technical spike.
3. Define content schema and validation tooling.
4. Define simulation time cadence and deterministic test harness.
5. Prototype one settlement screen and one invention screen to validate UX/DX/AX.
6. Only then begin broad runtime implementation.

## Scope control

A new feature must identify which vertical-slice objective it supports. Features that do not support the slice should be deferred unless they resolve a foundational architectural risk.
