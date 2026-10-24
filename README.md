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

The game begins in bed at night. Three blinks take you into another world.
Explore the arrival area and walk into the video tape on the floor. Your double
emerges, screams, and forces you toward the broken track.

Each tutorial lesson pauses for instructions. Press Enter to attempt it; you
must perform the action successfully to continue. Falls restore the checkpoint.
The rival and race clock remain frozen until all seven lessons are complete.
Then a countdown starts the harder race, with a faster rival and periodic surges.

| Control | Action |
|---|---|
| Mouse | Look around |
| WASD / Arrows | Move relative to your view |
| Space | Jump; hold while falling to glide |
| Shift | Dive; gain speed on downhill slopes |
| Q / E / R / F | Match the takeover prompt within two seconds |
| Esc | Pause / resume |
| M | Toggle sound |
| Enter | Start a tutorial attempt; restart after a race |

Mint chevrons boost speed; rose ground slows movement; amber platforms collapse
after heavy landings. The shadow corrupts the path into slower violet terrain.
Beat it to the glowing exit. Falling or letting the shadow escape ends the race.
The cracked mirror near the start reflects the shadow as a solid person.

Visible first-person arms and the double use matching detailed procedural
character parts, including fingers, clothing seams, boots, a watch and a face
with hair, eyes, teeth and a scar. Artwork, ambient sound and the encounter
scream are generated locally; no external assets or dependencies are required.

See [TEAM_GUIDE.md](TEAM_GUIDE.md) for the script ownership map and integration
instructions. Lionel owns ghost racing, Caleb QTEs, Evan movement, and Samaii
environment behavior. Supporting features also have separate scripts.

Run regression checks with:
`godot --headless --path . --script tests/smoke.gd`

Also run `tests/tutorial_playthrough.gd` to verify that every lesson can be
completed using real movement and keyboard input, and `tests/race_playthrough.gd`
to check the full race.
