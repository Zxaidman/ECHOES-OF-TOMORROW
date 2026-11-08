# ADR-0008: Windows, Android, then Web Target Strategy

- Status: Accepted
- Date: 2026-11-08
- Decision version: 0.1.1

## Context

The project is a solo-developed strategy simulation. The developer wants Windows first, Android second and Web as a possible later distribution target. Supporting every platform immediately would increase QA and UX scope.

## Decision

Prioritize Windows for the first playable slice, Android as the second platform, and Web as a later compatibility target. Keep domain code platform-independent, use typed GDScript, avoid native dependencies in core modules and validate each platform with a separate export/device/browser gate. Web is not a release promise until Compatibility renderer, browser, memory, performance, storage and networking checks pass.

## Consequences

Positive:
- Focused initial development and QA.
- Cross-platform constraints are considered early.
- GDScript avoids Godot 4 C#'s current Web export limitation.

Trade-offs:
- Android and Web may require UI, rendering and storage adaptations.
- Platform compatibility cannot be inferred from Windows success.
- Web performance and browser restrictions may require reduced content or visual fidelity.
