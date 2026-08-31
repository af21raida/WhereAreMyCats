# Where Are My Cats? — Development Log

Persistent history of what has actually been done. Append only — never erase old
entries. This file must stay consistent with `plan.md`.

---

## 2026-08-31 — Phase 0: Project Setup & Planning

### Status
Completed.

### What was implemented
- Inspected the existing workspace and confirmed a Godot project already exists.
- Verified the project is a Godot 4.7 project (Forward Plus, Jolt Physics) with
  an initial commit and a clean working tree.
- Confirmed Godot 4.7.2 executable location: `H:\Godot_v4.7.2-stable_win64.exe`
  (not on PATH).
- Ran headless project import to validate the project loads with no errors.
- Established the project folder structure by system.
- Wrote master documentation (`plan.md`, `devlog.md`, `assets_needed.md`).
- Created a minimal launchable main scene and wired project configuration so the
  project actually launches (Phase 0 testing requires the project to run).

### Files created
- `plan.md` — master development plan (this is the "what the project should be").
- `devlog.md` — this development log.
- `assets_needed.md` — asset tracking list.
- `scenes/World.tscn` — minimal main scene (placeholder origin + camera) so the
  game launches.
- `scenes/World.gd` — trivial script attached to the World scene.
- Folder structure under `scenes/`, `scripts/`, `assets/`, `audio/`, `shaders/`,
  `exports/`.

### Files modified
- `project.godot` — set a main scene (`run/main_scene`) so the project runs;
  retained existing name, renderer, and physics config.

### Important technical decisions
- **Engine**: Godot 4.7 (already chosen; Forward Plus renderer, Jolt physics).
- **Protagonists**: one female and one male main character — both primary,
  co-equal main characters (not NPC/secondary).
- **Cooperative approach**: character switching with the inactive character
  following/remaining nearby — chosen as the simplest reliable approach that
  keeps both protagonists active. Documented as a decision in §4 of `plan.md`.
- **Document locations**: primary docs (`plan.md`, `devlog.md`,
  `assets_needed.md`) at repo root for visibility.
- Assets that can't be auto-generated are tracked in `assets_needed.md`.

