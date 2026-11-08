# Game Design Document

**Document version:** 0.1.0  
**Project version:** 0.1.0  
**Status:** Baseline for pre-production; details remain subject to validation.

## 1. High concept

A person from a collapsed technological future travels one-way into a medieval past. They retain broad knowledge of science, engineering, medicine, agriculture, economics and history, but arrive without advanced tools or equipment. The player must rebuild capability through materials, manufacturing, institutions and relationships while changing the course of history.

**Player fantasy:** What could humanity become if someone who understood its future had the chance to rebuild it from an earlier point?

## 2. Genre and pillars

- Civilization reconstruction and settlement simulation.
- Historical strategy and alternate-history consequences.
- Knowledge-driven technology progression.
- Character-led social simulation with selected AI-assisted dialogue.

Design pillars:
1. Knowledge is powerful but insufficient without implementation.
2. Important people have agency, memory and conflicting goals.
3. The world changes in response to player actions.
4. The simulation continues independently of direct player attention.
5. Complex systems are presented through clear, legible interfaces.
6. The game remains playable without cloud AI.

## 3. Narrative premise

The protagonist originates in 2189, after a chain of technological, environmental, political and biological disasters has contributed to civilizational collapse. An experimental temporal transportation project sends the protagonist to a medieval-era region. The journey is one-way.

The protagonist has broad future knowledge but no future equipment, supply chain, laboratory or institutional authority. They must earn trust and translate abstract knowledge into achievable local steps.

The original future is a historical reference held by the protagonist. It becomes increasingly unreliable as the player causes divergence.

## 4. Player role and constraints

The player directs the protagonist and settlement strategy. The protagonist is knowledgeable, not omnipotent.

Constraints:
- Materials and tools must exist before an invention can be built.
- Skills must be taught, recruited or developed.
- People may distrust, misunderstand, resist or reinterpret ideas.
- Political and economic actors pursue their own interests.
- Historical predictions become less reliable as divergence increases.
- The protagonist cannot return to the original timeline.

## 5. Core gameplay loop

1. Explore the region and identify people, threats and resources.
2. Establish relationships and recruit capable inhabitants.
3. Build infrastructure and organize production.
4. Select a useful piece of future knowledge.
5. Resolve material, skill and manufacturing prerequisites.
6. Prototype and validate an invention.
7. Improve settlement health, productivity or resilience.
8. Respond to social, economic, environmental and political consequences.
9. Expand trade and diplomacy.
10. Observe how history diverges.

## 6. Knowledge-to-implementation model

Each invention progresses through seven distinct states:
1. Knowledge: the protagonist understands the principle.
2. Resources: required materials can be sourced.
3. Manufacturing: tools, processes and skilled labor exist.
4. Prototype: an experimental artifact is produced.
5. Validation: the prototype meets defined reliability criteria.
6. Industrialization: repeatable production can be scaled.
7. Adoption: people and institutions use it.

These are not necessarily a single linear progress bar. Some stages may require multiple prerequisites, failed attempts or alternative methods. The game must communicate why progress is blocked.

Initial inventions:
- Improved waterwheel and mechanical power transmission.
- Improved irrigation and water management.
- Sanitation practices and basic public-health infrastructure.

## 7. Settlement and economy

Initial resources:
- Food
- Water
- Wood
- Stone
- Iron
- Currency

Future candidate resources include copper, coal, clay, salt, medicinal materials, livestock, textiles and specialized components.

Every resource definition should identify:
- Sources and extraction methods.
- Production recipes.
- Consumption categories.
- Storage constraints and spoilage where applicable.
- Units and conversion rules.
- Relevant skills and facilities.

Initial settlement population target: 25–30 inhabitants. Population simulation should use aggregate or lightweight individual state where possible; do not run expensive LLM inference for routine needs.

## 8. Important NPCs

Five initial important NPC roles:
- Blacksmith: metallurgy, craft knowledge and production capability.
- Healer: traditional medicine, care and public-health practice.
- Merchant: trade networks, finance and economic leverage.
- Scholar: mathematics, natural philosophy and knowledge translation.
- Village leader: authority, legitimacy, public order and political priorities.

Each important NPC has identity, personality traits, skills, needs, goals, beliefs, relationships, trust, memories and current plans. NPCs can disagree with the protagonist and with each other.

## 9. World and timeline

The game tracks:
- Original timeline: the protagonist's remembered baseline.
- Altered timeline: the state and events produced by the simulation.

Historical divergence should be caused by simulation state and recorded events, not arbitrary narrative flags alone. Events may be prevented, delayed, accelerated or transformed. The player should receive understandable explanations of important consequences.

## 10. First vertical slice: The First Spark

Target play session: 30–60 minutes.

Scope:
- One medieval region.
- One controllable settlement.
- 25–30 inhabitants.
- Five important NPCs.
- Six initial resources.
- 10–15 building types (final list to be validated).
- Three implementable inventions.
- One neighbouring settlement.
- Basic trade and diplomacy.
- Food shortage, disease/public-health pressure and social conflict events.
- Original and altered timeline presentation.

The vertical slice should demonstrate a complete loop: meet people, solve a practical problem, build or improve infrastructure, introduce an invention, and observe consequences.

## 11. UX requirements

Core screens:
- Region/world map.
- Settlement overview.
- Building and production details.
- Population and work overview.
- Important NPC profile and interaction.
- Knowledge and invention workspace.
- Timeline and historical divergence.
- Event/decision detail.

Every screen must answer: Where am I? What is happening? What can I do? What will it cost? Why is an action unavailable? What changed after I acted?

## 12. Out of scope for the first slice

- Multiplayer.
- Massive open world.
- Global individual-level population simulation.
- LLM-powered routine behavior for every inhabitant.
- Large-scale military campaigns.
- Multiple playable eras.
- Fully simulated modern industrial economy.
- Real-time 3D world simulation.

## 13. Success criteria

The vertical slice is successful when the player can:
- Operate a settlement with understandable resource flows.
- Interact with five important NPCs whose responses reflect prior events.
- Advance three inventions through meaningful implementation constraints.
- Experience at least one consequential social or survival event.
- Observe a measurable historical divergence.
- Complete the experience without an LLM connection.
- Understand the state of the game through its interfaces.

## 14. Open design questions

- Exact calendar year and geographical/cultural inspiration.
- Protagonist identity, name, background and ethical limits.
- Whether the initial setting is fictionalized or historically grounded.
- Detailed resource units and production rates.
- Exact building roster and map scale.
- How much player control exists over the protagonist's direct actions.
- Narrative tone and rating target.

These decisions must be resolved before final content production, not silently assumed.
