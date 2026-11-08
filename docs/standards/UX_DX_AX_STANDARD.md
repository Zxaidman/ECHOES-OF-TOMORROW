# UX, DX and AX Standard

**Document version:** 0.1.0  
**Status:** Mandatory project standard.

> If a screen needs them to make sense, fix the layout. Every decision should elevate the user experience (UX), developer experience (DX) and agent experience (AX) at once, without breaking anything.

## 1. UX — User experience

- Establish clear information hierarchy and consistent navigation.
- Show relevant costs, prerequisites, consequences and failure reasons before commitment.
- Provide meaningful feedback after actions.
- Use progressive disclosure for complex systems.
- Ensure readable typography, contrast, input targets and scalable layouts.
- Prefer coherent layouts over adding explanatory clutter.
- Preserve player context when moving between related screens.
- Support pause, speed and simulation-state clarity where applicable.

## 2. DX — Developer experience

- Keep modules cohesive and loosely coupled.
- Define explicit interfaces and ownership.
- Prefer typed data and stable IDs over magic strings.
- Make setup, build, test and debug workflows reproducible.
- Add tests around business rules and persistence.
- Document non-obvious decisions and trade-offs.
- Avoid unnecessary abstractions and dependencies.
- Keep errors actionable.

## 3. AX — Agent experience

- Maintain AGENTS.md as the entry point for coding-agent constraints.
- Provide machine-readable content schemas and examples.
- Keep architecture, feature scope and acceptance criteria discoverable.
- Use stable command names, reason codes and data contracts.
- Make tests deterministic and easy to run.
- Expose useful development diagnostics.
- Record decisions and unresolved questions explicitly.
- Never require an agent to infer hidden state or invent missing requirements.

## 4. Stability and change safety

Every non-trivial change must identify:
- Existing behavior affected.
- Data and interface compatibility impact.
- Migration needs.
- Test coverage.
- Rollback or fallback.
- UX/DX/AX effects.

Do not break working behavior to satisfy a local implementation preference. Prefer additive, reversible changes when possible.

## 5. Screen review checklist

For each screen, ask:
1. What is the user's primary task?
2. What information is required to make a decision?
3. Is the visual hierarchy clear?
4. Are costs, risks and prerequisites visible?
5. Are unavailable actions explained?
6. Can the user recover from mistakes?
7. Does the layout work at supported resolutions and scaling?
8. Is the underlying data contract clear to developers and agents?
9. Can the screen be tested without brittle visual assumptions?

## 6. Definition of done

A feature is not complete merely because it renders or compiles. It must meet its acceptance criteria, have appropriate tests, communicate state clearly, document relevant contracts and preserve existing functionality.
