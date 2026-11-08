# CI and Release Policy

**Policy version:** 0.3.0

| Workflow | Trigger | Work | Output |
|---|---|---|---|
| CI | PRs and pushes to main/develop on project paths | Pinned Godot import/parse and headless tests | Check only; no build files |
| Development Release | Push to develop on runtime paths or manual dispatch | Tests, Windows x86_64 export, publish prerelease | GitHub Release assets |

## Storage and runtime controls
- Never use Actions artifact upload/download actions.
- Never cache Godot binaries, export templates, .godot/ or build output.
- Download the pinned engine per runner and discard it after the job.
- Publish only final ZIP and SHA-256 checksum to GitHub Releases.
- One Ubuntu runner per job; no OS matrix or parallel export.
- CI timeout: 10 minutes. Development release timeout: 20 minutes.
- Cancel superseded runs on the same ref.
- No scheduled builds. Android and Web exports remain excluded until platform gates.

## Development workflow
1. Feature branches open PRs to develop.
2. CI validates changes without producing downloadable build artifacts.
3. Merge to develop when a shareable development build is wanted.
4. Development Release reruns tests, exports Windows x86_64 and publishes a GitHub prerelease.
5. Open a PR from develop to main when a milestone is ready.

develop is the integration branch. main remains the stable baseline. Stable 1.0.0 must not be tagged or merged to main until the manual acceptance checklist passes and the owner approves the release.
