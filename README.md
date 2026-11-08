# Echoes of Tomorrow

**Project version:** 0.1.1  
**Phase:** Pre-production  
**Genre:** Civilization reconstruction / historical strategy simulation  
**Initial target:** Windows PC  
**Engine:** Godot 4.7.2-stable (pinned baseline)
**Language:** GDScript (primary)  
**Primary implementation language:** GDScript (provisional; validate before runtime implementation)

> You know how humanity's future unfolds. You have one opportunity to change it. But changing history is harder than knowing the future.

Echoes of Tomorrow is a strategy simulation about a person from a collapsed technological future who travels one-way into a medieval past. The protagonist carries broad scientific, engineering, medical, agricultural and historical knowledge, but has no future equipment or industrial base. The player must turn knowledge into practical capability by working with people, materials, institutions and imperfect historical conditions.

## Project principles

1. **Knowledge is not implementation.** Every invention must pass through material, manufacturing, prototyping, validation and adoption constraints.
2. **People are individuals.** Important NPCs have goals, skills, beliefs, relationships and persistent memories.
3. **History responds.** The original timeline is a reference, not a guaranteed future.
4. **Simulation is authoritative.** LLMs may propose dialogue or actions; deterministic game systems validate and apply state changes.
5. **UX, DX and AX improve together.** Interfaces, code architecture and agent-facing contracts must remain coherent.
6. **Protect working systems.** Changes require tests, migration discipline and explicit compatibility decisions.

## Current status

This repository contains the pre-production documentation baseline. It is not yet a playable Godot project. Runtime implementation begins after the architecture and vertical-slice requirements are reviewed.

## Documentation

- [Game Design Document](docs/design/GAME_DESIGN_DOCUMENT.md)
- [Technical Architecture](docs/architecture/TECHNICAL_ARCHITECTURE.md)
- [Simulation and Time Model](docs/architecture/SIMULATION_AND_TIME.md)
- [Platform Compatibility](docs/architecture/PLATFORM_COMPATIBILITY.md)
- [NPC Intelligence](docs/systems/NPC_INTELLIGENCE.md)
- [Knowledge and Invention](docs/systems/KNOWLEDGE_AND_INVENTION.md)
- [World and Timeline](docs/systems/WORLD_AND_TIMELINE.md)
- [UX, DX and AX Standard](docs/standards/UX_DX_AX_STANDARD.md)
- [Vertical Slice 0.1.0](docs/production/VERTICAL_SLICE_0.1.0.md)
- [Roadmap](docs/production/ROADMAP.md)
- [Save and Content Data Strategy](docs/architecture/DATA_AND_PERSISTENCE.md)
- [Architecture Decision Records](docs/adr/README.md)
- [Agent Instructions](AGENTS.md)
- [Contributing](CONTRIBUTING.md)

## First milestone

**The First Spark — Vertical Slice 0.1.0**

A single medieval region, one settlement, 25–30 simulated inhabitants, five important NPCs, six core resources, three inventions and one neighbouring settlement. The target is a coherent 30–60 minute playable experience.

## Versioning

The project uses semantic versioning: `MAJOR.MINOR.PATCH`. During pre-production, document versions and milestone identifiers are tracked explicitly. Breaking data or interface changes must be documented.

## Working agreement

Do not introduce engine scenes, plugins, external services, paid APIs or dependencies without recording the reason, expected benefit, fallback and verification plan. Never commit secrets or API keys.


## Architecture decisions — 0.1.1

The selected baseline is typed GDScript on Godot 4.7.2-stable; JSON for authored game content and versioned save snapshots; ConfigFile for player settings; an integer-minute deterministic simulation clock with scheduled event processing; and a provider-neutral, schema-validated NPC AI gateway. See the architecture documents and ADRs for rationale and constraints. Windows is the first release target, Android is the second, and Web is a later compatibility target that must pass its own export and browser performance gate.
