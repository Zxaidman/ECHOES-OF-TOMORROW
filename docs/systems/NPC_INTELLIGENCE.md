# NPC Intelligence Specification

**Document version:** 0.1.0

## 1. Design objective

Important NPCs should feel like people with consistent motives and histories, not dialogue generators. They must remain useful and understandable when cloud AI is unavailable.

## 2. Hybrid architecture

### Deterministic simulation
Owns needs, schedules, jobs, skills, goals, relationships, trust, loyalty, available actions and consequences.

### Utility AI
Scores feasible actions against current needs, goals, personality modifiers and context. It chooses from an explicit action set.

### GOAP (selective)
Use goal-oriented action planning only where multi-step planning materially improves behavior, such as gathering materials before crafting or seeking help to fulfill a goal. Avoid a universal planner for every routine.

### Optional LLM
Used for contextual dialogue, negotiation phrasing, reflection summaries and bounded proposals for social actions. It does not own state or decide numeric outcomes.

## 3. NPC state model

Each important NPC should have:
- Stable character ID.
- Name and role.
- Skills and experience.
- Needs and current condition.
- Personality traits.
- Short- and long-term goals.
- Beliefs and opinions with confidence/provenance where needed.
- Relationships to other characters and groups.
- Trust and loyalty as separate concepts.
- Bounded memory records.
- Current plan and recent decision trace.

Do not reduce a character to a single friendliness score.

## 4. Memory model

Memory records should be structured:
- Memory ID.
- Event reference.
- Timestamp.
- Participants.
- Event summary.
- Emotional significance (bounded numeric or categorical representation).
- Importance/retention score.
- Whether the NPC witnessed the event or learned it second-hand.
- Confidence and source.
- Schema version.

Memory should be bounded through deterministic retention/compaction rules. Never silently rewrite a witnessed fact into an objective truth. NPCs can have mistaken beliefs.

## 5. Relationships

Relationship state is directional: NPC A's view of NPC B may differ from B's view of A.

Potential dimensions:
- Trust.
- Affection/respect.
- Fear.
- Obligation/debt.
- Rivalry.
- Shared affiliation.

Use only dimensions that influence gameplay. Relationship changes should reference events and be inspectable.

## 6. Important NPC roles for the first slice

- Blacksmith: craft expertise, production ambition and concern for workshop safety.
- Healer: care priorities, medical ethics and public-health knowledge.
- Merchant: profit, risk, reputation and trade relationships.
- Scholar: curiosity, evidence standards and institutional ambition.
- Village leader: legitimacy, stability, local obligations and political constraints.

Names, biographies and exact traits remain to be authored.

## 7. LLM proposal contract

An LLM response must be treated as a proposal, not a command. The application layer should validate:
- Schema and size limits.
- Allowed action type.
- NPC identity and current context.
- Whether the NPC knows the relevant information.
- Whether the action is feasible.
- Whether the player has authorized the interaction.
- Whether the action conflicts with hard simulation constraints.

Reject unknown fields or unsupported actions according to the selected schema policy. Do not execute free-form tool calls from model text.

## 8. Context construction

Send only the minimum context needed:
- NPC persona summary.
- Relevant memories, not full lifetime logs.
- Current needs and goals.
- Relevant relationship facts.
- Recent visible events.
- Player's current dialogue or action.
- Allowed response schema and constraints.

Never send secrets, unrelated save data or unnecessary personal information.

## 9. Failure and offline behavior

When the provider is unavailable:
- Use deterministic dialogue options or authored fallback lines.
- Continue simulation normally.
- Do not block critical gameplay.
- Show clear UI feedback when generated dialogue is unavailable.
- Retry only with bounded timeouts and rate limits.

## 10. Testing

Test consistent behavior across repeated runs, memory retrieval, false-belief handling, relationship directionality, invalid LLM output, prompt injection attempts, provider timeout, offline fallback and save/load persistence.


## 11. Selected AI interaction contract (0.1.1)

The first implementation must support offline deterministic dialogue and an optional provider-backed dialogue adapter. LLM integration is not allowed to block simulation progress.

### Request DTO

The application builds a bounded request containing:
- schema_version
- request_id
- npc_id
- player_input
- current_scene_summary
- npc_persona_summary
- current_goals_summary
- relevant_memory_records (bounded list)
- known_facts relevant to this interaction
- allowed_intents
- response_constraints

The gateway must not receive the complete save file, unrelated NPC memories, credentials or hidden state that the NPC could not know.

### Response DTO

The first response contract contains:
- schema_version
- request_id
- npc_id
- dialogue_text (bounded length)
- intent (one of: none, ask_for_help, offer_trade, refuse, share_information, propose_meeting)
- target_id (nullable; must be a valid visible/known target for that intent)
- referenced_memory_ids (bounded list; every ID must exist in the supplied context)

The model cannot set trust, loyalty, relationship scores, inventory, resources, health, quest state or timeline state. Those values change only through deterministic domain commands.

### Validation

Reject responses when:
- JSON parsing or schema validation fails.
- request_id or npc_id does not match the active request.
- text exceeds limits or contains invalid control payloads.
- intent is not allowlisted.
- target is missing, unknown or not eligible.
- referenced memories were not provided to the model.
- the request has expired or the NPC context has materially changed.

A valid intent is still only a proposal. The application layer checks current world state and permissions, then either issues an allowed command or returns a safe refusal/fallback.

### Memory retrieval

Retrieve a small set of memories using deterministic relevance scoring based on recency, importance, participants, event tags and current topic. Keep witnessed facts distinct from hearsay and subjective interpretation. Store durable memory records as structured data with stable IDs; do not store only free-form LLM summaries.

### Provider and privacy boundary

Provider-specific code stays behind the gateway. A private API key must never be embedded in Windows, Android or Web client builds. If cloud inference is introduced, route requests through a controlled backend with authentication, quotas, rate limits, timeouts and data minimization. Provide an offline fallback for every gameplay-critical interaction.

## 12. Initial implementation scope

For the first playable milestone:
- Deterministic authored dialogue is the guaranteed baseline.
- Optional LLM dialogue may be enabled behind a feature flag.
- NPC memory and relationship changes are stored and resolved by the game.
- LLM-generated intent is limited to the allowlist above.
- No free-form agent tool execution or autonomous external actions.