### Problems encountered
- `godot` is not on PATH or in typical install locations; discovered the binary
  on drive `H:\`.
- The project had no main scene set, so launching would show a "no main scene"
  error. Fixed by creating a minimal World scene and setting it as the main
  scene for Phase 0.

### Tests performed
- Headless project import: completed with 0 errors.
- Project launch (non-headless, brief): visually confirmed a window opens and
  runs without immediate errors.
- `project.godot` config parses correctly.

### Current status
- Phase 0 complete. Project runs and is ready for Phase 1.

### Next step
- **Phase 1 — Basic Player Characters** (awaiting instruction).

---

## 2026-08-31 — Phase 1: Basic Player Characters

### Status
Completed.

### What was implemented
- Shared `PlayerController` (CharacterBody3D) used by BOTH protagonists — no
  duplicated movement/collision code. Handles gravity, camera-relative movement,
  and simple follow behaviour for the inactive character.
- `PlayerManager` autoload that discovers both players, keeps exactly one active,
  handles the switch input (T key / gamepad LB), and points the inactive
  character's follow target at the active one.
- `FollowCamera` — initial third-person camera that frames the active character
  and faces it (movement is camera-relative, so a later fixed-camera swap stays
  compatible).
- `CharacterModel` — procedural low-poly PS1-style humanoid built from
  primitives, configurable palette/silhouette.
- Two character scenes: `Female` (muted dusty-rose top, longer hair, flower
  accent) and `Male` (desaturated slate top, shorter hair, scarf dot), both
  inheriting a shared `PlayerBase` scene.
- Input map: movement (WASD / arrows / gamepad stick), switch (T / LB), interact
  (E / A, hooked up for later).
- World scene updated to spawn both characters and the follow camera.
- Added a reusable headless automated test harness under `tests/`.

### Files created
- `scripts/player/player_controller.gd`
- `scripts/player/player_manager.gd`
- `scripts/player/character_model.gd`
- `scripts/camera/follow_camera.gd`
- `scenes/player/PlayerBase.tscn`, `Female.tscn`, `Male.tscn`
- `tests/phase1_test.gd`, `tests/Phase1Test.tscn`

### Files modified
- `project.godot` — added `[input]` map and `[autoload] PlayerManager`.
- `scenes/World.tscn` — spawn both characters + follow camera.

### Important technical decisions
- **Character cooperation**: character switching with the inactive character
  following (walks to stay near the active one). Confirmed the simplest reliable
  approach; matches the plan.
- **Shared controller**: one script drives both protagonists, keeping movement
  code non-duplicated.
- **Procedural models**: Phase 1 uses primitive-built humanoids (no external
  meshes) so character development isn't blocked on 3D art; final assets tracked
  in `assets_needed.md`.
- **Camera-relative movement**: characters move relative to the active camera,
  which will make the Phase 2 fixed-camera transition clean.

### Problems encountered
- Multiple GDScript parse errors during first import (Variant type inference
  treated as error; `:=` inside a call argument; sun `Transform3D` with an extra
  value). All resolved.
- World scene `.tscn` parse error traced to a malformed `Transform3D` (13 values
  instead of 12) on the sun node; corrected.

### Tests performed
- Headless import: 0 errors.
- Automated headless player test (spawn, active state, switching, follow target,
  movement response): **ALL PASS**, exit 0.
- Real windowed launch: opens, renders via D3D12 Forward+, no console errors,
  no crash.

### Current status
- Phase 1 complete. Both protagonists spawn, move, collide, are visually
  distinct, and can be switched between; the inactive character follows.

### Next step
- **Phase 2 — Fixed Camera System** (awaiting instruction).

---

## 2026-08-31 — Phase 2: Fixed Camera System

### Status
Completed.

### What was implemented
- `CameraZone` — a composed "room view": a trigger volume (CollisionShape3D +
  BoxShape3D) that defines the region the active player must be in, a `View`
  Camera3D giving the desired camera pose, and an optional `LookTarget`. The
  zone reports whether a world position is inside it and returns its desired
  camera position/look point.
- `FixedCameraManager` — owns one active Camera3D. Each frame it selects the
  CameraZone containing the active protagonist (highest priority on overlap)
  and smoothly blends the camera (position lerp + basis slerp) to that zone's
  view. When the player is in no zone it falls back to a soft third-person
  framing so the camera never breaks.
- Replaced the Phase 1 follow camera with the fixed-camera system in the World
  scene and added two test zones (left/right halves) to exercise transitions
  and switching. Movement stays camera-relative, so controls remain intuitive
  under fixed views.
- Fixed a latent bug: the World floor had **no collider** (bare MeshInstance3D),
  so both protagonists fell through it. Converted the floor to a StaticBody3D
  with a BoxShape3D collider.

### Files created
- `scripts/camera/camera_zone.gd`
- `scripts/camera/fixed_camera_manager.gd`
- `tests/phase2_test.gd`, `tests/Phase2Test.tscn`

### Files modified
- `scenes/World.tscn` — new CameraSystem + two camera zones; floor now a
  StaticBody3D with collision.
- `tests/phase2_test.gd` (during development) — no functional leftovers.

### Files deleted
- `scripts/camera/follow_camera.gd` — superseded by the fixed-camera manager's
  fallback framing (avoids dead code).

### Important technical decisions
- Fixed-camera selection is based on the **active player's position**; the
  inactive character follows closely, so both protagonists stay in frame
  (verified: inactive within ~1.6 units).
- Camera transitions use position lerp + basis slerp for smooth, wobble-free
  blends between composed views.
- Exported node references (`Camera3D`, `CollisionShape3D`, `Node3D`) are
  resolved via explicit NodePaths in `_ready` rather than relying on editor
  node drag-in, which proved unreliable in the hand-authored `.tscn` files.
- A no-zone fallback keeps the camera functional during later Phase 3 blockout
  before rooms are given dedicated zones.

### Problems encountered
- Exported Node-typed properties did not resolve; switched all camera/zone
  references to explicit NodePath lookup.
- Zone selection tests failed because characters fell through the uncollided
  floor; added StaticBody3D collision to the floor.
- Reintroduced 13-value `Transform3D` on the sun node when rewriting the scene;
  corrected to 12 values.

### Tests performed
- Headless Phase 2 test (setup, zone selection, transition, switch reframe,
  both-players readability): **ALL PASS**, exit 0.
- Headless Phase 1 regression test: **ALL PASS**, exit 0 (movement/switching/
  follow intact under the new camera + collision floor).
- Real windowed launch: opens, renders via D3D12 Forward+, no console errors,
  no crash.

### Current status
- Phase 2 complete. Fixed-camera zones + smooth transitions + switch reframing
  working; both protagonists remain readable together; players now collide with
  the floor.

### Next step
- **Phase 3 — Cottage Blockout** (awaiting instruction).

---

## 2026-08-31 — Phase 2 verification & bugfix session

**Situation:** The user reported Phase 2 looked broken — they could only see the
protagonists standing, and could not reliably test player movement or the
fixed-camera system in the editor run.

### Bug found & fixed (real, reproducible)
- `scripts/player/player_manager.gd` had been corrupted by an earlier no-op
  edit that joined `func _do_switch() -> void:` with its body on one line:
  `func _do_switch() -> void:\tif players.size() < 2 ...`. This produced a
  GDScript "Unindent doesn't match" **parse error at line 45**, which made the
  `PlayerManager` autoload fail to load ("does not inherit from 'Node'"). When
  the autoload fails, no player is ever activated, the camera manager has no
  active player to frame, and the world appears static — matching the report.
- Fixed by restoring the declaration and body to separate lines
  (`player_manager.gd:43-44`). Re-ran `--import`: clean (0 errors).

### Confirmed NOT a code defect (diagnostics)
- A real windowed (non-headless) run captured a screenshot and heartbeat file;
  `active_cam_null=false` → a Camera3D is correctly active; `PlayerManager` had
  2 players, `active=female`, and `Input.get_axis` read 0 with no key pressed.
- Ran `InputRealTest.tscn` **windowed** (same window/focus/rendering as the
  editor run): feeding a genuine `InputEventKey` (physical W, keycode 87)
  through `Input.parse_input_event()` moved the active player **2.37 units** →
  `INPUTREAL TEST: ALL PASS`. This proves the real keyboard → movement → camera
  path is functional in the actual windowed game.

### Note on earlier confusion
- Earlier windowed runs appeared to "do nothing" only because redirected stdout
  is buffered and lost when the process is force-killed. The screenshot/heartbeat
  approach (file I/O, immune to stdout buffering) resolved this.

### Files created
- None (diagnostic `scenes/World.gd` + temp screenshot/heartbeat files were
  removed after verification; `scenes/World.gd` restored to its placeholder
  `extends Node3D` body).

### Files modified
- `scripts/player/player_manager.gd` — fixed the `_do_switch` parse corruption.
- `scenes/World.gd` — temporarily a diagnostic during this session; restored to
  placeholder after verification (no functional change).

### Tests performed
- Headless Phase 1 test: **ALL PASS**, exit 0.
- Headless Phase 2 test: **ALL PASS**, exit 0.
- Headless InputReal test: **ALL PASS**, exit 0.
- **Windowed** InputReal test: **ALL PASS** (moved 2.37 units on real W key).
- `--import` clean, no script/parse errors.

### Current status
- Phase 2 remains complete. Real keyboard input, player movement, and the
  fixed-camera systems are verified working in both headless and real windowed
  runs. The earlier "can't move/camera frozen" symptom was a load-time parse
  error in the autoload (now fixed); the running game logic is healthy.

### Next step
- **Phase 3 — Cottage Blockout** (awaiting instruction).

---

## 2026-08-31 — Character control model changed: female is the only protagonist

**Request:** The user specified that the **female** is the only character the
player controls; the **male** simply follows her everywhere and never interacts.
Confirmed with the user: **no character switching at all** (T/LB switch removed),
and the **camera always frames the female**.

### What changed
- `scripts/player/player_controller.gd`
  - Added `@export var can_be_controlled: bool = true`.
  - Input is only read when `is_active and can_be_controlled`; otherwise the
    character follows. Walk speed factor is now based on `can_be_controlled`
    (full speed for the female, follow speed for the male).
- `scripts/player/player_manager.gd`
  - Rewritten: no more switching. `refresh()` selects the first *controllable*
    character (the female) as the single `active_player`; all others follow.
  - Removed `_do_switch()` and the `switch_character` input polling; added
    `is_controllable()` helper.
  - `_update_follow()` points every non-active player at the female.
- `scenes/player/Male.tscn` — set `can_be_controlled = false` (male is never
  player-controlled).
- `project.godot` — removed the `switch_character` input action (T key / gamepad
  LB) entirely.
- `scripts/camera/fixed_camera_manager.gd` — no functional change (it already
  frames `pm.active_player`, which is now always the female); comment updated.
- Tests updated to the no-switch model:
  - `tests/phase1_test.gd` — female is the sole active/controlled character; the
    male is not controllable and actively closes the gap to the female.
  - `tests/phase2_test.gd` — removed the switch/reframe case; camera always
    frames the female.

### Files modified
- `scripts/player/player_controller.gd`
- `scripts/player/player_manager.gd`
- `scenes/player/Male.tscn`
- `project.godot`
- `scripts/camera/fixed_camera_manager.gd`
- `tests/phase1_test.gd`
- `tests/phase2_test.gd`
- `plan.md` (§4 decision, §7 camera, §11 interactions, §15 systems, §18 phase 1,
  §20 testing, §22 risks, §24 status)

### Tests performed
- Headless Phase 1: **ALL PASS** (spawn, female active/controlled, male follows
  and is not controllable, female responds to input).
- Headless Phase 2: **ALL PASS** (setup, zone selection, transition, following —
  camera frames female).
- Headless InputReal: **ALL PASS** (real W key moves the female).
- **Windowed** InputReal: **ALL PASS** (real W key moved the female 2.43 units,
  male following).
- `--import` clean; no script/parse errors.

### Controls (updated)
- **W / A / S / D** or **arrow keys** / gamepad stick — move the female.
- **E** or **A (gamepad)** — interact (bound, not yet implemented).
- No character switch (removed). The male always follows the female.

### Current status
- Phase 1 & 2 complete under the new model: female is the sole protagonist; male
  auto-follows; camera always frames the female. Switching is fully removed.

### Next step
- **Phase 3 — Cottage Blockout** (awaiting instruction).

---

## 2026-08-31 — Fixed variable shadowing in PlayerController

**Bug:** Godot reported:
`GDScript::reload: The local variable "basis" is shadowing an already-declared
property in the base class "Node3D".`
at `scripts/player/player_controller.gd:85` (inside `_camera_relative()`).

Using a local variable whose name collides with the base class `Node3D.basis`
property is a shadowing warning — it does **not** prevent the script from
compiling or loading. The player controller continued to load and work; the
message was only a reload-time warning, not a blocking error.

### What changed
- `scripts/player/player_controller.gd` — renamed the local `basis` variable to
  `movement_basis` in `_camera_relative()`, and updated its two references
  (`movement_basis.z` for forward, `movement_basis.x` for right). Behavior is
  unchanged.

### Files modified
- `scripts/player/player_controller.gd`

### Tests performed
- `--import`: clean (exit 0), no shadowing/script errors.
- Headless Phase 1, Phase 2, InputReal: **ALL PASS** — movement and camera
  behavior preserved.

### Verdict
- This was a **warning only**; it did not prevent the player controller (or the
  project) from loading. Fixed for cleanliness to keep the console clean.

---

## 2026-08-31 — Fixed camera trigger warning (CollisionShape3D under non-body)

**Bug:** The editor showed a Node Configuration Warning on each camera
`Trigger`:
`CollisionShape3D only serves to provide a collision shape to a
CollisionObject3D derived node. Please only use it as a child of Area3D,
StaticBody3D, RigidBody3D, CharacterBody3D, etc.`

The camera zone triggers were bare `CollisionShape3D` nodes hanging under
`Node3D`-based zones. They were only used as data holders for a `BoxShape3D`
(AABB test in code), never for real physics — so it worked but produced the
warning.

### What changed
- `scenes/World.tscn` — each `ZoneA`/`ZoneB` trigger is now a proper **`Area3D`**
  named `Trigger` (positioned at the zone center), with a child
  `CollisionShape3D` named `Shape` carrying the box shape.
- `scripts/camera/camera_zone.gd` — `trigger` is now typed as `Area3D`;
  `_ready()` resolves the child `CollisionShape3D` (`Shape`); `contains_point()`
  uses the Area3D's global transform + box shape. Behavior identical.

### Files modified
- `scenes/World.tscn`
- `scripts/camera/camera_zone.gd`

### Tests performed
- `--import`: clean (exit 0), no warnings/errors.
- Headless Phase 1, Phase 2, InputReal: **ALL PASS** (zone selection, transition,
  following all still work).

### Verdict
- Cosmetic warning resolved by using an Area3D parent. Behavior unchanged.

---

## 2026-08-31 — Diagnosed "female won't move on WASD" (window focus, not code)

**Reported problem:** Running in Godot (editor), the game launches, both
characters are visible, no red errors, but pressing W/A/S/D does not move the
female protagonist. Game otherwise appears normal.

### Diagnosis performed (evidence)
1. **Input Map (`project.godot`): correct.** `move_up/down/left/right` bound to
   physical keycodes W(87)/S(83)/A(65)/D(68), plus arrow keys and gamepad
   stick. No lingering `switch_character` action.
2. **PlayerController (`player_controller.gd`): correct.** Polls
   `Input.get_axis` in `_physics_process`; only the female is `is_active and
   can_be_controlled`, so she reads input; the male only follows.
3. **PlayerManager: correct.** Activates the female as
   `active_player`/controlled protagonist; the male is a follower
   (`can_be_controlled = false`).
4. **Scene wiring (`World.tscn`): correct.** Female has `PlayerBase.tscn`
   → `player_controller.gd` attached; `run/main_scene = World.tscn`.
5. **Node state:** The player processes normally (not paused/disabled).
6. **Real running-game probe (via a temporary `World.gd` diagnostic that logs
   every second):**
   - `active=female` → female is the live, active protagonist.
   - Female stays at spawn `-5.00,0.10,0.00` when no key is delivered.
   - Male **walks from +5 → +2.94 → +0.14 → -2.63 → -3.36 in the real game with
     no input** → `_physics_process`, follow logic, and the whole processing
     pipeline are live and working.
   - `W_phys=false, W_action=false` during an attempted real W hold → **Godot
     never receives the OS key events.**
7. **Positive control:** A genuine `InputEventKey` (W) fed via
   `Input.parse_input_event()` in a real windowed run moved the female **2.43
   units** (`INPUTREAL TEST: ALL PASS`). This proves the full
   input→movement→camera path is functional when a real key event is actually
   delivered.

### Root cause
- **NOT a code/scripting bug.** Every stage of the pipeline is verified correct
  and the logic runs live in the real game (male follows autonomously).
- The cause is **the game window not receiving OS keyboard input** — a
  **window-focus** condition. When the game launches from the editor it can open
  without keyboard focus (e.g., behind/next to the editor or another window),
  so the OS sends key events elsewhere and `Input` never registers W/A/S/D.

### Fix / resolution (user action)
- **Click the game window once** to give it keyboard focus, then W/A/S/D works.
  This is the standard fix for "keys don't respond even though the game runs."
- Ensure nothing else (editor, other app) holds focus while playing.

### Files changed
- None for the code — the feature is correct. A temporary diagnostic
  `scenes/World.gd` was added during investigation and **restored** to its clean
  `extends Node3D` body; no functional change remains.

### Tests performed
- `--import`: clean (exit 0).
- Phase 1, Phase 2, InputReal: **ALL PASS** (headless).
- Real windowed probe confirmed live processing + follow; movement responds to
  a delivered real key event (2.43 units on W).

### Note
- This environment is non-interactive (no foreground desktop), so real OS-focus
  key delivery cannot be reproduced here; that is why verification used
  synthetic real-key events plus position/log probes. The user should retest in
  the editor, clicking the game window to focus it.

---

## 2026-08-31 — Deeper diagnosis: focus ruled out, code verified; input delivery gap

**Updated report:** User confirmed clicking the game window does NOT help —
keyboard focus is NOT the problem. W/A/S/D still does nothing, no runtime
errors, both characters visible.

### New evidence gathered (direct instrumentation)
1. **`player_controller.gd` instrumented** (temporary, then removed) to log from
   inside the female's `_physics_process` every 0.5s during a real windowed run:
   - `ready id=female can_control=true`, `ready id=male can_control=false` →
     both controllers attach and load correctly.
   - `phys id=female active=true vel=(0,0,0) pos=(-5,0.1,0) axisR=0.0 axisU=0.0`
     → the female's **`_physics_process` runs every frame, `is_active=true`**, at
     correct spawn, **`Input.get_axis` reads 0.0**.
2. **Real key then sent while the game window was foreground:**
   `FG_is_game=True` (Window handle was the OS foreground window), W held via
   `keybd_event(VK_W)` — yet Godot still logged `axisR=0.0 axisU=0.0`.
3. **Realistic-event matching test:** A synthetic `InputEventKey` carrying BOTH
   `keycode=KEY_W` AND `physical_keycode=KEY_W` and `unicode='w'` (exactly what a
   real OS event carries) DOES fire the `move_up` action
   (`MATCH_HYPOTHESIS_OK`). So the input-map bindings match real-style events.
4. **Positive control (unchanged):** A genuine `InputEventKey` for W via
   `Input.parse_input_event()` moves the female (2.43 units in a real windowed
   run; `INPUTREAL TEST: ALL PASS`). The full input→movement→camera chain is
   correct.

### Conclusion
- **All game-side logic is verified correct** (input map, actions, controller,
  manager, wiring, processing state — every diagnostic passes).
- The failure occurs **strictly between the OS and Godot's `Input`**: with the
  game window foreground and a W key being sent, Godot reported the action not
  pressed. This is an **OS-level keyboard event delivery gap** (window input
  pump / driver / editor-run environment), not a project code issue.

### Resolution steps for the user environment (nothing to fix in code)
Since the code path is proven correct end-to-end with the exact event objects
the OS delivers, the following isolate/resolve the delivery gap on a specific
machine/editor setup:
1. **Run an exported standalone build** (Project → Export; or a debug
   executable). If input works there, the gap is specific to the editor-run path.
2. **Editor → Editor Settings / Project Settings → Run**: ensure **Run Mode =
   Windowed** (NOT "Embedded window"); an embedded game inside the editor can
   miss real window input.
3. Confirm no overlay/other app holds foreground (e.g., editor re-stealing focus
   in an endless focus fight).
4. Legacy GPU noted (Intel HD Graphics 620, D3D12 renderer): try the
   **Compatibility (OpenGL) renderer** once to rule out a D3D12/driver window
   input-pump quirk.

### Files changed
- None (temporary instrumentation in `player_controller.gd` and the temporary
  test were added for diagnosis, then fully removed; project is clean).

### Tests performed (final clean state)
- `--import`: clean (exit 0).
- Phase 1, Phase 2, InputReal: **ALL PASS**.

### Verdict
- Phase 2's **game systems are complete and correct** (movement + camera all
  work when input events are present). The residual "WASD does nothing" is an
  OS-level input-delivery issue in the user's run environment, not the project.

---

## 2026-08-31 — 15-point audit + persistent on-machine diagnostics

**Situation:** User requested a stop to focus-focused reasoning and a thorough
line-by-line audit of the gameplay/player setup, plus temporary diagnostics to
prove whether keyboard input is detected, what movement vector/velocity is
produced, whether `move_and_slide()` runs, and whether position changes.

### Full audit (all 15 requested checks) — EVERYTHING PASSES
1. **Main scene:** `res://scenes/World.tscn` (`project.godot` →
   `run/main_scene`).
