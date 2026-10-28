# Rewind — Project 4

A story campaign built around the existing runner movement, rival AI, projectile corruption, race controller, and boss encounter.

Open the root `project.godot` in Godot 4.7.2 and press **F5**. The main scene is `scenes/rewind.tscn`.

## Story

Explore the bedroom and approach the cassette boombox. Look at it and press E to open the portal. Win three races across increasingly fragmented neon tracks, then counter the shadow in the final confrontation. Damaged tapes between races show a person separating from their shadow. After the final fight, the tape opens the way home; the mirror and the person trapped inside the boombox reveal who escaped.

Story text is limited to ROUND 1, ROUND 2, ROUND 3, FINAL ROUND, and YOU WIN. Controls and QTE keys are interface text. There is no spoken dialogue.

## Campaign controls

| Input | Action |
|---|---|
| WASD | Move |
| Mouse | Camera |
| Space | Jump; hold while airborne to glide |
| Shift | Dive |
| E | Interact with the bedroom boombox |
| Q / E / R / F | Counter the displayed attack within two seconds |
| Esc | Release/capture cursor |
| M | Toggle sound |
| Enter | Replay after the ending |

A successful QTE grants a 30% running boost for five seconds. A failed QTE removes 15% of current horizontal momentum. The boss retains its existing animated ram/launch responses as well.

Mint platforms boost running speed; rose platforms slow movement. Amber platforms collapse after dive impacts or shadow corruption, with a 0.9-second warning and a four-second recovery. The shadow turns passed platforms violet and slows them. Wider gaps and more wall-run sections increase the challenge in later rounds. Losing retries the same round; winning advances the campaign.

## Code and scenes

- `scripts/rewind_story.gd`: bedroom exploration, portal, campaign progression, tape memories, generated music, and ending shots.
- `scripts/story_course.gd`: campaign-only floating platforms, surfaces, corruption, monsters, and QTEs.
- `scripts/story_props.gd`: reusable cassette, boombox, and silhouette geometry.
- `scenes/runner_race.tscn`: original race and current character/movement systems.
- `scenes/bossfight.tscn`: original final confrontation, connected to the campaign.
- `scenes/movement_test.tscn`: standalone movement sandbox.
- `scenes/main.tscn`: preserved older first-person story prototype.

The standalone race and boss scenes keep their original controls: Space jump, Shift glide, Ctrl dive. Campaign controls apply only to campaign instances.

The `runnerGodotReady` and `enemyRunnerGodotReady` directories are asset packages; the game uses the root `runner/` and `enemy_runner/` copies.

## Verification

Run with your Godot executable:

    godot --headless --path . -s tests/rewind_check.gd
    godot --headless --path . -s tests/environment_check.gd

`tests/rewind_preview.gd` renders bedroom, race, and ending screenshots when run with a graphical renderer. Generated PNGs are ignored by Git.

## Browser export

The existing `.github/workflows/pages.yml` workflow exports to GitHub Pages. In repository Settings → Pages, select GitHub Actions as the deployment source. Generated web files live in `Project4/` and stay out of Git.

## Team

Lionel Bolling · Samaii Hartley · Evan Jones · Caleb Milliken
