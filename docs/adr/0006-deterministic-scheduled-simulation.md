# ADR-0006: Integer-Minute Deterministic Scheduled Simulation

- Status: Accepted
- Date: 2026-11-08
- Decision version: 0.1.1

## Context

The game must simulate settlement systems independently of render frame rate and remain reproducible in headless tests. Most strategy-simulation systems do not need to update every rendered frame.

## Decision

Use integer game minutes as canonical simulation time. Advance time through explicit application commands. Process due events in deterministic order by scheduled time, priority and stable sequence ID. Register recurring hourly, daily and weekly work only where needed. Use injected seeded random streams.

## Consequences

Positive:
- Frame-rate-independent outcomes.
- Efficient event-driven processing.
- Reproducible tests and replay.
- Clear save/load requirements for pending events and RNG state.

Trade-offs:
- Scheduler ordering must be explicitly designed and tested.
- Systems must declare cadence and avoid hidden side effects.
- Large time jumps need careful event processing and caps against pathological event loops.
