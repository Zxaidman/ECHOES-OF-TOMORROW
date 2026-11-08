# Contributing

Thank you for contributing to Echoes of Tomorrow.

## Current phase

The repository is in pre-production. Contributions should strengthen the design, architecture, acceptance criteria and production readiness before expanding runtime scope.

## Before opening a change

- Read [AGENTS.md](AGENTS.md).
- Read the relevant design or architecture documents.
- Check whether an Architecture Decision Record (ADR) is needed.
- Keep changes scoped and explain their impact on UX, DX and AX.
- Preserve existing behavior unless a deliberate change is documented.

## Required quality checks

For documentation changes:
- Check links and headings.
- Use consistent terminology.
- Mark assumptions and unresolved decisions.
- Update the relevant version or change history.

For future code changes:
- Add tests for new behavior.
- Run formatting, static analysis and automated tests.
- Include save-data migration tests when schemas change.
- Verify the game remains usable without an LLM connection.

## Commit messages

Use concise, imperative commit messages. Suggested prefixes:
- `docs:`
- `feat:`
- `fix:`
- `refactor:`
- `test:`
- `build:`

## Pull request checklist

- [ ] Scope and rationale are clear.
- [ ] UX, DX and AX implications are considered.
- [ ] Existing behavior is preserved or intentionally changed.
- [ ] Tests/checks are reported accurately.
- [ ] Documentation and ADRs are updated where needed.
- [ ] No secrets or unnecessary dependencies are included.
