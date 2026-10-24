# Working on The Other Side

Open `project.godot` with Godot 4.7 and press F5. The starting scene is
`scenes/main.tscn`. It loads `scripts/game.gd`, which wires together the systems
and holds the shared scene state. Implement features in the system you own.

| Person | Main script | Responsibility |
|---|---|---|
| Lionel | `scripts/systems/ghost_runner.gd` | Rival movement, racing pace, surges, corruption, running animation |
| Caleb | `scripts/systems/qte.gd` | Random key prompts, time limits, success/failure, tutorial retry |
| Evan | `scripts/systems/player_movement.gd` | First-person mouse look, walking, running, jump, glide, dive, camera and arms motion |
| Samaii | `scripts/systems/environment.gd` | Track, slopes, gaps, arrival area, tape prop, surface speed, fragile platforms and collision |

Supporting systems have their own files too:

| Script | What to edit there |
|---|---|
| `opening_sequence.gd` | Bedroom, three blinks, waking, tape encounter, forced turn/run |
| `tutorial.gd` | Lesson text, checkpoints, success conditions, retries and graduation |
| `character_models.gd` | Shared human/double appearance, face, clothes, fingers, boots and first-person arms |
| `game_audio.gd` | Ambient drone, generated scream, feedback sounds |
| `game_ui.gd` | HUD, tutorial panel, crosshair, eyelids, pause and results |
| `game_flow.gd` | Startup, reset, phase updates and race countdown |

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

`sleep -> wake -> explore -> encounter -> forced_turn -> tutorial -> countdown -> race -> result`

Esc freezes the current phase and resumes it. The race timer and rival stay
stopped throughout training. Each lesson pauses for instructions, Enter starts
the attempt, and only successful gameplay advances it. Failed attempts restore
the practice checkpoint. The final QTE must succeed before the countdown.

## Checks before sharing changes

Run these from the project folder, replacing `godot` with your Godot executable
path if necessary:

```powershell
godot --headless --path . --script tests/first_person_check.gd
godot --headless --path . --script tests/tutorial_playthrough.gd
godot --headless --path . --script tests/race_playthrough.gd
```

The first check exercises the opening, encounter, first-person camera, retry,
QTE timeout, race transition and restart. The second performs every tutorial
action through simulated keyboard input. The third attempts the full race.

For screenshots, run the first check without `--headless` and append
`-- --visual`. Captures are saved in `tests/fp-*.png` and excluded from Git.

Use a branch for your feature and commit only your own changes. Review shared
integration changes together before merging.
