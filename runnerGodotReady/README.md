# runnerGodotReady

Self-contained character assets for **Godot 4.5 or newer**. Your latest Blender model and painted textures were used for a fresh export. The original Blender project was not changed.

## Use in your game

Copy the **`runner` folder** into your Godot project's root and instance **`res://runner/runner.tscn`** beneath your player/enemy controller. Keep the folder name `runner` so the included resource paths resolve. Do not replace your game's project.godot.

Alternatively, open this folder's **`project.godot`** to inspect the asset scenes in the editor. This is an asset project: it contains no test level, camera, movement controller or gameplay main scene.

```gdscript
var runner = preload("res://runner/runner.tscn").instantiate()
add_child(runner)
runner.play_animation(&"Run")
```

The model uses meters, +Y up and +Z visual front. Keep the model at scale 1; place/rotate/move its parent controller in your game.

## Editable Blender file and frame timing

Open **`runner.blend`** in this folder. It was rebuilt from your newly edited original under `RunnerCharacter/blender`, including your corrected animation poses. That original authoring file remains unchanged.

All 15 actions and their facial keys start at **frame 0**, with no added T-pose lead-in. The original's frame-1 first keys were shifted back one frame in this packaged copy; motion duration, subsequent timing, geometry, weights and bone setup are preserved. The file opens at frame 0 with Idle selected. Choose actions in the Runner sidebar or Action Editor. Packed painted textures, IK controls, cel materials, belt cloth setup and the embedded face tools remain included.

The GLB also begins every clip at time 0. `animations.json` records the matching Blender frame ranges and repeat flags, and the facial sidecar uses the same zero-based timing.

## Included

- **`runner.blend`**: editable Blender source rebuilt from your corrected original; all 15 actions start at frame 0.
- **`runner/runner.tscn`**: reusable character scene with AnimationPlayer, facial playback, cel materials and belt spring setup wired through its script.
- **`runner/assets/runner.glb`**: rigged character, clothing, shoes, hands, attached rigid boombox and all 15 gameplay clips. It contains the 47 deformation joints, including the original six belt bones and boombox attachment. Blender IK controls/widgets are omitted; their evaluated motion is baked into the clips.
- **`runner/boombox.tscn`** and **`runner/assets/boombox.glb`**: independent modular boombox. The character already includes its attached copy; instance the standalone asset only when you need a separate one.
- **`runner/textures/face/`**: all nine transparent painted face variants, extracted byte-for-byte from the current packed Blender images. Other original paint colors/materials and the default face textures are included in the GLB.
- **`runner/animations/face_animation_tracks.json`**: authored face-key timing for every gameplay clip.
- **`runner/animations/animations.json`**: names, durations and default loop settings.
- **`runner/materials/runner_cel.gdshader`**: Godot implementation of the three-band cel look, preserving imported paint colors.
- **`runner/scripts/`**: production character, face, cel-material and belt runtime scripts.

No validation clips, blank IK drafts, test scripts/scenes, review UI, studio geometry, previews or build logs are included.

## Animation names

`Idle`, `Run`, `Stop`, `hurt`, `jumpStart`, `jumpRise`, `jumpFall`, `jumpLand`, `glideStart`, `glideFloat`, `glideLand`, `dive`, `diveLand`, `wallRunRight`, `wallRunRightJump`.

`dive`, `glideFloat`, `Idle`, `jumpFall` and `wallRunRight` repeat, as requested. `Run` retains its existing repeat setting. The other clips play once. These flags are stored in `animations.json`, applied by the reusable scene in the editor and at runtime, and set as cyclic actions in the packaged Blender file. Adjust the metadata if your game needs different looping.

```gdscript
runner.play_animation(&"jumpRise", 0.1)
runner.animation_finished.connect(_on_runner_animation_finished)
var player: AnimationPlayer = runner.animation_player
var skeleton: Skeleton3D = runner.skeleton
```

## Faces

Authored face keys follow the AnimationPlayer automatically. They use the companion JSON and controller rather than relying on Blender material-driver animation inside GLB. Keep those resources with the model.

```gdscript
runner.set_eyes("surprised")   # neutral, closed, surprised
runner.set_brows("expressive") # regular, expressive
runner.set_mouth("open")       # smile, frown, open
runner.set_expression("frown")
runner.restore_neutral()
runner.resume_authored_face_keys()
```

Manual setters suspend authored face playback until `resume_authored_face_keys()` or another `play_animation()` call. Parts remain independently selectable. Automatic blinking is available for manual faces; authored playback respects the supplied blink keys. Your painted neutral red irises, surprised contours and open-mouth teeth are retained.

When using an AnimationTree, feed the selected clip and its playback time to `runner.apply_animation_face(clip_name, time_seconds)`. AnimationTree state/movement logic belongs to your game.

## Belt motion and cel shading

The character script creates a native Godot **SpringBoneSimulator3D** restricted to `Belt_01` through `Belt_06`, with body/case capsule colliders. It reads body poses and applies secondary motion to the belt chain only. Root stiffness, tip stiffness, drag, gravity and enable state are exposed on the character scene. The bright edge shares the same belt skin weights.

```gdscript
runner.set_belt_physics_enabled(true)
runner.reset_belt_motion() # after a teleport or hard pose reset
runner.belt.wind = Vector3(0, 0, -0.4)
```

This is a game-side bone-spring implementation, not a transfer of Blender's cloth cache. Its motion is not guaranteed to be numerically identical to Blender cloth. It includes body/case collisions; world/level collision and game-specific tuning remain part of integration.

Cel shading is enabled by default and can be toggled on the scene's `cel_shading_enabled` property. Imported painted base colors feed the shader. Facial artwork and drawn white details stay flat and clear. Use your game's lighting; the asset includes no studio lights.

## Verification status

The new Blender copy was reopened and all 15 actions were checked to start at frame 0 in their authored motion pose. The requested repeat flags were checked. Curves and sampled bone poses match your edited original after the one-frame timing shift. The refreshed GLB was reimported into Blender; all 15 clips were checked at start, midpoint and end for pants, hands, feet and rigid case deformation. Clip durations, painted images, skeleton and resource paths were also checked. The original authoring Blender file remains byte-identical.

**Godot engine parsing/runtime/visual testing was not executable on this machine.** The supplied Godot scripts, shader and native spring setup have not been run in-engine here. Verification scripts/reports were kept outside this delivery folder.

See **`ASSET_MANIFEST.json`** for the included file hashes and animation list. API references: [Godot spring bones](https://docs.godotengine.org/en/4.5/classes/class_springbonesimulator3d.html), [Godot spatial shaders](https://docs.godotengine.org/en/4.5/tutorials/shaders/shader_reference/spatial_shader.html).
