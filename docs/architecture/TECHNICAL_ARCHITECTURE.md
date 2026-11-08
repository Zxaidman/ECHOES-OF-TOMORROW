# Technical Architecture Specification

**Document version:** 0.1.0  
**Project version:** 0.1.0  
**Status:** Proposed baseline; validate with a small engine spike before production implementation.

## 1. Architecture goals

The architecture must support a deterministic, testable settlement simulation; modular content; selected LLM-assisted NPC interactions; save/load; clear UI boundaries; and gradual expansion beyond the first vertical slice.

Priorities:
1. Correctness and debuggability.
2. Offline-first core gameplay.
3. Stable data contracts.
4. UX, DX and AX coherence.
5. Small dependency footprint.
6. Vertical-slice scope discipline.

## 2. Proposed technology

- Engine: Godot 4.x.
- Primary language: GDScript for initial implementation.
- Data definitions: versioned JSON or Godot Resources; choose one canonical authoring format after a content-pipeline spike.
- Persistence: versioned save format; SQLite is a candidate, not yet mandatory for the first slice.
- AI: provider-neutral adapter around an optional cloud LLM.
- Tests: headless engine tests plus pure-domain tests where feasible.
- Version control: Git.

Do not lock to a specific Godot patch, LLM provider or database library until compatibility, export, licensing and deployment have been checked.

## 3. Layered architecture

### Presentation layer
Godot scenes and UI controls. Responsible for rendering state, collecting player input, accessibility and navigation. Must not own simulation rules.

### Application layer
Use cases/commands such as:
- AssignWork
- ConstructBuilding
- StartInventionStage
- CompleteTrade
- AcceptOrRejectRefugees
- RequestNpcConversation

Coordinates domain operations and returns structured results for UI and agents.

### Domain/simulation layer
Authoritative rules and state:
- World and settlement state.
- Population and NPC state.
- Economy and inventories.
- Buildings and production.
- Technology and invention progression.
- Timeline events and divergence.
- Diplomacy and relationships.

Domain logic should avoid direct scene-tree dependencies and network calls.

### Infrastructure layer
Save/load, content loading, event logs, deterministic random source, optional LLM provider adapters and platform integrations.

## 4. Module boundaries

| Module | Owns | Must not own |
|---|---|---|
| World | Region, locations, travel and world events | UI widgets |
| Settlement | Buildings, work sites and local policies | LLM prompts |
| Population | Residents, needs and aggregate demographics | Direct scene manipulation |
| NPC | Character goals, relationships and memory | Unvalidated external state writes |
| Economy | Resource balances, recipes and transactions | Dialogue generation |
| Technology | Knowledge, prerequisites and invention state | Arbitrary resource creation |
| Timeline | Baseline events, divergence and causal records | Untraceable narrative overrides |
| Diplomacy | Inter-settlement relations, agreements and trade | UI presentation |
| Events | Event definitions, triggers and consequences | Hidden direct state mutation |
| AI integration | Prompt/context assembly and validated proposals | Authoritative game-state ownership |
| Persistence | Serialization, schema versions and migrations | Gameplay decision-making |

Modules communicate through typed data contracts and application commands. Avoid cyclic dependencies.

## 5. State ownership and command flow

The simulation owns authoritative state. UI and LLM adapters submit commands. Commands are validated against current state and produce:
- Success or failure result.
- Structured reason codes.
- State changes.
- Domain events for logs and UI updates.

A command must be safe to reject. Invalid commands must not partially mutate state.

LLM proposal flow:
1. Build a bounded context snapshot.
2. Request structured proposal from provider.
3. Parse output against a schema.
4. Validate actor, target, permissions and preconditions.
5. Apply via normal application command.
6. Record outcome and provenance.
7. Present result to player.

Provider output is untrusted, even when it is valid JSON.

## 6. Determinism

Simulation updates should be reproducible from:
- Initial state.
- Ordered player commands.
- Explicit random seed.
- Versioned simulation rules.

Use an injected seeded random source. Avoid reading wall-clock time or global randomness inside domain rules. Record command/event order for debugging and replay.

LLM text generation is not deterministic; it must not determine core outcomes without a deterministic validation and resolution step.

