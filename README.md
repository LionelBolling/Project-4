## Team

| # | Name |
|---|------|
| 1 | Lionel |
| 2 | Caleb |
| 3 | Evan |
| 4 | Samaii |

## The Other Side

A playable Godot 4 first-person 3D interpretation of the selected Swap Day story:
escape a collapsing memory world before your shadow takes your place.

Open `project.godot` in Godot 4.7 and press **F6** on `scenes/main.tscn`, or **F5** to play.

### Play from a browser link

The GitHub Actions workflow in `.github/workflows/pages.yml` exports the game
with Godot 4.7.2 and deploys it to GitHub Pages. In the repository's **Settings →
Pages → Build and deployment**, set **Source** to **GitHub Actions**. Push the
workflow to `main`, or run **Deploy Godot game to Pages** from the Actions tab.
After its build and deployment succeed, open
https://lionelbolling.github.io/Project-4/ in a desktop browser.

The default **Deploy from a branch** / Jekyll build cannot export a Godot game.
The workflow publishes the generated `Project4/index.html` and its companion
files. These generated files stay out of Git. Web exports use a single thread,
so the host does not need special cross-origin isolation headers.

The opening walks you into a decorated bedroom at 02:17 AM. Explore the TV,
console, gaming desk and bedside lamp with **E**, then interact with the bed.
Three blinks lead to a destroyed world full of floating land and broken walls.
Walk forward to reveal a tape, then approach it, look at it and press **E**.
A hand emerges and pulls you inside.

You wake at the track beside your double. The camera flies to the finish portal,
where a live bedroom view shows you still asleep, then returns to the starting
line. The double laughs and runs. Control returns immediately at full speed:
beat it to the portal. There are no lessons, checkpoints or training countdown.

| Control | Action |
|---|---|
| Mouse | Look around |
| WASD / Arrows | Move relative to your view |
| Space | Jump; hold while falling to glide |
| Shift | Dive; gain speed on downhill slopes |
| E | Interact with nearby objects while looking at them |
| Q / E / R / F | Match the takeover prompt within two seconds |
| Esc | Pause / resume |
| M | Toggle sound |
| Enter | Restart the story after a race |

Mint chevrons boost speed; rose ground slows movement; amber platforms collapse
after heavy landings. The shadow corrupts the path into slower violet terrain.
Beat it to the glowing exit. Falling or letting the shadow escape ends the race.
The cracked mirror near the start reflects the shadow as a solid person.

Visible first-person arms and the double use matching detailed procedural
character parts, including fingers, clothing seams, boots, a watch and a face
with hair, eyes, teeth and a scar. Artwork, ambient sound and the encounter
scream and ghost laugh are generated locally. The bundled Rajdhani font uses
the SIL Open Font License; its license is included in `assets/fonts/`.

See [TEAM_GUIDE.md](TEAM_GUIDE.md) for the script ownership map and integration
instructions. Lionel owns ghost racing, Caleb QTEs, Evan movement, and Samaii
environment behavior. Supporting features also have separate scripts.

Run regression checks with:
`godot --headless --path . --script tests/first_person_check.gd --fixed-fps 60`

Run `tests/race_playthrough.gd` with the same flags to check the full race.
For visual checkpoints, run `tests/preview_story.gd` without `--headless` and
append `-- --visual`. Screenshots are written to `tests/story-*.png`.
