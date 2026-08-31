# Where Are My Cats? — Master Development Plan

Working title: **"Where Are My Cats?"** (title may change later)

This is the living master plan for the project. It describes what the project is
**supposed to become**. For a record of what has actually happened, see
`devlog.md`. If this file and `devlog.md` ever disagree, `devlog.md` reflects
reality and this plan should be corrected.

---

## 1. Game Overview

A small, cozy, exploration-focused **3D game** with a strong **PlayStation 1
(PS1) era visual aesthetic**. The player controls **two main characters** — one
**female protagonist** and one **male protagonist** — who live in a countryside
cottage with **three cats**. The cats keep hiding around the house.

The primary objective:

> **Find all three cats hiding inside the cottage.**

The experience is simple, charming, atmospheric, and slightly mysterious —
exploration and discovery rather than combat. It should feel like a finished
small indie game, not a technical demo.

---

## 2. Core Design

- Cozy, quiet, nostalgic, slightly strange, cooperative exploration.
- Two playable protagonists search the cottage together.
- Third-person follow camera (user decision 2026-08-31; supersedes the original
  fixed-camera plan — fixed-camera code kept intact for easy reversion).
- Low-poly, low-resolution, retro-rendered visuals.
- Three cats hide in distinct locations; sound and subtle clues help find them.
- No combat, weapons, inventory, crafting, skills, multiplayer, or online.
- Small world: the cottage is the main playable area.

### The Core Loop

```
START GAME
  → Begin in/around cottage with both protagonists
  → Control the female protagonist (male follows her)
  → Explore cottage together
  → Find Ginger (kitchen) → Find Tabby (bedroom) → Find Tuxedo (dark bathroom)
  → All three cats found
  → Completion / Ending → Credits / Restart
```

---

## 3. The Two Protagonists

### Female Protagonist (primary, co-equal main character)

- A main protagonist, **not** a secondary NPC.
- Low-poly PS1-style humanoid.
- Distinct via silhouette, hair style, muted clothing color, and a small
  accessory.
- Can explore, interact, and discover cats on her own.

### Male Protagonist (primary, co-equal main character)

- An active main character who contributes to the search.
- Low-poly PS1-style humanoid.
- Distinct via silhouette, hair style, muted clothing color, and a small
  accessory.
- Can explore, interact, and discover cats on his own.

Both must be visually distinct yet stylistically consistent with the overall
palette.

---

## 4. Character Cooperation Approach (decision)

**DECISION:** The **female protagonist is the sole playable character**. The male
protagonist is never player-controlled; he simply **follows the female** wherever
she goes and does not interact on his own (no character switching, no controller
input for him). The camera always frames the female.

Rationale:
- Keeps control simple and focused: you play one protagonist (female) while the
  male stays with her, reinforcing the co-present companion feel without a
  companion-follow AI needing pathfinding/animation/collision complexity.
- The male never receives input, so he cannot diverge or trigger interactions;
  he only stays near the female, keeping both readable together in every frame.
- No switching means one mental model and no switch-specific camera behaviors.

This may evolve (e.g., a lightweight "regroup/come here" or a scene where the
male is required) only via a later approved phase.

---

## 5. The Three Cats

| Cat     | Color        | Location          | Hiding Place       | Difficulty |
|---------|--------------|-------------------|--------------------|------------|
| Ginger  | Ginger/orange| Kitchen           | Inside a cabinet   | Easy       |
| Tabby   | Tabby        | Upstairs bedroom  | Under the bed       | Medium     |
| Tuxedo  | Black & white| Upstairs bathroom | In the bathroom    | Hard (dark)|

Either protagonist may discover any cat.

### Tuxedo special mechanic

The bathroom **light is broken**, making the room significantly darker and
harder to search. The tuxedo cat is the hardest to find. The player may hear it
or notice subtle visual clues before locating it.

---

## 6. The World: Cottage

A small countryside cottage and surrounding greenery. Two floors.

