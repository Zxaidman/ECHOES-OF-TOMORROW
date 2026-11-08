# World and Timeline System

**Document version:** 0.1.0

## 1. Two timeline views

### Original timeline
A baseline knowledge model describing events the protagonist remembers from the future. It may contain dates, causes, confidence and source quality. It is not omniscient.

### Altered timeline
The actual sequence of world events produced by simulation and player decisions.

## 2. Historical divergence

Divergence should emerge from state changes and causal events. Examples:
- A settlement survives a disease event that was expected to devastate it.
- A new production method changes trade relationships.
- A neighboring authority reacts to a sudden increase in local capability.
- A political alliance changes because an NPC's goals or relationships changed.

Do not use a single arbitrary divergence percentage as the source of truth. A summary score may be displayed, but the underlying record must be traceable.

## 3. Event model

Historical events should include:
- Stable event ID.
- Expected/original date range, if known.
- Actual event date.
- Preconditions and trigger.
- Actors and locations.
- Consequences.
- Causal links.
- Confidence in original-timeline knowledge.
- Whether the event was prevented, delayed, accelerated, transformed or newly created.

## 4. Knowledge reliability

As divergence increases, the protagonist's remembered future becomes less reliable. This should be local and causal where possible: changing one region's political succession should not automatically erase unrelated scientific facts.

Distinguish:
- Stable scientific principles.
- Context-dependent technical predictions.
- Social and political predictions.
- Personal memories.

## 5. World scope for the first slice

One region, one player settlement and one neighboring settlement. Use a small number of explicit locations and events. The purpose is to prove causality and legibility, not simulate an entire planet.

## 6. Player-facing timeline UI

The timeline should show:
- What was expected.
- What actually happened.
- What action or event contributed to the change.
- What remains uncertain.
- Which future predictions are now less reliable.

Avoid presenting false precision or implying that the protagonist knows every future event.
