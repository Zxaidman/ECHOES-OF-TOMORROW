# ADR-0007: Provider-Neutral, Validated NPC AI Gateway

- Status: Accepted
- Date: 2026-11-08
- Decision version: 0.1.1

## Context

Important NPCs should support contextual dialogue and selected social intents. LLM providers are external, nondeterministic and potentially unavailable. A client application cannot safely contain a private provider API key.

## Decision

Keep AI behind a provider-neutral gateway. The gateway accepts bounded, structured context and returns a strict response DTO. LLM output is untrusted and may only propose allowlisted intents. The application validates every proposal and resolves it through normal deterministic commands. The core game has an offline fallback and no gameplay-critical dependency on cloud inference.

If cloud inference is enabled in a shipped client, requests must go through a controlled backend/proxy with authentication, rate limits, quotas, timeouts and data minimization. No private provider key may be embedded in the client.

## Consequences

Positive:
- Provider can be changed without changing domain logic.
- Malformed or malicious model output cannot directly mutate state.
- Offline gameplay remains possible.
- Costs and data exposure can be controlled centrally.

Trade-offs:
- Requires backend infrastructure for securely shared cloud inference.
- AI interactions may have latency and operating costs.
- Structured responses constrain free-form autonomous behavior by design.