### Downstairs
- **Kitchen:** cabinets, countertops, sink, refrigerator, dining objects, props.
  Ginger hides in a cabinet.
- **Living Room:** sofa, table, chairs, decorations, books, plants, cozy props.
- **Stairs:** connect downstairs and upstairs.

### Upstairs
- **Bedroom:** bed, bedside furniture, decorations, props. Tabby hides under
  the bed.
- **Bathroom:** sink, toilet, bathtub/shower, props. Main lighting broken.
  Tuxedo hides here.

### Outside
Small amount of countryside scenery — grass, trees, bushes, flowers, dirt path,
fence, small garden, mailbox, firewood, simple props. Exists for atmosphere and
as a starting/brief exploration area. **Not** an open world.

---

## 7. Camera

**Third-person follow camera** — the active game camera (`ThirdPersonCamera` at
`scripts/camera/third_person_camera.gd`). This is the intended camera design. (An
interim Phase 4 revision briefly switched the scene to the fixed-camera manager;
that was a regression and was reverted.)

- Follows the female protagonist (the only controlled one) from **behind and
  slightly above** (`look_height` 1.5, `initial_pitch` 0.35, default distance
  4.5), keeping her the clear focus of the frame.
- **Mouse-wheel zoom:** scroll up zooms in, scroll down zooms out (`distance`
  clamped between `min_distance` and `max_distance`).
- **Stable and controlled:** smooth `_process` lerp toward the desired position
  (`blend_speed`), and a raycast (`_avoid_collision`) that pulls the camera in
  front of geometry so it never clips through walls. The camera is not a fixed
  room-survival-horror camera; it is not freely orbitable to the point of losing
  the player.
- Player movement is camera-relative (W/A/S/D relative to the on-screen view), so
  turning the camera changes which way the keys push (left/right strafe relative
  to view) while forward/back behave intuitively.
- The male follower stays alongside the female and is framed with her.

