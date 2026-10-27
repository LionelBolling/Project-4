# enemyRunnerGodotReady

Godot **4.5 or newer** character asset package, freshly exported from your latest edited enemyRunner.blend. Includes **Launch** and all 15 earlier animations, your painted faces, black character materials, the lengthened neon blue scarf, 53-joint deformation rig, separate boombox and cel shader. Your editable enemyRunner source folder was left unchanged.

## Add to your game

Copy the **enemy_runner/** folder into your Godot project's root, then instance **res://enemy_runner/enemy_runner.tscn** under your enemy's movement/controller node. Keep the folder name so the resource paths resolve. This namespace can coexist with the player's res://runner/ assets. Keep your game's project.godot.

```gdscript
var enemy = preload("res://enemy_runner/enemy_runner.tscn").instantiate()
add_child(enemy)
enemy.play_animation(&"Launch")
```

The reusable scene auto-plays Idle, configures repeat settings and connects the facial controller. Its model uses meters, Y up and Z visual front. Keep the imported model at scale 1; move or rotate its parent controller in your game.

You can also open this package's **project.godot** to inspect the asset in Godot's editor. It is an asset package with no gameplay main scene, test level, camera or movement system.

## Animations

**Launch** is exported under its exact name, starts at frame 0 and spans frames 0-49 at 30 fps (1.6333 seconds). Its repeat setting follows the cyclic flag saved in your Blender action.

All 16 clips start at frame 0:

Launch, Idle, Run, Stop, hurt, jumpStart, jumpRise, jumpFall, jumpLand, glideStart, glideFloat, glideLand, dive, diveLand, wallRunRight, wallRunRightJump.

**Launch, dive, glideFloat, Idle, jumpFall, wallRunRight and Run repeat.** The other clips play once. Names, durations and repeat flags are in **enemy_runner/animations/animations.json**. Set a clip's loop flag to false there if you want it to play once. Authored face-key timing, including Launch, is in **enemy_runner/animations/face_animation_tracks.json**.

Use play_animation(name, blend_seconds) to switch clips. The public animation_player property exposes the imported AnimationPlayer for AnimationTree integration; movement/state-machine logic belongs to your game.

## Face, cel look and scarf

All nine current face PNGs are in **enemy_runner/textures/face/**. They were extracted byte-for-byte from your current packed Blender paintings. Eye/brow/mouth switching remains independent, and authored face keys follow playback automatically.

```gdscript
enemy.set_eyes("surprised")
enemy.set_brows("expressive")
enemy.set_mouth("open")
enemy.set_expression("frown")
enemy.restore_neutral()
enemy.resume_authored_face_keys()
```

Manual face commands suspend authored face playback until resume_authored_face_keys() or another play_animation() call. For AnimationTree-driven playback, call apply_animation_face(clip_name, time_seconds) with the selected animation and its time.

The included Godot cel shader uses the imported painted colors, including the blue scarf. The rig contains Scarf_01 through Scarf_06 under Neck, weighted to the edited tail and edge. The scarf wrap/folds follow Neck. The original player's bones remain compatible, and hand/foot IK has been baked into the game clips.

Optional Godot spring settings are in **enemy_runner/assets/scarf_config.json** and default to disabled. Call **set_scarf_physics_enabled(true)** to opt into the native spring setup. This setup targets the neck scarf chain and includes body/case capsule colliders; game-specific tuning and level collision remain part of integration. Its engine runtime has not been executed here.

## Included editable source

**blender/enemyRunner.blend** is an exact copy of your latest authoring file, including Launch, painted images, animation controls and scarf rig. The folder contains a .gdignore so Godot uses the production GLB without automatically importing the authoring file a second time.

The ready-to-use mesh is **enemy_runner/assets/enemy_runner.glb**. A standalone **enemy_runner/boombox.tscn** and **assets/boombox.glb** are also included; the character already carries its attached copy.

## Verification

The GLB was reimported into Blender. All 16 clips, including Launch, were checked at start, midpoint and end for pants, hand, shoe, rigid boombox, neck scarf wrap and scarf tail deformation. All clips and face timing agree on duration, and the runtime rig has 53 deformation joints. Packed/current PNG hashes and scene/script/shader/JSON resource paths were checked. Your source folder remains byte-identical.

**Godot engine parsing/runtime testing was unavailable on this machine.** The runtime scripts, shader and optional native spring setup have not been run in-engine here. No test scenes, test scripts, validation reports, build logs or Blender backups are included in this delivery. ASSET_MANIFEST.json records every delivered file and hash.
