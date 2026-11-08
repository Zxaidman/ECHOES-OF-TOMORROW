# ADR-0003: Godot and GDScript as Provisional Starting Direction

- Status: Proposed
- Date: 2026-11-08

## Context

The project is a 2D-first strategy simulation being developed by a solo developer with AI-assisted coding. A lightweight engine and rapid iteration are desirable.

## Proposed decision

Use Godot 4.x and evaluate GDScript as the default implementation language. Before committing to production, build a small spike that covers typed domain data, deterministic simulation, save/load, UI scaling and automated tests. Compare C# only if the spike exposes meaningful limitations.

## Consequences if accepted

- One primary engine and language reduce setup overhead.
- GDScript is tightly integrated with Godot.
- The team must validate test tooling, static checks and code organization early.

## Acceptance gate

Do not mark this ADR Accepted until the spike and compatibility review are complete.
