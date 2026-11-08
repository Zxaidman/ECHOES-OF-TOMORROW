# Production Roadmap

**Roadmap version:** 0.2.0

Architecture decisions for engine/language, content data, persistence, simulation scheduling and NPC AI boundaries are recorded in ADR-0003 through ADR-0008.

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

## 0.2.0 implementation status

- [x] Godot project configuration and main scene
- [x] Initial responsive settlement dashboard shell
- [x] JSON starter resource and NPC content
- [x] Integer-minute simulation clock
- [x] JSON content loading boundary and stable-ID checks
- [x] Versioned JSON save snapshot foundation
- [x] Dependency-free headless test runner
- [x] CI workflow definition (headless validation only)
- [x] Development release workflow definition (GitHub prerelease assets; no Actions artifacts)
- [ ] Godot 4.7.2 runtime validation in CI
- [ ] Windows export template and release workflow verification
- [ ] UX review at desktop and narrow viewport sizes

## Next work queue

1. Verify the 0.2.0 foundation on Godot 4.7.2 and fix engine/parser issues.
2. Add deterministic scheduled-event queue and seeded random streams.
3. Add typed settlement state and resource transactions with invariant tests.
4. Connect dashboard to real application state and player commands.
5. Add Android feasibility smoke test after the Windows core loop is stable.

## Scope control

A new feature must identify which vertical-slice objective it supports. Features that do not support the slice should be deferred unless they resolve a foundational architectural risk.
