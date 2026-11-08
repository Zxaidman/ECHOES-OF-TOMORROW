# Simulation and Time Model

**Document version:** 0.1.0

## Purpose

Define the rules for advancing the game world independently of rendering frame rate. This is a proposed model for the first vertical slice and must be validated through a small prototype.

## 1. Simulation clock

Maintain a game clock with:
- Calendar date (fictional calendar to be selected).
- Time of day.
- Simulation tick or sequence number.
- Explicit random seed.

The clock advances only through the simulation scheduler. UI frame rate must never change production, hunger, disease progression or NPC schedules.

## 2. Initial cadence proposal

| Boundary | Candidate work |
|---|---|
| On command | Validate and apply player actions |
| Hourly | Scheduled activities and selected local processes |
| Daily | Resource consumption, production, needs and NPC goal review |
| Event-triggered | Construction completion, trade arrival, threshold events |
| Weekly | Longer-term planning and settlement summaries |

Avoid evaluating every rule at every boundary. Systems should register only the cadence they need.

## 3. Deterministic update order

A daily update should use an explicit, documented order, provisionally:
1. Resolve scheduled arrivals and completions.
2. Apply production and resource transfers.
3. Apply consumption and upkeep.
4. Update needs and health indicators.
5. Update relationships and social pressures.
6. Evaluate NPC goals and schedules.
7. Evaluate event triggers.
8. Record summary and timeline events.

The final order must be validated for fairness and exploit resistance. Never rely on incidental dictionary or node iteration order.

## 4. Commands and events

Commands express intent (for example, ConstructBuilding). Domain events record facts (for example, BuildingConstructionStarted). Commands may fail; events describe accepted outcomes.

Every event should have:
- Stable event ID.
- Game timestamp and sequence.
- Event type and schema version.
- Actor and target IDs where relevant.
- Structured payload.
- Causal/correlation ID.
- Visibility classification for UI and NPC memory.

## 5. Deterministic randomness

Inject seeded random streams. Consider separate streams for world generation, economy, NPC simulation and event selection so unrelated changes do not perturb all outcomes.

Tests must be able to replay a sequence from seed plus commands.

## 6. Performance approach

The first slice has 25–30 inhabitants. Use simple per-character needs for important and nearby residents, and aggregate simulation for background population where appropriate. Do not add LLM calls to scheduled simulation ticks.

## 7. Open questions

- Exact calendar and day length.
- Whether the player can pause, speed up or step simulation.
- Which systems require hourly versus daily updates.
- How disease spreads and resolves at the first-slice level.
- How to represent sleeping, travel and off-screen work.
