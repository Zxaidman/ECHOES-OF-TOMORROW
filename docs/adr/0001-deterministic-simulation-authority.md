# ADR-0001: Deterministic Simulation Owns Authoritative State

- Status: Accepted
- Date: 2026-11-08

## Context

The game combines simulation systems with optional LLM-generated dialogue and proposals. Direct model writes would make game state difficult to validate, replay, test and secure.

## Decision

Only domain/application commands may mutate authoritative simulation state. LLM output is an untrusted proposal that must be parsed, validated and resolved through the same command path as player actions.

## Consequences

Positive:
- Deterministic rules remain testable.
- Invalid or malicious model output can be rejected.
- Core gameplay remains available offline.
- State changes are auditable.

Costs:
- AI interactions require explicit schemas and validation.
- Some conversational freedom must be constrained by available game actions.
