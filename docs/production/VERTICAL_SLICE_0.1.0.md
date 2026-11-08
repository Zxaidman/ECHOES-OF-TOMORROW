# Vertical Slice: The First Spark

**Milestone version:** 0.1.0  
**Target session:** 30–60 minutes  
**Status:** Scope baseline; exact content values remain to be balanced.

## 1. Objective

Prove the core promise: future knowledge can help rebuild a medieval settlement, but successful implementation depends on materials, skills, institutions and trust.

## 2. Player experience

The protagonist arrives in a small settlement, meets local people, earns cooperation, introduces an improved practical system and responds to a crisis. The player sees measurable effects on the settlement and a change in the altered timeline.

## 3. Content scope

- One small historical region.
- One player settlement.
- One neighboring settlement.
- 25–30 inhabitants.
- Five important NPCs: blacksmith, healer, merchant, scholar and village leader.
- Six initial resources: food, water, wood, stone, iron and currency.
- 10–15 buildings, final roster pending.
- Three inventions: improved waterwheel, irrigation and sanitation.
- Basic trade, diplomacy and relationship state.
- Events: shortage, disease/public-health pressure and social conflict.

## 4. Required systems

1. Region navigation and location discovery.
2. Settlement overview and construction.
3. Resource inventory, production and consumption.
4. Work assignment and simple population simulation.
5. Important NPC schedules, goals, relationships and memory.
6. Knowledge-to-implementation progression.
7. One bounded AI dialogue interaction with deterministic fallback.
8. Event triggers and consequences.
9. Original/altered timeline record.
10. Save/load with schema versioning.

## 5. UX screens

- Region map.
- Settlement overview.
- Building details.
- Resource and production details.
- Population/work overview.
- NPC profile and conversation.
- Invention workspace.
- Event/decision screen.
- Timeline comparison.
- Save/load and settings.

Each screen must explain current state, available actions, costs, constraints and outcomes. Layout quality is a release criterion.

## 6. Acceptance criteria

### Simulation
- Same initial seed and ordered commands produce the same deterministic state.
- Resource balances never become negative unless an explicitly defined debt mechanic allows it.
- Production and consumption are traceable.
- Invalid commands do not partially mutate state.

### NPCs
- Five important NPCs have distinct roles, skills and goals.
- At least one interaction changes a relationship or memory record.
- Memory distinguishes witnessed events from hearsay.
- NPC behavior remains functional without cloud AI.
- Invalid or unauthorized AI proposals are rejected.

### Inventions
- All three inventions expose stage and prerequisite state.
- The player can identify why an invention is blocked.
- At least one invention reaches validated prototype or adoption within the slice.
- Failed attempts provide a comprehensible reason.

### Timeline
- At least one player action produces a recorded divergence.
- The UI explains the causal link.
- Original-timeline knowledge is not treated as infallible.

### Reliability
- Save/load round trip preserves required state.
- Invalid saves fail safely.
- Automated tests cover critical domain rules.
- No secrets are included in repository or save data.

## 7. Explicit exclusions

No multiplayer, massive map, global simulation, full military system, multiple eras, per-resident LLM inference or final commercial content volume.

## 8. Exit review

The slice is ready for external playtesting only after all acceptance criteria are demonstrated in a reproducible build and known limitations are documented.