## 7. Simulation scheduling

Use a discrete simulation clock rather than tying world outcomes to rendered frame rate.

Proposed initial cadence:
- Frame loop: presentation only.
- Short simulation step: only for mechanics that visibly require it.
- Hour/day boundaries: needs, production and schedules.
- Day boundary: aggregate economy, NPC goal review and settlement summaries.
- Event-driven: construction completion, trade arrival, disease threshold and other discrete events.

Exact time scale and cadence are open decisions to test for clarity and performance. Do not simulate every NPC every rendered frame.

## 8. Persistence

Save data must include:
- Save schema version.
- Game content version.
- Simulation seed and clock.
- World and settlement state.
- Resource inventories and active production.
- NPC state and bounded memory.
- Technology and invention states.
- Timeline baseline, divergence and event history.
- Pending scheduled events.

Requirements:
- Atomic save strategy.
- Validate data on load.
- Migrate known older schemas.
- Preserve unknown optional fields where practical.
- Reject corrupt or unsupported saves safely with a useful message.
- Never persist API keys or provider secrets in a save.

A schema migration must be tested against representative prior fixtures.

## 9. Content pipeline

Resources, buildings, recipes, inventions, events and character templates should be data-driven.

Each definition must have:
- Stable ID.
- Schema version.
- Display name and description keys.
- Explicit prerequisites.
- Numeric values with documented units.
- Validation rules.
- Optional tags for discovery and UI grouping.

Do not use display names as persistent identifiers.

## 10. UI and interaction contracts

UI reads view models or immutable snapshots and dispatches application commands. It must not mutate domain objects directly.

Every action should expose:
- Preconditions.
- Costs.
- Expected outcome.
- Failure reason.
- Whether it is reversible.
- Relevant risk or uncertainty.

Use consistent design tokens and reusable components. Screen layout must be corrected when information density makes the interface unclear; do not solve every issue by adding more panels or text.

## 11. Observability and debugging

Provide development-only tools for:
- Current simulation time and seed.
- Resource flow inspection.
- NPC goal and decision trace.
- Invention prerequisite inspection.
- Event history and causal links.
- Save schema and migration status.
- LLM request/response metadata with secrets and personal data excluded.

Logs should be structured and useful to both developers and coding agents.

## 12. Testing strategy

- Unit tests: domain rules, costs, prerequisites, relationships and event triggers.
- Determinism tests: same seed and command sequence yield same simulation state.
- Contract tests: schemas and application command validation.
- Integration tests: save/load, migration and module interactions.
- AI boundary tests: malformed, adversarial, irrelevant and unauthorized LLM proposals are rejected.
- UI tests: navigation, critical actions, error states and responsive layout.
- Performance tests: target population and event volume on minimum supported hardware.

## 13. Security and reliability

- No secrets in repository, client build, save files or logs.
- Cloud AI must be optional and clearly disclosed.
- Apply request timeouts, bounded retries and rate limits.
- Treat all external content as untrusted.
- Avoid sending unnecessary player data to providers.
- Provide deterministic fallback behavior when AI is unavailable.
- Do not let model-generated content execute code or arbitrary commands.

## 14. Initial project structure (target, not yet created)

```text
EchoesOfTomorrow/
├── project.godot
├── AGENTS.md
├── README.md
├── docs/
├── game/
│   ├── presentation/
│   ├── application/
│   ├── domain/
│   │   ├── world/
│   │   ├── settlement/
│   │   ├── population/
│   │   ├── npc/
│   │   ├── economy/
│   │   ├── technology/
│   │   ├── timeline/
│   │   └── diplomacy/
│   ├── infrastructure/
│   └── content/
├── tests/
└── tools/
```

## 15. Decisions still requiring validation

- GDScript versus C# through a representative prototype.
- Godot Resource versus JSON content authoring.
- SQLite versus versioned JSON save files for the first slice.
- Exact simulation cadence.
- Event bus versus explicit application service communication.
- Provider and structured-output capabilities for optional LLM.
- Desktop UI scaling and input support.

No runtime implementation should assume these are settled until the relevant ADR or spike is complete.
