# ADR-0003: Godot 4.7.2 and Typed GDScript

- Status: Accepted
- Date: 2026-11-08
- Decision version: 0.1.1

## Context

The project is a solo-developed, 2D-first strategy simulation with AI-assisted implementation and a requirement for repeatable headless validation. The intended platform order is Windows, Android, then potentially Web.

## Decision

Use Godot 4.7.2-stable as the pinned engine baseline and typed GDScript as the primary and default gameplay language. Do not use C# for the project baseline. Do not introduce GDExtension, native plugins or a second gameplay language unless a measured requirement and an ADR justify it.

Use Godot's headless command-line workflow for project import, script validation, automated tests and CI. Pin the exact Godot version in project documentation and CI; engine upgrades require a deliberate compatibility pass.

## Rationale

- GDScript is native to Godot and keeps the runtime/tooling path unified.
- Godot supports headless command-line workflows suitable for automation.
- Godot 4 C# currently lacks Web export support, while GDScript keeps the Web option open.
- A single primary language reduces context switching and makes coding-agent instructions simpler.

## Consequences

Positive:
- One primary language and engine workflow.
- Straightforward headless validation.
- Better alignment with the planned Web feasibility path.
- Lower setup and maintenance burden for a solo developer.

Trade-offs:
- GDScript may require profiling and optimization if simulation scale grows substantially.
- Some third-party libraries or tooling may favor C# or native extensions.
- Android and Web still require dedicated export, performance and UX testing; language choice alone does not guarantee compatibility.

## Validation gate

Before feature production, verify the pinned engine version, headless script/test execution, Windows export and a small Android/Web export spike. If a platform export limitation is found, document it rather than silently changing the language.
