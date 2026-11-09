# First Spark — 1.0.0 acceptance checklist

**Candidate:** 1.0.0-rc.2  
**Target:** Windows desktop  
**Stable release rule:** Do not publish 1.0.0 until every required check passes and critical/high-severity defects are fixed.

## 1. Install and launch
- [ ] Download the Windows ZIP from the candidate GitHub Release.
- [ ] Verify the ZIP against the published SHA-256 checksum.
- [ ] Extract to a writable folder and launch EchoesOfTomorrow.exe.
- [ ] Confirm the game opens without errors, missing content or a blank screen.
- [ ] Resize the window between 1280×800, 1440×900 and a narrow window.
- [ ] Confirm the settlement remains visible and HUD/context panels remain readable.

## 2. World presentation and controls
- [ ] Confirm the isometric settlement is the default screen, not a dashboard or blank canvas.
- [ ] Drag open ground to pan; confirm a click without dragging selects an entity.
- [ ] Zoom with the mouse wheel and with plus/minus; confirm zoom stays bounded and keeps the cursor area anchored.
- [ ] Pan with WASD and arrow keys.
- [ ] Inspect the terrain, paths, river, crop furrows, trees, farmstead, bridge, well and fences; check for gaps, overlaps or misaligned sprite anchors.
- [ ] Select the farmstead and each built facility; confirm selected outlines and contextual details match the selected object.
- [ ] Select all five named villagers; confirm the People view and dialogue remain reachable.
- [ ] Advance time through morning, afternoon and night; confirm the world lighting transition does not reduce UI readability.
- [ ] Resize to a narrow window; confirm world interaction is not blocked by the HUD or contextual panel.

## 3. First session
- [ ] Confirm the settlement starts with 25 residents and six resources.
- [ ] Advance one hour and one day; confirm time and resources update.
- [ ] Open Settlement, People, Knowledge and Chronicle.
- [ ] Select each named NPC and send a question.
- [ ] Confirm replies are readable and reflect recorded memories when available.
- [ ] Confirm conversations do not change resources, relationships or simulation time.

## 4. Historical decisions
- [ ] Advance to the harvest crisis.
- [ ] Inspect the choices and their costs before selecting one.
- [ ] Resolve the event and confirm its resource and NPC consequences.
- [ ] Advance to the village compact follow-up and resolve it.
- [ ] Confirm History records original and selected outcomes.

## 5. Knowledge and production
- [ ] Study selective seed cultivation.
- [ ] Build and test the improved seed-selection prototype.
- [ ] Commission production and produce the first batch at the farmstead.
- [ ] Confirm the First Spark objective completes.
- [ ] Confirm an invention cannot produce without its required facility.
- [ ] Build a workshop or forge when prerequisites and materials are available.
- [ ] Confirm construction costs are deducted exactly once.

## 6. Save and recovery
- [ ] Save after making progress.
- [ ] Advance time and change resources; save again.
- [ ] Close and relaunch the game; load the campaign.
- [ ] Confirm time, resources, NPC memories, facilities, inventions and timeline restore.
- [ ] Confirm a previous save is retained as a backup after a second save.
- [ ] In a disposable test copy only, corrupt the active save and confirm the backup loads with a visible recovery message.
- [ ] Confirm missing or invalid active and backup files fail safely.

## 7. Release blockers
- [ ] No crash, data loss, softlock or unrecoverable save issue.
- [ ] No critical/high-severity UX issue blocks the campaign path.
- [ ] No incorrect resource totals, duplicate construction charges or invalid objective completion.
- [ ] Offline play works without network access or provider credentials.
- [ ] Record screenshots and reproduction steps for every defect.

## Result
- [ ] PASS — stable 1.0.0 may be approved.
- [ ] FAIL — fix issues and publish another release candidate.

Do not use a real campaign save for deliberate corruption tests. Back up the test save first.
