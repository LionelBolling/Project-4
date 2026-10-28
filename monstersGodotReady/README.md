# monstersGodotReady

Three animated monster assets for Godot 4: disco ball, speaker and microphone. Each has its current rig, painted normal/hurt eye meshes, idle and hurt clips, cartoon materials and a reusable scene. **Both animations repeat for every monster**, as requested. The original Blender folders are unchanged.

## Use in your Godot game

Extract the ZIP, then copy the entire **monsters/** folder into your project's root. It includes the shared controller/shader used by all three separate monster folders. Keep your game's project.godot.

Instance one of these scenes beneath your game's enemy/movement controller:

- **res://monsters/disco_ball/disco_ball.tscn**
- **res://monsters/speaker/speaker.tscn**
- **res://monsters/microphone/microphone.tscn**

```gdscript
var monster = preload("res://monsters/disco_ball/disco_ball.tscn").instantiate()
add_child(monster)
monster.play_hurt() # repeats with hurt eyes until you switch animations
monster.play_idle() # repeats with normal eyes
```

Every scene starts playing idle automatically. Both idle and hurt use Animation.LOOP_LINEAR, configured in the editor and at runtime by the shared script. Call play_idle() or play_hurt() whenever your game switches state. They continue repeating until another animation is selected. The source animation frames, speed and poses are preserved.

The imported AnimationPlayer is exposed as **monster.animation_player**, and the Skeleton3D as **monster.skeleton**. Your gameplay logic can use an AnimationTree; movement, collision and combat systems belong to your game. The assets use meters, Y up and Z visual front. Keep the imported Model child at scale 1 and transform its parent controller.

## Eye meshes and painted artwork

The separately edited normal and hurt eye meshes are both included in each GLB. The shared controller displays the matching mesh, retaining its own UVs, shape and painted texture. Current packed Blender paintings were copied byte-for-byte into each monster's textures/ folder; default images are also embedded in GLB.

The saved clips contain no Eyes-property keys. Their default eye state is therefore matched by animation name: idle shows normal, hurt shows hurt. monster.json stores this explicit mapping and the eye-event times, so new authored eye keys can be added later.

```gdscript
monster.set_eyes(&"hurt")
monster.set_eyes(&"normal")
monster.resume_animation_eyes()
```

Manual setters override the automatic eye state until resume_animation_eyes() or the next play_animation() call. For AnimationTree playback, call **monster.apply_animation_eyes(clip_name, time_seconds)** with the active clip/time. An editor **preview_eyes** selector also previews either appearance.

## Rigs and clips

Each monster keeps its own files under monsters/:

- Disco ball: one Body deformation joint; idle frames 0-30, hurt 0-8.
- Speaker: three linked layer deformation joints; idle frames 0-36, hurt 0-12. Your corrected hand/arm/handle normals and layer assignments are retained.
- Microphone: Body plus six wire joints on each arm (13 deformation joints); idle frames 0-42, hurt 0-12.

All source files use **24 fps**. Blender drag controls/IK are evaluated into the exported deformation-bone animations, so no Blender control rig is needed in Godot. Both clips start at time 0. Per-monster **monster.json** records frame ranges, durations, repeat flags, eye events and flat-painted material names.

## Materials and editable copies

Eevee ShaderToRGB graphs were converted to portable material colors/textures for GLB export; the shared **monster_toon.gdshader** recreates the stepped cartoon look. Eye/nose art is unshaded with alpha transparency, and optional silhouette-outline geometry is retained. The **toon_enabled** property toggles the body shader. Use the lighting from your game; no studio lights or cameras are exported.

Exact editable copies of the latest Blender files are included under **blender/**, in separate monster subfolders. They retain the packed paintings and embedded animation tools. A .gdignore keeps Godot from importing those authoring files again. Continue authoring in your original project4 monster folders when you want to update the models.

You may open this package's **project.godot** to inspect the assets. This is an asset project with no gameplay main scene, test level or movement controller. Use the supplied .tscn scenes to configure materials, looping and eye visibility automatically.

## Executed checks

All three GLBs were reimported into Blender. Both clips on each monster were compared at start, midpoint and end across every rendered mesh, including both eye variants, outlines and wire arms. Deformations match the source within floating-point precision. Runtime skeletons contain 1, 3 and 13 deformation joints respectively, with authoring controls excluded. Material colors, embedded/current eye pixels, non-empty painted hurt textures, animation durations, both repeat flags and all scene/script/shader/JSON paths were checked. The original source folders are byte-identical.

**Godot engine parsing/playback/render testing could not be executed here:** no installed executable was found, and the portable-engine download could not connect. The supplied runtime scripts/shader have not been run in-engine on this machine. No test scenes, test scripts, validation reports, previews or Blender backups are included. ASSET_MANIFEST.json records delivered file hashes.
