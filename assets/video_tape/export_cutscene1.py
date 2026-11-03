"""Export the restored Blender cutscene without saving or changing its source file.

blender --background source/player_shadow_whole_tape_cutscene.blend --python export_cutscene1.py
"""
import bpy
from pathlib import Path


root = Path.cwd()
source = Path(bpy.data.filepath)
assert source.name == "player_shadow_whole_tape_cutscene.blend", source
player_action = bpy.data.actions.get("cutscene1")
tape_action = bpy.data.actions.get("Tape_Rig | pose Tape_MasterAction")
assert player_action is not None and tape_action is not None, "Restored cutscene actions are missing"

scene = bpy.context.scene
scene.name = "cutscene1"
scene.frame_start = 1
scene.frame_end = 120
scene.frame_set(1)
bpy.data.objects["Player | Runner_Rig controls"].animation_data.action = player_action
bpy.data.objects["Tape_Rig | pose Tape_Master"].animation_data.action = tape_action

groups = ("Player | editable original rig and meshes",
          "Shadow | editable original rig and meshes",
          "Complete VHS | animate this prop")
export_objects = set()
for name in groups:
    group = bpy.data.collections.get(name)
    assert group is not None, name
    export_objects.update(obj for obj in group.all_objects if not obj.name.startswith("WGT_"))

# The glTF exporter needs mesh lettering; conversion happens only in memory.
label = bpy.data.objects.get("VHS | REWIND lettering")
if label is not None and label.type == "FONT":
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    bpy.ops.object.select_all(action="DESELECT")
    label.select_set(True)
    bpy.context.view_layer.objects.active = label
    bpy.ops.object.convert(target="MESH")
    export_objects.discard(label)
    export_objects.add(bpy.context.object)

bpy.ops.object.select_all(action="DESELECT")
for obj in export_objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Player | Runner_Rig controls"]

output = root / "assets" / "boss_cutscene_start" / "cutscene1.glb"
output.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", use_selection=True,
                          export_yup=True, export_materials="EXPORT", export_animations=True,
                          export_animation_mode="SCENE", export_frame_range=True,
                          export_force_sampling=True, export_frame_step=1,
                          export_anim_scene_split_object=False)
print("EXPORTED CUTSCENE1", output, "objects", len(export_objects), "frames", scene.frame_start, scene.frame_end)
