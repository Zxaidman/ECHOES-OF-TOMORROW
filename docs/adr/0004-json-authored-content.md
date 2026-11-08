# ADR-0004: JSON for Authored Game Content

- Status: Accepted
- Date: 2026-11-08
- Decision version: 0.1.1

## Context

Content such as resources, buildings, recipes, inventions, NPC templates and events must be easy to review, diff, validate and edit with AI coding agents. The game also needs portability beyond Godot-specific tooling.

## Decision

Use versioned JSON as the canonical source for simulation content, with JSON Schema contracts and a headless validation step. Use Godot Resources and scenes for engine-native assets and presentation configuration where their editor integration is valuable.

## Consequences

Positive:
- Human- and agent-readable data.
- Stable IDs and explicit schema contracts.
- External validation and tooling are straightforward.
- Content is not coupled to scene-tree structure.

Trade-offs:
- JSON must be parsed and converted into typed domain data.
- Schema validation and useful error reporting must be implemented.
- Complex engine objects are not appropriate for JSON and remain native Resources/scenes.
