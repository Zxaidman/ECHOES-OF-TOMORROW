# Echoes of Tomorrow

**Project version:** 1.0.0-rc.2  
**Phase:** World-first visual overhaul / release candidate  
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

The 1.0.0-rc.2 candidate is a Windows-first, offline-capable First Spark campaign. Its default screen is now a world-first isometric settlement with camera pan/zoom, selectable buildings and villagers, and contextual panels. The first outlined sprite pass uses selected Kenney Sketch Town / Sketch Town Expansion CC0 assets for terrain, paths, river, crops, buildings, trees and props. The deterministic settlement and population simulation, five named NPCs, offline conversations, historical choices, knowledge/invention progression, facility-gated production and save recovery remain in place. NPC art is still a placeholder pass; the settlement art requires desktop visual playtesting before stable 1.0.0. Trade, diplomacy, a regional map, multiple settlements, worker assignment and live cloud AI remain outside this candidate.

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

- 1.0.0-rc.2 playtest: docs/production/PLAYTEST_1.0.0.md
- Visual direction and rendering plan: docs/design/VISUAL_DIRECTION_1.0.0_RC2.md
- Integrated asset sources and licence: assets/kenney/sketch-town/README.md

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