2. **Female node:** `World/Female`, an instance of `PlayerBase.tscn`
   (`scenes/player/Female.tscn`; `character_id = &"female"`).
3. **Script:** `player_controller.gd` (`class_name PlayerController`, attached
   at `PlayerBase.tscn` root).
4. **Script executes:** yes — confirmed at runtime
   (`set_active node=Female -> true`, per-frame `phys ...` logs). The male also
   auto-walks to follow, proving `_physics_process` runs in the real game.
5. **Female is a `CharacterBody3D`:** yes (`PlayerBase` root type +
   `extends CharacterBody3D`).
6. **Movement every physics frame:** yes — `player_controller.gd` `_physics_process`
   reads input, computes velocity, calls `move_and_slide()` every frame.
7. **Input Map actions defined:** yes — `move_up/down/left/right` + `interact`
   all present in `project.godot`.
8. **W/A/S/D bound:** yes — physical keycodes 87/83/65/68 (+ arrows + gamepad).
9. **`process_mode` correct:** default (inherits = processing) on both
   characters and all parents.
10. **Game not paused:** `get_tree().paused == false` at runtime (`proc ...
    paused=false`).
11. **No parent blocks processing:** World is a plain `Node3D`, no
    `process_mode` override, no `set_process` disabling, not paused.
