# ADR-0002: Optional LLM Integration Behind a Validated Adapter

- Status: Accepted
- Date: 2026-11-08

## Context

Important NPCs should support contextual dialogue and selected social reasoning, but cloud providers may be unavailable, expensive or change their APIs.

## Decision

Define a provider-neutral application interface for optional LLM requests. Keep provider-specific SDKs, network code and prompt construction in infrastructure. Core simulation must not depend on the provider.

## Consequences

Positive:
- Provider can be changed without rewriting simulation rules.
- Offline fallback remains possible.
- Request limits and privacy controls have a single boundary.

Costs:
- Adapter and schema work is required.
- Provider-specific capabilities must not leak into domain models.
