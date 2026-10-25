# Working on The Other Side

Open `project.godot` with Godot 4.7 and press F5. The starting scene is
`scenes/main.tscn`. It loads `scripts/game.gd`, which wires together the systems
and holds the shared scene state. Implement features in the system you own.

| Person | Main script | Responsibility |
|---|---|---|
| Lionel | `scripts/systems/ghost_runner.gd` | Rival movement, racing pace, surges, corruption, running animation |
| Caleb | `scripts/systems/qte.gd` | Random key prompts, time limits and success/failure |
| Evan | `scripts/systems/player_movement.gd` | First-person mouse look, walking, running, jump, glide, dive, camera and arms motion |
| Samaii | `scripts/systems/environment.gd` | Track, slopes, gaps, arrival area, tape prop, surface speed, fragile platforms and collision |

Supporting systems have their own files too:

| Script | What to edit there |
|---|---|
| `opening_sequence.gd` | Bedroom, E interactions, sleep, waking, tape abduction and race flyover |
| `dream_scenery.gd` | Floating land fragments and the sleeping-player portal viewport |
| `character_models.gd` | Shared human/double appearance, face, clothes, fingers, boots and first-person arms |
| `game_audio.gd` | Ambient drone, generated scream, feedback sounds |
| `game_ui.gd` | Objective HUD, interaction prompts, crosshair, eyelids, pause and results |
| `game_flow.gd` | Startup, reset, phase updates and race start |

## How the pieces connect

Each system is a `RefCounted` object with `setup(context)`. Its `game` member is
the active scene. Use `game.player`, `game.camera`, `game.state` and the other
shared fields to read or change the scene. Use `game.add_child()` when adding a
node, since the system itself is not a scene-tree node.

The short methods in `scripts/game.gd` are stable delegates to the systems.
For example, `game.resolve_qte(true)` calls Caleb's QTE implementation, and
`game.update_ghost(dt)` calls Lionel's rival code. Normal implementation edits
do not require changing `scenes/main.tscn` or `scripts/game.gd`.

When adding new shared state or a public method, coordinate that small change
in `game.gd` with the team. Avoid renaming existing shared fields or delegates
without updating callers. Rendering helpers live in `environment.gd`; character
mesh helpers live in `character_models.gd`.

The main flow is:

`room_entry -> bedroom -> sleep -> wake -> explore -> tape_reveal -> explore -> tape_grab -> track_wake -> race_flyover -> ghost_taunt -> race -> result`

Esc freezes the current phase and resumes it. E activates a nearby object only
when it is in view. The tape reveal returns control before pickup. The race
timer starts after the ghost's laugh; there is no tutorial or countdown.
Arrival uses Z=1000 so the track is only revealed after the tape abduction.
The bedroom is at X=1000. The portal owns a separate bedroom viewport.

## Checks before sharing changes

Run these from the project folder, replacing `godot` with your Godot executable
path if necessary:

```powershell
godot --headless --path . --script tests/first_person_check.gd
godot --headless --path . --script tests/race_playthrough.gd
```

The first check exercises the bedroom interactions, cutscene order, tape reveal
and pickup, first-person camera, pause, QTEs, direct race transition and restart.
The second attempts the full race. Add `--fixed-fps 60` to run checks faster.

For screenshots, run the first check without `--headless` and append
`-- --visual`. Captures are saved in `tests/fp-*.png` and excluded from Git.

Use a branch for your feature and commit only your own changes. Review shared
integration changes together before merging.