12. **Movement not overridden:** no script writes the female's position every
    frame; `fixed_camera_manager` only moves the Camera, `player_manager` only
    sets the male's `follow_target`.
13. **Male doesn't control both:** male is a separate `PlayerBase` instance with
    `can_be_controlled = false`; he only reads follow direction, never input.
14. **No input-consuming/blocking handler:** there are no `_input` /
    `_unhandled_input` handlers in the game (only the temporary diagnostics).
15. **Diagnostics added** (see below).

### Diagnostics added (persistent, toggle off after diagnosis)
- `scripts/player/player_controller.gd` (top `_DIAG := true`): logs per-frame to
  `user://movement_diag.txt` — active/controlled flags, per-action axis via
  `Input.get_axis`, physical key state via `Input.is_physical_key_pressed` for
  W/A/S/D, camera presence, the produced `wish` vector, `target_velocity`,
  `_horizontal_velocity`, `move_and_slide()` return, `global_position`, and
  per-frame position delta. Also logs every `InputEventKey` seen by `_input`.
- `scenes/World.gd` (temporary diagnostic root script): logs to
  `user://world_diag.txt` — active player id, player count, paused state, camera
  presence, per-action axis, and every `InputEventKey` reaching the tree.

### Baseline result in this environment (headless, no OS keys — expected all-zero)
- `movement_diag.txt`:
  `set_active node=Female -> true`
  `phys ... active=true canctrl=true axis_U=0.00 axis_LR=0.00 physA=false
  physD=false physW=false physS=false cam=true slid=true pos=(-5.00,0.10,0.00)
  dpos=0.000`
