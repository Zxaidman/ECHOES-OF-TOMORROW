# CI and Release Policy

**Policy version:** 0.2.0

## Workflow responsibilities

| Workflow | Trigger | Work | Output |
|---|---|---|---|
| CI | Pull requests and pushes to main/develop affecting project files | Download pinned Godot, import/parse, run headless tests | GitHub check only; no build files |
| Development Release | Push to develop affecting runtime files, or manual dispatch | Run tests, export Windows x86_64, create prerelease | GitHub Release assets |

## Storage rules

- Never use actions/upload-artifact or actions/download-artifact.
- Never upload game builds as Actions artifacts.
- Never cache Godot binaries, export templates, .godot/, or build output.
- CI downloads the pinned engine at runtime and discards it with the runner.
- Development ZIP and SHA-256 checksum are attached directly to a GitHub prerelease.
- Do not upload intermediate folders, PCKs, logs or duplicate archives.
- Release assets are separate from Actions artifact storage; keep packages small and prune obsolete prereleases periodically.

## Runtime/minute controls

- One Ubuntu runner per workflow; no OS matrix or parallel export.
- CI timeout: 10 minutes. Development release timeout: 20 minutes.
- Concurrency cancels superseded runs on the same ref.
- CI runs only when project/runtime/test/workflow paths change.
- Development packages are generated only from develop, or by explicit manual dispatch.
- No scheduled builds.
- Android and Web exports are intentionally excluded from this milestone.

## Development workflow

1. Work on feature branches and open PRs to develop for iterative development.
2. CI validates changes without generating downloadable builds.
3. Merge to develop when a shareable development build is wanted.
4. Development Release tests again, exports Windows x86_64 and creates a GitHub prerelease tagged v<version>-dev.<run_number>.
5. Open a PR from develop to main when the milestone is ready for review.

The develop branch is the integration branch for development builds. main remains the stable baseline.

## Security

- CI uses contents: read; release workflow alone uses contents: write.
- No personal access token or third-party release action is required; release creation uses GITHUB_TOKEN through GitHub CLI.
- Never commit provider API keys or signing credentials.
- Third-party actions must be pinned to a full commit SHA.
