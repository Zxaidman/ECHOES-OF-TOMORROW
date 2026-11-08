# Echoes of Tomorrow

**Project version:** 0.4.0  
**Phase:** World and settlement simulation  
**Genre:** Civilization reconstruction / historical strategy simulation  
**Initial target:** Windows PC  
**Engine:** Godot 4.7.2-stable  
**Language:** Typed GDScript

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

The repository now includes a deterministic settlement simulation with named NPCs, needs, daily schedules, directional relationships, population food upkeep, save restoration and interactive time controls. This is an early playable systems slice, not the complete vertical slice.

## Run locally

1. Install Godot 4.7.2-stable (standard, not .NET).
2. Open the folder containing project.godot in Godot.
3. Run the project from the editor or terminal:

~~~bash
godot --path .
~~~

Run headless validation:

~~~bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/run_tests.gd
~~~

## CI and development releases

- Pull requests and pushes to main/develop run headless validation.
- CI produces check results only. It does not upload build artifacts.
- Merging to develop triggers a Windows development build published as a GitHub prerelease.
- See docs/production/CI_AND_RELEASES.md.

## Documentation

- Game Design Document: docs/design/GAME_DESIGN_DOCUMENT.md
- Technical Architecture: docs/architecture/TECHNICAL_ARCHITECTURE.md
- Simulation and Time Model: docs/architecture/SIMULATION_AND_TIME.md
- CI and Release Policy: docs/production/CI_AND_RELEASES.md
- Platform Compatibility: docs/architecture/PLATFORM_COMPATIBILITY.md
- NPC Intelligence: docs/systems/NPC_INTELLIGENCE.md
- Knowledge and Invention: docs/systems/KNOWLEDGE_AND_INVENTION.md
- World and Timeline: docs/systems/WORLD_AND_TIMELINE.md
- UX, DX and AX Standard: docs/standards/UX_DX_AX_STANDARD.md
- Roadmap: docs/production/ROADMAP.md
- Save and Content Data Strategy: docs/architecture/DATA_AND_PERSISTENCE.md
- CI and Release Policy: docs/production/CI_AND_RELEASES.md
- Architecture Decision Records: docs/adr/README.md
- Agent Instructions: AGENTS.md
- Contributing: CONTRIBUTING.md

## Versioning

The project follows MAJOR.MINOR.PATCH semantic versioning. Breaking changes to public interfaces or persisted schemas require an explicit migration plan.