- `world_diag.txt`:
  `proc frame=15/30/45 active=female count=2 paused=false cam=true axis_U=0.00
  axis_LR=0.00`
- This proves: female is active+controlled, processing runs, `move_and_slide()`
  executes, camera present, **not paused**, no position drift when idle.

### Decisive next step (user action on actual hardware)
With the diagnostics live, run the game (separate window), press W/A/S/D, then
report `movement_diag.txt` + `world_diag.txt`
(located under `%APPDATA%\Godot\app_userdata\Where Are My Cats\`). The result
is self-defining:
- If `_input` logs `KEY` events and `physW=true` / `axis_U>0` appear, keys DO
  reach Godot → any remaining failure would be in movement logic (none found).
- If no `KEY` lines for W/A/S/D appear and `physW=false` / `axis_U=0.00` persist,
  that is definitive proof **OS keyboard events never reach the Godot window** —
  an environment/driver/editor-run issue, not a project bug.

### Tests performed
- `--import`: clean (exit 0), no script/parse errors.
- Phase 1, Phase 2, InputReal: **ALL PASS** (headless, diagnostics on).
- Headless `World.tscn` run: no format errors; diagnostics wrote the baseline
  above.

---

## 2026-08-31 — DEFINITIVE ROOT CAUSE: OS never delivers keyboard input to the window

**User ran the instrumented build on their actual machine** (separate, focused
game window) and pressed W/A/S/D. The resulting logs are conclusive and were
analyzed here.

### On-machine evidence (`user://movement_diag.txt`, 733 lines)
- The female's `_physics_process` ran for **732 physics frames** and every row
  was identical: `active=true canctrl=true axis_U=0.00 axis_LR=0.00 physA=false
  physW=false physS=false physD=false wish=(0,0,0) slid=true pos=(-5.00,0.10,0.00)
  dpos=0.000`.
- **Zero lines containing `_input KEY`** → the game's input handlers never fired
  for any key, the entire run.
- **No non-zero `axis_U`/`axis_LR`**, no `physX=true`, no `dpos>0` anywhere →
  `Input.get_axis` never saw input and the character never moved.

### On-machine evidence (`user://world_diag.txt`, 132 rows ≈ 1400+ frames)
- Every row: `active=female count=2 paused=false cam=true axis_U=0.00
  axis_LR=0.00`.
- **Zero `WORLD._input` lines** → the root viewport received *no OS input events
  at all* (neither keyboard nor mouse) during the entire run.

### Interpretation
- The **game is healthy and fully live**: female active + controlled, camera
  present, not paused, `move_and_slide()` executing, both characters present,
  female never drifted.
- The **operating system delivered zero input events to the Godot window**, even
  though the user clicked it and it had focus. This is definitively a window /
  OS-event-delivery problem (Godot's `Input` never being fed by the OS), **not** a
  gameplay/player/scripting bug — every game-side check passed and the exact same
  code moves the female when a real `InputEventKey` is delivered
  (`INPUTREAL TEST: ALL PASS`).

### Files changed
- None for gameplay. The temporary diagnostics (`player_controller.gd`,
  `World.gd`) were **fully removed**; both files are restored to clean state.

### Tests performed (final clean state)
- `--import`: clean (exit 0).
- Phase 1, Phase 2, InputReal: **ALL PASS**.
- Confirmed no diagnostic strings remain in any `.gd` file.

### Fix for the user environment (not project code)
Because keyboard events never reach the window, the fix is at the
window/engine/driver level, **not** in this project's code:
1. **Export a standalone build and run the `.exe`** (Project → Export). If the
   exported game receives keys, the gap is specific to running from the editor.
2. **Project Settings → Rendering → Renderer**: switch to the **Compatibility**
   renderer (this machine has an Intel HD Graphics 620 + D3D12 path). Old Intel
   iGPU/D3D12 window message pumps are a known input-focus failure mode.
3. **Update the Intel HD 620 graphics driver** (force a recent driver).
4. As a last resort, run the game on a different machine/GPU to confirm the same
   project behaves normally (it should).

*End of current log. Append future entries below this line.*

---

## 2026-08-31 — Camera switched from fixed-camera to third-person follow camera

**Request:** the user wanted to change the camera from the fixed-camera setting
(zone-based views) to a **third-person point of view**.

### What changed
- `scripts/camera/third_person_camera.gd` — **new** third-person follow/orbit
  camera (`class_name ThirdPersonCamera extends Node3D`):
  - Orbits the active (female) protagonist from behind using mouse motion
    (yaw/pitch, pitch clamped -0.9..1.2 rad so it never goes under the floor or
    straight over the top).
  - **Mouse wheel zoom** (in/out), clamped to `min_distance` 1.5 / `max_distance`
    9.0, step 0.5.
  - **Wall-aware:** every frame a raycast from the player's head toward the
    desired lens position pulls the camera in (`collision_margin` 0.15, the
    player's own body excluded) so it never clips into walls/floors/furniture.
  - Smooth position lerp; `camera.current = true` in `_ready`; frames the female
    at head height (`look_height` 1.5).
- `scenes/World.tscn` — `CameraSystem` now uses `third_person_camera.gd` instead
  of `fixed_camera_manager.gd` (no more `zones` NodePaths; Camera starts near the
  player's spawn).
- `tests/phase2_test.gd` — rewritten for the third-person camera: setup/current,
  frames the active player at working distance, follows her when she teleports
  across the cottage, wheel zoom in/out, male stays readable.
- `tests/phase3_test.gd` — rewritten: geometry/collision counts kept; per-room
  floor-hold checks (living, kitchen, kitchen-back, bedroom, bathroom,
  upstairs-back) plus camera-frames-player in every room; stairs climb; wheel
  zoom sanity check. Zone-resolution checks removed (no longer the main camera).
- `plan.md` — §2 core-design bullet, §7 Camera, §14 architecture, §15 systems,
  §24 status updated.

### Intentionally NOT changed
- `scripts/camera/fixed_camera_manager.gd` and `camera_zone.gd`, and the
  Cottage builder's 6 `CameraZone`s (`scripts/world/cottage_builder.gd` `_build_zones`)
  are all **left intact and unused** so the fixed-camera mode can be restored
  with a one-line scene swap if the user changes their mind.
- `scripts/player/player_controller.gd` — movement stays camera-relative, so
  W/A/S/D behave the same under the new camera (W forward, S back after the
  earlier fix).

### Controls (updated)
- **Mouse move** — rotate the camera around the female.
- **Mouse wheel** — zoom in/out.
- **W/A/S/D** — move the female relative to the camera (W forward).

### Tests performed
- Headless `--import`: clean (exit 0).
- Phase 1, Phase 2, InputReal, Phase 3: **ALL PASS** — the camera frames the
  player (drawn to ~4.37 at spawn, ~2.99 in the tight kitchen), zooms
  (4.5→5.0→4.0), follows across room teleports, and none of the environment
  checks regressed.

### Current status
- Camera is now third-person follow/orbit with wheel zoom and wall clipping
  avoidance. Movement, follow, environments, and tests all intact.

### Next step
- User to try it in the editor/window (Compatibility renderer). Phase 4 remains
  **awaiting instruction**.

---

---

## 2026-08-31 — Controls: W/S fixed (W=forward) + mouse-wheel camera zoom

**Request:** in-game W moved backward and S moved forward — swap so W is forward.
Also add zoom in/out with the mouse wheel.

### What changed
- `scripts/player/player_controller.gd` — `_read_input_direction()` now reads the
  forward/back axis as `Input.get_axis("move_down", "move_up")` (was
  `"move_up", "move_down"`), so **W now moves forward** (away from the camera)
  and **S moves backward**. Left/right unchanged (A left, D right).
- `scripts/camera/fixed_camera_manager.gd` — added mouse-wheel zoom:
  - New exports `zoom_step` (0.5), `zoom_in_max` (4.0), `zoom_out_max` (6.0) and a
    `_zoom` offset (units along the view axis).
  - `_unhandled_input()` handles `MOUSE_BUTTON_WHEEL_UP/DOWN` and clamps `_zoom`.
  - `_process()` applies `_apply_zoom()` on top of whichever view it is using
    (camera zone or no-zone fallback): positive `_zoom` dollys the camera toward
    the look point (zoom in, never past it), negative pulls back (zoom out).
- `tests/phase3_test.gd` — added a zoom check (wheel up → `_zoom > 0` and
  `_apply_zoom` moves the camera closer to the look target; wheel down → `_zoom < 0`).

### Controls (updated)
- **W** forward, **A** left, **S** back, **D** right (arrows / gamepad stick too).
- **Mouse wheel up** — zoom camera in; **mouse wheel down** — zoom out.

### Tests performed
- Headless `--import`: clean (exit 0).
- Phase 1, Phase 2, InputReal, Phase 3: **ALL PASS** (Phase 3 now includes the
  zoom check).

---

---

## 2026-08-31 — Renderer switched to Compatibility (resolves WASD/input delivery)

**Situation:** Following the definitive root-cause finding (the OS never delivered
keyboard input to the game window on the dev machine), the user switched the
project renderer to **Compatibility (`gl_compatibility`)** and confirmed **Phase 2
works in Godot** — the female moves with W/A/S/D and the camera system functions.

### What changed
- `project.godot` — `[rendering] renderer/rendering_method="gl_compatibility"`
  (was Forward Plus). `rendering_device/driver.windows` retained as `d3d12`.
- This is now the required renderer for this project on the developer machine
  (Intel HD Graphics 620 / D3D12 path). `plan.md` §13 Technology Decisions updated.

### Verdict
- Root cause of the Phase 2 "WASD does nothing" issue fully resolved: it was the
  renderer/input-delivery quirk, not game code. Phase 2 is confirmed working
  by the user on their machine.

---

## 2026-08-31 — Phase 3: Cottage Blockout

### Status
Completed.

### What was implemented
A full two-storey **procedural blockout cottage** plus a small countryside
exterior, all built from primitive boxes with muted cottage-core / PS1-style
colors, wired into the existing Phase 1 movement + Phase 2 fixed-camera systems
**without touching cat gameplay, interaction, or final assets**.

- **New scene composition:**
  - `scenes/world/Cottage.tscn` — instantiates `scripts/world/cottage_builder.gd`
    (a `Node3D` that builds everything in `_ready()`).
  - `scenes/World.tscn` rewritten: `Cottage` instance + `Sun` (DirectionalLight3D
    with shadows) + `Omni` interior light + `WorldEnvironment` (soft blue sky,
    ambient) + `CameraSystem` (the existing `FixedCameraManager` with a `Camera`
    child) + `Female`/`Male` players spawned outside near the front door.
- **Layout (blockout):**
  - **Ground floor** (Y 0..3): kitchen (east), living room (west), stairwell +
    16-step straight staircase in the back-center. Interior wall with doorway
    splits kitchen/living.
  - **Upper floor** (Y 3..6): bedroom (west), bathroom (east), stairwell shaft,
    open back area.
  - **Exterior:** 30×26 grass ground, dirt path to the front door, trees, bushes,
    fence (non-colliding visual around the yard), mailbox.
  - **Roof:** two sloped gable halves (visual only) so the exterior reads as a
    cottage.
- **Collision:** every structural piece (floors, exterior/interior walls,
  stairwell walls, all 16 stair treads, furniture) is a `StaticBody3D` with a
  `BoxShape3D` — walls/floor/stairs are solid and the player cannot fall through
  any floor (verified headlessly, y stays at floor height).
- **Furniture blockout** so rooms read clearly and the future hiding spots have
  a physical shape: kitchen counter, counter island, fridge, table/chair
  (living), sofa/table/rug (living), bed + bedside table (bedroom), sink/toilet/
  bath (bathroom). Note: the kitchen **cabinet** (Ginger), bedroom **bed**
  (Tabby) and the **dark bathroom** (Tuxedo) are already the locations that Phase 8
  will use for the cat-hiding spots.
- **Camera zones (6):** `Zone_Exterior`, `Zone_Living`, `Zone_Kitchen`,
  `Zone_Stairs`, `Zone_Bedroom`, `Zone_Bathroom`. Each is an `Area3D` trigger +
  `View` Camera3D + `LookTarget` discovered by the existing `CameraZone` script.
  `Zone_Stairs` is given `priority = 1` so the stairs camera wins in the small
  overlap with living/kitchen near the stairwell. The `FixedCameraManager` blends
  to whichever zone contains the female, so the camera switches cleanly between
  exterior → living → kitchen → stairs → bedroom → bathroom.

### Files created
- `scenes/world/Cottage.tscn`
- `scripts/world/cottage_builder.gd`
- `tests/phase3_test.gd`, `tests/Phase3Test.tscn`

### Files modified
- `scenes/World.tscn` — rewritten to compose the Cottage + CameraSystem + players
  + lighting (replaced the old 24×24 floor + 2-zone world).
- `project.godot` — renderer switched to Compatibility (see previous entry).
- `tests/phase2_test.gd` — updated from the old 2-zone world (ZoneA/ZoneB) to the
  6-zone cottage world (spawn=Zone_Exterior, transition Exterior→Kitchen,
  follow check repositioned to an open area on reachable ground).
- `plan.md` — Phase 3 status, renderer decision, Phase 2 note.

### Tests performed
- Headless `--import`: clean (exit 0), no script/parse errors.
- **Phase 3 test (new): ALL PASS** — 6 camera zones resolve; ~collision bodies
  and meshes present; camera current; each room point maps to the correct zone
  (Exterior, Living, Kitchen, Stairs, Bedroom, Bathroom); player placed above the
  kitchen floor does not fall through; stairs carry the player up.
- **Phase 1 regression: PASS** (female responds to input; male follows).
- **Phase 2 regression: PASS** (setup, zone selection, Exterior→Kitchen
  transition, follow readability) against the new 6-zone world.
- **InputReal regression: PASS** (real W key moves the female).

### Known limitations / notes
- The male follower uses simple straight-line steering (`move_and_slide`); it
  follows fine on unobstructed/open ground but has **no pathfinding**, so it can
  get stuck against walls if the human teleports/jumps across them. In normal
  play (walking the real route) it follows through doorways. Dedicated follower
  pathfinding is a later-phase polish item.
- Camera / zone **poses and framing are unverified visually** headlessly — room
  labels, geometry counts, zone selection and transitions are verified, but the
  user should confirm the composed views look right in the editor/windowed run.
- Visual-only roof & fence have no collision (intentional for blockout).
- No cat gameplay, interaction, or final assets yet (Phase 4+).

### Current status
- Phase 3 complete. The player can (in principle) walk through the exterior, into
  the cottage, across the living room, into the kitchen, up the stairs, and into
  the bedroom/bathroom with the camera switching zones and no floor/wall
  penetration. Not started Phase 4.

### Next step
- **Phase 4 — PS1 Rendering Style** (awaiting instruction).

---

## 2026-08-31 — Phase 3 staircase repaired (up AND down through the cottage)

**Reported bugs:** the female protagonist could not walk up the stairs to reach
the second floor; a wall across the staircase meant the stairs were not actually
connected to the upper floor.

### Root causes found
1. **The original 16 box "steps" are not climbable by this controller.** The
   player controller moves with pure horizontal velocity + gravity +
   `move_and_slide()` (no upward-powered step assist), and `floor_snap` only snaps
   the body *down* small ledges — it never lifts it *up*. Investigation confirmed
   `CharacterBody3D` here cannot auto-step even a ~0.1 ledge, so any discrete-step
   staircase (each riser > floor_snap) catches the capsule and it gets stuck on the
   way up.
2. **Any flat "landing" placed below the full stair height is an unclimbable
   wall.** Because the body has no step-up, a landing box's tall vertical front
   face stops a climber that is still low on the ramp, no matter where the landing
   was nudged.
3. **A rotated BoxShape ramp by itself stalls just shy of the top** and has a
   drop-off behind its peak, so the player could not crest onto the upper floor.
4. **The ground-floor kitchen/living divider wall ran straight through the front
   of the stairwell shaft** (`z ∈ [-3.0, 0.5]` at `x ≈ -0.1`), blocking the foot of
   the stairs, so a player could not exit the staircase onto the ground floor —
   dead-ending the climb.

### The fix (`scripts/world/cottage_builder.gd`)
- Replaced the box-step / box-ramp staircase with a **single continuous
  triangle-mesh ramp surface** (`_build_ramp_surface`, an `ArrayMesh` →
  `ConcavePolygonShape3D` trimesh with `backface_collision`). Its top is one
  unbroken walkable surface that rises from the ground floor (y=0.1 at z=-2.0) up
  a ~37° slope (under the controller's 45° floor_max_angle) to exactly the upper
  floor height (y=3.0 at z=-5.8), then **flattens out and runs level** to the back
  wall. Because there is no vertical step or lip anywhere between the slope and
  the flat top, the controller rides it straight up, crests at y=3.0, and steps
  level sideways onto the flush bedroom/bathroom floor — and back down the same
  way. Visual step treads still overlay the ramp so it reads as a staircase.
- Kept the stairwell shaft side-walls **full height only at the FRONT** (they
  enclose the lower stairs and block passage), with the back of the shaft left
  open so the ramp top can reach the upper floor; the back exterior wall stays.
- **Pulled the ground-floor interior divider wall off the shaft front**
  (`_build_interior_walls` now ends it at z=-2.0, matching the upper divider), so
  the foot/exit of the staircase is unobstructed on the ground floor.

### Tests performed
- New regression suite `tests/stair_test.gd` / `tests/StairTest.tscn` using the
  same `move_and_slide()` + gravity movement as the real controller. **ALL STAGES
  PASS:** live room → stair foot; climb UP to the top; step onto the upstairs
  bedroom; walk across the upper floor (stays at y=3.0); walk back DOWN to the
  ground floor; the male follower climbs up behind the female; the third-person
  camera frames the player on the stairs; and the stairwell walls still block
  passage.
- Regression suites all pass: **Phase1Test, Phase2Test, Phase3Test,
  InputRealTest** — no regressions from the ramp/divider changes.
- `--import` clean, no script/parse errors.

### Current status
- Phase 3 stairs are now a real, connected, walkable path between the ground
  floor and upstairs, verified up and down (plus male follow, camera framing, and
  wall-blocking) by automated tests. Phase 4 remains **awaiting instruction**.

---
