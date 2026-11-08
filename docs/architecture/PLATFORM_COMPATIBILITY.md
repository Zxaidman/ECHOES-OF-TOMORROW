# Platform Compatibility Strategy

**Document version:** 0.1.1  
**Status:** Approved target order; compatibility remains subject to export and device testing.

## 1. Target order

1. Windows desktop — first supported development and release target.
2. Android — second target, with touch-first UX and performance budgets.
3. Web — later target, only after a browser export and performance feasibility gate.

This order is intentional. Do not let speculative Web requirements slow the first playable Windows slice, but avoid architecture choices that unnecessarily close the option.

## 2. Engine and language implications

The project uses Godot 4.7.2-stable and typed GDScript. GDScript keeps the project on Godot's native scripting path and avoids the Godot 4 C# Web-export limitation. This does not mean every plugin, rendering feature or operating-system integration works identically on all platforms.

## 3. Portability rules

- Keep domain and simulation code independent of platform APIs.
- Use Godot's portable input, file and networking abstractions.
- Store writable data under user://, never attempt to write into res://.
- Keep provider credentials out of client builds.
- Avoid native plugins and GDExtensions in the core game.
- Isolate any platform-specific behavior behind a small adapter.
- Do not assume desktop mouse/keyboard interactions translate directly to touch.
- Use responsive containers, scalable typography and input abstraction.
- Use the Compatibility renderer for Web feasibility work.
- Treat browser storage quotas, cache behavior, CORS and network interruption as first-class constraints.

## 4. Platform gates

### Windows
- Import and run with the pinned Godot version.
- Headless tests pass.
- Desktop export launches on a clean machine.
- Keyboard and mouse navigation are complete.
- Save/load survives restart and invalid-save cases.

### Android
- Native export succeeds with documented SDK/JDK/template versions.
- Test on at least one lower-mid-range and one modern device.
- Touch targets and layout work in portrait and landscape where supported.
- Pause/resume, app backgrounding, storage permissions and save durability are tested.
- CPU, memory, battery and thermal behavior meet the defined budget.

### Web
- Export with Compatibility renderer.
- Validate current Chromium and Firefox desktop browsers; mobile browser support is a separate gate.
- Confirm WebAssembly and WebGL 2 availability.
- Measure initial download size, startup time, memory and simulation performance.
- Test browser refresh, tab suspension, storage persistence and network loss.
- Confirm AI requests work through the controlled backend with correct CORS and authentication.
- Do not promise Web support until these checks pass.

## 5. Rendering and gameplay implications

The first slice is a strategy simulation with modest real-time visual demands. Prefer UI clarity and deterministic simulation over expensive rendering. Keep the world presentation separable from the domain model so a lower-cost mobile/Web presentation can be introduced without rewriting game rules.

## 6. Release policy

A platform is supported only when its gate is green in CI or documented manual device testing. "It exports" is not equivalent to "it is supported." Keep a platform compatibility matrix in release notes.
