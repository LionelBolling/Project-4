# REWIND video tape assets

- `source/broken_tape_four_pieces.blend` contains the four separate, editable fragments.
- `source/player_shadow_whole_tape_cutscene.blend` contains the complete tape, the original Player and Shadow rigs, and their animation actions. Select **Tape_Rig | pose Tape_Master**, enter Pose Mode, and keyframe the **Tape_Master** bone to animate the whole tape. The **TAPE CONTROL** object remains available for object animation. Select either character's **Runner_Rig controls** armature, enter Pose Mode, and choose clips in the Action Editor. The Player has 15 actions; the Shadow has 16, including **Launch**.
- For facial animation, select the Player rig, enter Pose Mode, and select its **Face_Control** bone. The top-right Outliner only lists objects; edit the face in the **bottom-right Properties editor > Bone tab > Custom Properties**. **Eyes:** 0 neutral, 1 closed, 2 surprised. **Brows:** 0 regular, 1 expressive. **Mouth:** 0 smile, 1 frown, 2 open. These properties drive the face materials and can be keyframed. The Shadow has a separate **Face_Control** bone with the same properties.
- `source/broken_preview0001.png` and `source/cutscene_preview0001.png` show the modeled assets.
- `tape_piece_1.glb` through `tape_piece_4.glb` are the Godot imports. Levels 0, 1, 2, and 3 display pieces 1, 2, 3, and 4 respectively at their finish posts.

The Blender source folder has `.gdignore` so Godot imports the four gameplay pieces without processing the cutscene rigs. Running `blender --background --factory-startup --python assets/video_tape/build_assets.py` from the project root rebuilds the gameplay `.glb` files and preserves existing `.blend` files and their animation edits. The explicit `--overwrite-blend-files` argument replaces edited Blender files; use it only when you intend to discard those edits.

The restored `cutscene1` animation is exported read-only from the cutscene `.blend` with `assets/video_tape/export_cutscene1.py`. Godot loads `assets/boss_cutscene_start/cutscene1.glb` in `scenes/boss_cutscene_start.tscn`. Level 3 and the city campaign both enter that scene before the bossfight.
