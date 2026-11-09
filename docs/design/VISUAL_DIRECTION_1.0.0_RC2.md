# Visual Direction and Rendering Plan

**Document version:** 1.0.0-rc.2  
**Target:** First Spark visual and gameplay overhaul

## Chosen direction

**Isometric 2.5D, hand-painted medieval settlement, restrained dark outlines.**

The settlement is the game. The first screen must show a place that appears inhabited, not a data dashboard. The art should feel warm, tactile and historically grounded without pursuing photorealism.

## Camera and world

- Isometric/diamond-grid composition with a fixed 3/4 camera.
- Use Godot 2D rendering with layered sprites, not a full 3D simulation.
- Use `TileMapLayer` for terrain and grid-aligned ground features.
- Use Y-sorting or explicit depth layers for buildings, characters and props.
- Keep simulation state authoritative and independent of render frame timing.
- Camera pan/zoom must be bounded, smooth and usable with mouse and keyboard.
- Support selection, hover feedback and contextual inspection.

## Art treatment

- Hand-painted textures with readable silhouettes.
- Muted earth, timber, stone, foliage and warm cloth palette.
- Fine, restrained dark contour outlines around major forms.
- Avoid thick black cartoon strokes and noisy outlines on every small detail.
- Keep selected/hovered outlines visually distinct from permanent art contours.
- Use layered foliage, smoke, water, flags, fire and ambient details to create motion.

## Outline rendering

Preferred order:
1. Author clean sprite contours during asset creation when the source art supports it.
2. Use `game/presentation/shaders/sprite_outline.gdshader` for selected sprites that need a consistent contour.
3. Use a duplicate enlarged silhouette only when shader bounds or texture padding make the shader unsuitable.
4. Do not use a full-screen Sobel/post-process outline as the default. It outlines UI and background noise, costs fill-rate and makes the scene visually busy.

The shared shader samples the source alpha around the current texel. Sprite textures must include transparent padding at least as wide as the requested outline; otherwise the outline can be clipped at the sprite quad boundary. Validate with transparent PNG sprites at multiple scales and with nearest/linear filtering before applying globally.

## Lighting and finish

- Use a restrained palette and consistent value hierarchy before adding effects.
- Day/night should be a world-level colour and light transition, not a full-screen filter that harms UI contrast.
- Use soft cast shadows only where the asset/render path supports them cheaply.
- Add ambient animation: smoke, water, foliage, flags, fire, clouds and idle NPC motion.
- Use particles sparingly for rain, sparks, dust and construction.
- Use camera easing and small impact feedback on meaningful actions; avoid constant screen shake.

## Interaction model

- World view is the default and primary screen.
- Top HUD: compact resources, time, simulation speed and alerts.
- Select a building: contextual panel with status, production, costs and actions.
- Select an NPC: portrait/profile, current activity, needs, relationship and dialogue.
- Build mode: ghost preview, valid/invalid placement feedback, cost and confirmation.
- Events: focused decision panel with consequence preview where known.
- Knowledge and invention: dedicated secondary workspace, not permanent dashboard tabs.

## Design tokens

Define reusable theme resources/tokens for:
- Palette: parchment, ink, timber, stone, moss, water, ember, danger.
- Typography: readable display face and neutral UI face; verify font licences.
- Spacing: 4/8/12/16/24/32 px rhythm.
- Surfaces: world HUD, contextual panel, modal, tooltip, notification.
- States: idle, hover, selected, pressed, disabled, warning, error, success.
- Motion: quick input response, short panel transitions, slower world ambience.

Do not add explanatory helper copy to compensate for weak hierarchy. Use clear labels, iconography, grouping and visible consequences.

## Open-source asset policy

Evaluate assets from Kenney, OpenGameArt and other open libraries as candidates, not as assumed production-ready content. Record the exact source URL, creator, licence, attribution requirements, modification status and files used. Prefer CC0 or permissive licences. Do not mix incompatible licences or redistribute assets without checking their terms.

## Rendering performance

- Prefer atlases and shared materials.
- Avoid one unique material/shader instance per sprite where shared parameters suffice.
- Use culling and bounded world visibility.
- Avoid excessive transparent overdraw and large full-screen effects.
- Profile at target window sizes before adding post-processing.
- Preserve the compatibility renderer unless a measured feature requirement justifies changing it.

## Acceptance criteria for the visual milestone

- Launch opens directly into a recognisable settlement scene.
- At least the farmstead, terrain, paths, vegetation and a small number of props are visually present.
- At least one NPC is visible and has an idle/walk/work animation loop.
- Camera movement and object selection work.
- Selected objects have a clear outline/highlight that does not clip.
- Resource/time HUD is compact and does not dominate the world.
- One meaningful action has visible world feedback.
- Existing deterministic simulation, dialogue, saves, migrations and tests remain intact.
- Windows export remains functional.