The Phase 2 fixed-camera system (`fixed_camera_manager.gd`, `camera_zone.gd` and
the Cottage's zones) remains in the repo but is **not** the active camera; it is
kept intact for easy reversion if ever wanted.

---

## 8. Graphics Style (PS1)

Intentional PS1-era look — one of the most important requirements.

- Low-poly models, low polygon counts.
- Low-resolution, pixelated textures.
- Simple lighting, strong shadows where appropriate.
- Atmospheric fog.
- Slight retro rendering artifacts / vertex-texture wobble if practical.
- Limited visual detail.
- Retro-looking characters and environments.
- Must deliberately feel like PS1, not generic modern low-poly.

---

## 9. Color Palette

- Muted, warm, cottage-core, slightly faded, natural, cozy.
- Muted greens, faded browns, cream, beige, dusty orange, soft gray,
  desaturated blue, dark wood.
- Avoid saturated modern game colors.
- The two protagonists use complementary muted colors, distinct yet in-palette.

---

## 10. Audio

- Instrumental music primarily.
- Environmental sounds: footsteps, doors, light switches, cat meows, wind,
  birds, rain (if appropriate), house ambience.
- **Cat audio is important** — sound helps locate cats.
- No unnecessary voice acting unless explicitly requested later.
- Subtle character movement/interaction sound differences; no dialogue system.

---

## 11. Interactions (planned)

- Open cabinet, inspect objects, open doors, toggle light switch, investigate
  areas, find cats, small environmental interactions, and a possible lightweight
  "regroup/come here" command. Only the female protagonist initiates these.
- Build a **reusable interaction system** where practical.
- Not all interactions are built in Phase 0; implement incrementally by phase.

---

## 12. Out of Scope

Combat, weapons, complex inventory, crafting, skill trees, RPG mechanics,
multiplayer, online systems, large procedural worlds, complex NPC systems,
unrelated quests, complex relationship systems, unnecessary dialogue trees.
The experience is: explore a cozy cottage with two protagonists who work
together to find three hiding cats.

---

## 13. Technology Decisions

| Concern      | Decision                              |
|--------------|---------------------------------------|
| Engine       | **Godot 4.7** (already in use)        |
| Renderer     | **Compatibility (`gl_compatibility`)** — required: Forward Plus never delivered keyboard input on the dev machine (Intel HD Graphics 620 / D3D12); Compatibility is confirmed working |
| Physics      | **Jolt Physics** (already configured) |
| 3D modeling  | Blender (external tool)               |
| Textures     | Krita / GIMP (external tool)          |
| Audio        | Audacity (external tool)              |
| Version ctrl | Git (repo already initialized)        |

No need for PostgreSQL, Prisma, Next.js, React, web servers, auth, or cloud
databases. This is a standalone game.

---

## 14. Architecture

- Scene-based Godot architecture.
- Small, reusable scripts grouped by system (player, camera, interaction, cats,
  ui).
- Shared PlayerController used by both protagonists — no duplicated movement or
  interaction code.
- Third-person follow camera (mouse orbit + wheel zoom + wall-collision pull-in).
- Reusable interaction detection/prompt system.
- Game flow states (menu, playing, paused, complete) managed by a game
  controller / UI layer.

### Folder Structure

```
project root/
├── project.godot
├── plan.md
├── devlog.md
├── assets_needed.md
├── scenes/
│   ├── player/       # character scenes (female, male)
│   ├── camera/       # camera manager/zones
│   ├── world/        # cottage, rooms, exterior
│   ├── cats/         # 3 cat scenes
│   └── ui/           # menu, HUD, credits
├── scripts/
│   ├── player/
│   ├── camera/
│   ├── interaction/
│   ├── cats/
│   └── ui/
├── assets/
│   ├── characters/female, male, cats
│   ├── environment/
│   ├── furniture/
│   ├── textures/
│   └── documents/
├── audio/
│   ├── music/
│   └── sfx/
├── shaders/
└── exports/
```

---

## 15. Game Systems

- Player movement + collision (shared).
- Female-controlled movement; male auto-follow (never controlled).
- Third-person follow camera (orbits female, mouse-driven, wheel zoom,
  wall-aware).
- Interaction detection + prompts.
- Cat discovery tracking.
- Broken bathroom light.
- Audio (music + sfx).
- UI / game flow (menu, pause, completion, credits, restart).

---

## 16. Art Requirements

- Female protagonist model + textures.
- Male protagonist model + textures.
- 3 cat models + textures.
- Cottage exterior + interior (2 floors, 4 rooms).
- Furniture & props (kitchen, living room, bedroom, bathroom).
- Exterior props (trees, bushes, flowers, fence, mailbox, firewood, path, grass).
- PS1-style textures (low-res, pixelated).
- Some assets initially replaced by placeholders; important ones need final
  PS1-style assets. Tracked in `assets_needed.md`.

---

## 17. Audio Requirements

- Instrumental music loop(s).
- Footsteps, doors, light switch, cat meows (per cat), wind, birds, ambience.
- Bathroom-specific dark atmosphere audio.
- Simple, minimal set for a small game.

---

## 18. Phase List

| Phase | Name                          | Focus |
|-------|-------------------------------|-------|
| 0     | Project Setup & Planning      | Initialize project, docs, structure, launch ✅ |
| 1     | Basic Player Characters       | Two protagonists, movement, collision, female control + male follow, basic camera ✅ |
| 2     | Fixed Camera System           | Camera zones, transitions, room framing ✅ |
| 3     | Cottage Blockout              | Exterior + interior placeholder geometry ✅ |
| 4     | PS1 Rendering Style           | Low-res, pixelated, fog, lighting, retro FX ✅ |
| 5     | Cottage Environment           | Proper low-poly assets, props, exterior greenery ✅ |
| 6     | Interaction System            | Detection, prompts, doors, cabinets, switches, inspection |
| 7     | Cats                          | 3 cat models, placement, interaction, discovery |
| 8     | Cat-Finding Gameplay          | Ginger/Tabby/Tuxedo discovery, broken light, audio clues, completion |
| 9     | Audio & Atmosphere            | Music, ambience, sfx, bathroom mood |
| 10    | UI & Game Flow                | Menu, start, pause, completion, credits, restart |
| 11    | Polish                        | Lighting, camera, collision, interaction, audio, visuals, perf |
| 12    | Testing & Final Build         | Full playthrough, bug fixes, input, export |

This structure may be adjusted if a better architecture is found; any change is
documented here and in `devlog.md`.

---

## 19. Dependencies

- Phase 1 depends on Phase 0 (project runs).
- Phase 2 depends on Phase 1 (characters exist to frame).
- Phase 3 depends on Phase 2 (camera framing the blockout).
- Phase 4 depends on Phase 3 (visual style applied to world).
- Phase 5 depends on Phases 3–4.
- Phase 6 depends on Phase 5 (assets to interact with).
- Phase 7 depends on Phase 6 (interaction for discovery).
- Phase 8 depends on Phase 7.
- Phase 9 depends on Phase 3+ (audio needs a world).
- Phase 10 depends on core gameplay.
- Phase 11 depends on Phases 1–10.
- Phase 12 is final.

---

## 20. Testing Strategy

Every phase is tested before it is marked complete. Per phase, verify:

- Does the game launch?
- Does the feature work?
- Does it integrate with existing systems?
- Any console errors / broken references?
- Collisions correct; can the player get stuck?
- Camera behavior correct?
- Can the player identify and control both protagonists?
- Does the female protagonist respond to input and the male follow her?

Phase 0 testing: project launches, config valid, no import errors.

---

## 21. Definition of Done (per phase)

1. Objective met.
2. All phase tasks implemented.
3. Tested (see Testing Strategy).
4. `plan.md` and `devlog.md` updated.
5. `assets_needed.md` updated if relevant.
6. Project left in a usable state.

---

## 22. Known Risks

- No installed cli `godot` on PATH — use full path, may change across machines.
- Fixed-camera + male-auto-follow interplay needs careful camera framing (male
  must stay in frame with the female).
- PS1 look is easy to get wrong (must not look like generic modern low-poly).
- Feasibility of vertex wobble without heavy cost — evaluate later.
- Placeholder art may mask layout issues; replace before final.
- Audio assets cannot be auto-generated — tracked in `assets_needed.md`.

---

## 23. Future Ideas (NOT in current scope)

- Cat-specific reactions, small environmental events, more hiding spots,
  weather, day/night atmosphere, additional rooms, small secrets, multiple
  endings, deeper cooperation between protagonists.
- **Do not implement unless added as an approved phase.**

---

## 24. Current Project Status

- **Phase 0** — Project Setup & Planning: COMPLETE.
- **Phase 1** — Basic Player Characters: COMPLETE (female is the sole
  controlled protagonist; male follows her; both visually distinct; basic camera
  active). Revised 2026-08-31: removed character switching entirely — the male
  is never player-controlled (can_be_controlled = false) and just follows.
- **Phase 2** — Fixed Camera System: COMPLETE (camera zones, smooth transitions,
  no-zone fallback; floor now has collision). Always frames the female. Verified
  again on 2026-08-31 in headless AND real windowed runs (real-key movement via
  `Input.parse_input_event` moved 2.43 units); fixed a load-time parse-error
  corruption in `scripts/player/player_manager.gd` that had made the autoload
  fail and left the world appearing static. **Root cause of the WASD failure
  finally resolved:** the OS never delivered any keyboard input to the window on
  the dev machine until the renderer was set to **Compatibility
  (`gl_compatibility`)** — Forward Plus on the Intel HD Graphics 620 / D3D12 path
  produced zero input events. Universe of tests re-run 2026-08-31: Phase1,
  Phase2, InputReal all pass headless. See `devlog.md`.
- **Phase 3** — Cottage Blockout: COMPLETE. Full two-storey blockout cottage
  (kitchen, living room, bedroom, bathroom, staircase + stairwell, roof, small
  exterior: grass, dirt path, trees, fence, mailbox). 6 camera zones (exterior,
  living, kitchen, stairs, bedroom, bathroom) driving the existing Phase 2
  fixed-camera system with wall/floor/stairs collision. No cat gameplay or
  interaction yet. **Staircase repaired 2026-09-01:** replaced the box ramps
  with a smooth trimesh ramp surface so the male MC can walk up/down between the
   ground floor and upstairs (`StairTest` 8 stages all pass). **Geometry fix
   2026-09-01:** both key openings are now genuinely passable — the front door has
   a clear rectangular opening (no blocking door leaf, only the frame) into a
   foyer, the interior-divider back segments no longer cross the open stairwell,
   and the ground-floor divider stops short of the door so the player walks around
   it into either room; verified with the real player capsule (`move_and_slide`)
   entering through the door and climbing the stairs.
- **Phase 4** — PS1 Rendering Style: COMPLETE. 320×240 low-res viewport upscaled
  3× to a 960×720 window with nearest-neighbor filtering (pixelated PS1 look),
  PS1 color quantization (24 levels) + Bayer 4×4 ordered dithering + a gentle
  saturation lift post-process shader attached to the camera, and adjusted
  lighting. `Phase4Test` passes; all prior suites (Phase1/2/3, Stair, InputReal)
  still pass. **Revised 2026-09-01 (playtest):** the distance fog was removed
  entirely (cottage and exterior stay clearly visible at any distance); the
  palette and lighting were brightened/warmed so walls, furniture and greenery
  have more contrast and life while preserving the PS1 pixelation; and the
  post-process shader was reworked to eliminate pixel shimmering (nearest
  sampling of the low-res buffer + dithering aligned to the scene texels). The
  active game camera remains the **third-person follow camera**
  (`third_person_camera.gd`) with working mouse-wheel zoom — an interim change
  that pointed the scene at the fixed-camera manager was a regression and was
  reverted.
- **Phase 5** — Cottage Environment: COMPLETE. Enriched the procedural cottage
  with detailed low-poly PS1 props and richer exterior greenery, all kept
  visual-only (no collision) so movement, collisions and the stairs are never
  disturbed. Kitchen got a sink + upper cabinet + dining table & chairs + shelf;
  the living room a coffee table, bookshelf with books, fireplace with mantle and
  a rug; the bedroom a headboard/blanket/pillow, a wardrobe, a bed lamp and a rug;
  the bathroom a mirror and towel rails. Fixes a latent Phase 3 issue: the
  bedroom and bathroom furniture now sits on the CORRECT **upper floor** (was
  accidentally placed at ground-floor height, so the upstairs rooms stood empty
  and the living/kitchen were cluttered). The exterior was expanded with more
  varied trees, shrubs, flower beds, a firewood stack, a stone well and a front
  doormat. `Phase5Test` added and passing; all other suites (Phase1–4, Stair,
  InputReal) still pass.
- **Camera (2026-08-31 → final 2026-09-01):** the **third-person follow camera**
  (`scripts/camera/third_person_camera.gd` driving `CameraSystem`) is the active
  game camera — it follows the female from behind/above, stays stable, avoids
  wall clipping, and zooms with the mouse wheel (wheel up = in, down = out).
  During a Phase 4 revision the scene was briefly switched to the fixed-camera
  manager; the user identified that as a regression (the intended design is
  third-person), and it was reverted. The Phase 2 fixed-camera system
  (`fixed_camera_manager.gd` + the Cottage's 6 `CameraZone`s) remains in the repo
  but is not the active camera.
- One female main character and one male main character are the core premise.
- Cooperative exploration is the core premise.
- Character approach: the female is the only playable character; the male
  follows her automatically (see §4).

---

*Back on page — this is a living document; update on every decision change.*
