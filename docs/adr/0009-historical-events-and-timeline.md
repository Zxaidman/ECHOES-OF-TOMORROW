# ADR-0009: Historical Events Are Deterministic Simulation Commands

- Status: Accepted
- Date: 2026-11-08

## Context

The campaign needs an original historical baseline and an altered timeline that emerges from player decisions. Event outcomes must be replayable, saveable and connected to existing settlement and NPC systems.

## Decision

- Authored event definitions live in versioned JSON content and are validated at load boundaries.
- Integer-minute trigger events enter the existing deterministic scheduled event queue.
- A player choice is an explicit domain command. It validates requirements before applying resource, relationship and memory consequences.
- Resolved choices may activate explicitly authored causal follow-up events.
- The timeline records original scheduled minute, actual trigger/resolution minute, baseline choice, selected choice and preserved/altered status.
- Timeline records are campaign state and are validated against the current authored catalog during restore.
- The UI displays domain state and submits commands; it does not calculate consequences.

## Consequences

Positive:
- Historical divergence is traceable to explicit player decisions.
- Event outcomes remain deterministic and work offline.
- NPC memories and settlement consequences share stable event IDs.
- Save/reload preserves pending decisions and causal follow-ups.

Trade-offs:
- Branches must be authored and validated; no arbitrary narrative graph is inferred at runtime.
- This first slice does not model global history, locations or multi-settlement causality.
