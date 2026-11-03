"""Run with Blender: blender --background --factory-startup --python build_assets.py"""
import bpy
import math
import sys
from pathlib import Path
from mathutils import Vector


ROOT = Path.cwd()
OUT = ROOT / "assets" / "video_tape"
SOURCE = OUT / "source"
OVERWRITE_BLEND_FILES = "--overwrite-blend-files" in sys.argv
bpy.context.preferences.filepaths.save_version = 0


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for child in list(bpy.context.scene.collection.children):
        bpy.context.scene.collection.children.unlink(child)
    for collection in list(bpy.data.collections):
        if collection.users == 0:
            bpy.data.collections.remove(collection)


def collection(name):
    result = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(result)
    return result


def put(obj, group):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    group.objects.link(obj)
    return obj


def material(name, color, metal=0.0, rough=0.4, emission=None):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = 1.5
    return mat


BLACK = material("Obsidian black | polished cassette shell", (0.012, 0.016, 0.035), .58, .19)
INNER = material("Deep black | fractured inner body", (0.005, 0.006, 0.014), .3, .27)
BLUE = material("Electric blue | anodized trim", (0.016, .38, .92), .55, .16, (.015, .35, .85))
PINK = material("Hot pink | anodized trim", (.9, .025, .33), .48, .18, (.8, .018, .28))
SILVER = material("Mirror chrome | reel hubs", (.42, .68, .83), .9, .13)
FILM = material("Smoky black | magnetic tape", (.025, .012, .026), .15, .35)
LABEL = material("Pale iridescent label", (.62, .88, 1.0), .35, .23, (.12, .18, .28))


def bevel(obj, width=.035, segments=2):
    mod = obj.modifiers.new("Soft manufactured edges", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.affect = "EDGES"
    obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj


def cube(name, loc, scale, mat, group, bevel_size=.02):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = put(bpy.context.object, group)
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel_size:
        bevel(obj, bevel_size)
    return obj


def disc(name, loc, radius, depth, mat, group, vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = put(bpy.context.object, group)
    obj.name = name
    obj.data.materials.append(mat)
    bevel(obj, min(.015, depth * .2), 2)
    return obj


def shard(name, points, group, accent):
    count = len(points)
    verts = [(x, y, z) for z in (-.11, .11) for x, y in points]
    faces = [tuple(range(count)), tuple(reversed(range(count, 2 * count)))]
    faces.extend((i + count, (i + 1) % count + count, (i + 1) % count, i) for i in range(count))
    mesh = bpy.data.meshes.new(name + " geometry")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(BLACK)
    mesh.materials.append(accent)
    mesh.update()
    obj = bpy.data.objects.new(name + " | broken shell", mesh)
    group.objects.link(obj)
    for polygon in mesh.polygons[2:]:
        polygon.material_index = 1
    bevel(obj, .018)
    cx = sum(x for x, _ in points) / count
    cy = sum(y for _, y in points) / count
    inset = [(cx + (x - cx) * .89, cy + (y - cy) * .89) for x, y in points]
    verts2 = [(x, y, .129) for x, y in inset]
    panel_mesh = bpy.data.meshes.new(name + " face geometry")
    panel_mesh.from_pydata(verts2, [], [tuple(reversed(range(count)))])
    panel_mesh.materials.append(INNER)
    panel_mesh.update()
    panel = bpy.data.objects.new(name + " | inset face", panel_mesh)
    group.objects.link(panel)


def reel(name, x, y, group, accent):
    disc(name + " | tape spool", (x, y, .155), .35, .045, FILM, group)
    disc(name + " | bright reel ring", (x, y, .19), .28, .027, accent, group)
    disc(name + " | black reel core", (x, y, .21), .205, .03, BLACK, group)
    disc(name + " | chrome spindle", (x, y, .232), .065, .042, SILVER, group)
    for i in range(6):
        a = i * math.tau / 6
        spoke = cube(name + " | chrome spoke %d" % i,
                     (x + math.cos(a) * .145, y + math.sin(a) * .145, .232),
                     (.13, .035, .012), SILVER, group, .006)
        spoke.rotation_euler.z = a


def screw(name, x, y, group):
    disc(name, (x, y, .145), .038, .018, SILVER, group, 16)


PIECES = [
    ("01_Blue_UpperLeft", [(-1.5,.93),(-.055,.93),(.09,.63),(-.06,.39),(.035,.035),(-.43,-.04),(-.82,.075),(-1.12,-.015),(-1.5,.045)], BLUE),
    ("02_Pink_UpperRight", [(-.055,.93),(1.5,.93),(1.5,-.065),(1.14,.045),(.78,-.06),(.39,.08),(.035,.035),(-.06,.39),(.09,.63)], PINK),
    ("03_Pink_LowerLeft", [(-1.5,.045),(-1.12,-.015),(-.82,.075),(-.43,-.04),(.035,.035),(-.09,-.3),(.07,-.59),(-.035,-.93),(-1.5,-.93)], PINK),
    ("04_Blue_LowerRight", [(.035,.035),(.39,.08),(.78,-.06),(1.14,.045),(1.5,-.065),(1.5,-.93),(-.035,-.93),(.07,-.59),(-.09,-.3)], BLUE),
]


def decorate_piece(index, group, accent):
    if index < 2:
        x = -.78 if index == 0 else .78
        reel("Left" if index == 0 else "Right", x, .42, group, accent)
        screw("Corner screw", -1.32 if index == 0 else 1.32, .75, group)
    else:
        x = -.83 if index == 2 else .83
        cube("Lower cassette grip", (x,-.51,.16), (1.07,.18,.055), accent, group)
        cube("Readable dark label stripe", (x,-.28,.172), (1.04,.09,.04), LABEL, group)
        screw("Corner screw", -1.32 if index == 2 else 1.32, -.74, group)
        for j in range(4):
            cube("Magnetic window slat %d" % j, (x-.36+j*.24,-.71,.175), (.1,.04,.04), INNER, group, .004)


def export_piece(group, filename):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in group.all_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(group.all_objects))
    bpy.ops.export_scene.gltf(filepath=str(OUT / filename), export_format="GLB", use_selection=True,
                              export_yup=True, export_apply=True, export_materials="EXPORT")


def make_piece_file():
    clear_scene()
    groups = []
    for i, (name, points, accent) in enumerate(PIECES):
        group = collection(name)
        shard(name, points, group, accent)
        decorate_piece(i, group, accent)
        groups.append(group)
    for i, group in enumerate(groups):
        export_piece(group, "tape_piece_%d.glb" % (i + 1))
    # The source file shows the four shards separated; the exports keep their original coordinates.
    for i, group in enumerate(groups):
        offset = (-.3 if i % 2 == 0 else .3, .22 if i < 2 else -.22, 0)
        for obj in group.all_objects:
            obj.location += Vector(offset)
    add_studio_camera()
    source_file = SOURCE / "broken_tape_four_pieces.blend"
    if OVERWRITE_BLEND_FILES or not source_file.exists():
        bpy.ops.wm.save_as_mainfile(filepath=str(source_file))
    else:
        print("Preserved edited Blender source:", source_file)


def make_whole_tape(group):
    cube("VHS | complete black shell", (0,0,0), (3.0,1.86,.23), BLACK, group, .09)
    cube("VHS | face plate", (0,0,.13), (2.82,1.67,.035), INNER, group, .045)
    for side, x, accent in (("left",-1.37,BLUE),("right",1.37,PINK)):
        cube("VHS | %s neon outer rail" % side, (x,0,.16), (.095,1.5,.065), accent, group)
        screw("VHS | %s upper screw" % side, x,.74,group)
        screw("VHS | %s lower screw" % side, x,-.74,group)
    for y, accent in ((.8,BLUE),(-.8,PINK)):
        cube("VHS | colored edge", (0,y,.165), (2.65,.07,.055), accent, group)
    cube("VHS | reel window", (0,.29,.177), (2.24,.88,.045), BLACK, group, .09)
    reel("VHS left", -.78,.3,group,BLUE)
    reel("VHS right", .78,.3,group,PINK)
    cube("VHS | iridescent center label", (0,-.48,.184), (2.3,.4,.04), LABEL, group, .035)
    cube("VHS | label blue edge", (-1.05,-.48,.207), (.09,.33,.013), BLUE, group, .006)
    cube("VHS | label pink edge", (1.05,-.48,.207), (.09,.33,.013), PINK, group, .006)
    text = bpy.data.curves.new("REWIND label curves", "FONT")
    text.body = "REWIND"
    text.align_x = "CENTER"
    text.align_y = "CENTER"
    text.size = .23
    obj = bpy.data.objects.new("VHS | REWIND lettering", text)
    group.objects.link(obj)
    obj.location = (0,-.49,.212)
    obj.data.materials.append(INNER)


def add_studio_camera(scale=5.5, focus=(0,0,0)):
    studio = collection("Preview lights and camera")
    bpy.ops.object.camera_add(location=(0,-4.7,5.8))
    camera = put(bpy.context.object, studio)
    camera.name = "Preview camera"
    camera.rotation_euler = (Vector(focus) - camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = scale
    bpy.context.scene.camera = camera
    for name, loc, energy, color in (("Blue softbox",(-3,-2,5),750,(.45,.75,1)),
                                     ("Pink softbox",(3,2,4),650,(1,.4,.75))):
        bpy.ops.object.light_add(type="AREA", location=loc)
        light = put(bpy.context.object, studio)
        light.name = name
        light.data.energy = energy
        light.data.color = color
        light.data.shape = "DISK"
        light.data.size = 5
        light.rotation_euler = (Vector((0,0,0))-light.location).to_track_quat("-Z","Y").to_euler()
    bpy.context.scene.render.engine = "CYCLES"
    bpy.context.scene.cycles.samples = 32
    bpy.context.scene.render.resolution_x = 1000
    bpy.context.scene.render.resolution_y = 700
    bpy.context.scene.render.resolution_percentage = 100


def append_character(path, label, offset):
    before = set(bpy.data.objects)
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.collections = [name for name in source.collections
                              if name[:2].isdigit() and int(name[:2]) <= 11]
        target.actions = list(source.actions)
    holder = collection(label + " | editable original rig and meshes")
    for group in target.collections:
        if group is not None:
            holder.children.link(group)
    appended = set(bpy.data.objects) - before
    for obj in appended:
        if obj.parent is None:
            obj.location.x += offset
    rig = next(obj for obj in appended if obj.type == "ARMATURE" and obj.name.startswith("Runner_Rig"))
    assert len(rig.pose.bones) > 0, label + " rig controls are missing"
    rig.name = label + " | Runner_Rig controls"
    rig.show_in_front = True
    rig.hide_viewport = False
    rig.animation_data_create()
    idle = next((action for action in target.actions if action and action.name.startswith("Idle")), None)
    if idle:
        rig.animation_data.action = idle
    for action in target.actions:
        if action:
            action.use_fake_user = True
            action["character"] = label
    return rig, len(appended), len([a for a in target.actions if a])


def make_tape_rig(group, control):
    armature = bpy.data.armatures.new("Tape_Rig bones")
    rig = bpy.data.objects.new("Tape_Rig | pose Tape_Master", armature)
    group.objects.link(rig)
    rig.location.z = 1.25
    rig.show_in_front = True
    armature.display_type = "STICK"
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    bone = armature.edit_bones.new("Tape_Master")
    bone.head = (0, 0, 0)
    bone.tail = (0, 0, .7)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.update()
    original_world = control.matrix_world.copy()
    control.parent = rig
    control.parent_type = "BONE"
    control.parent_bone = "Tape_Master"
    control.matrix_world = original_world
    bpy.context.view_layer.update()
    shell = next(obj for obj in group.all_objects if obj.name == "VHS | complete black shell")
    original_shell = shell.matrix_world.copy()
    pose_bone = rig.pose.bones["Tape_Master"]
    pose_bone.rotation_mode = "XYZ"
    pose_bone.rotation_euler.z = math.radians(20)
    bpy.context.view_layer.update()
    assert (shell.matrix_world @ Vector((1, 0, 0)) - original_shell @ Vector((1, 0, 0))).length > .05, "Tape bone does not drive the shell"
    pose_bone.rotation_euler.z = 0
    bpy.context.view_layer.update()
    return rig


def make_cutscene_file():
    source_file = SOURCE / "player_shadow_whole_tape_cutscene.blend"
    if source_file.exists() and not OVERWRITE_BLEND_FILES:
        print("Preserved edited cutscene and animations:", source_file)
        return
    clear_scene()
    tape = collection("Complete VHS | animate this prop")
    make_whole_tape(tape)
    control = bpy.data.objects.new("TAPE CONTROL | move, rotate, or keyframe", None)
    tape.objects.link(control)
    control.empty_display_type = "CUBE"
    control.empty_display_size = .55
    for obj in tape.all_objects:
        if obj != control:
            obj.parent = control
    control.location.z = 1.25
    tape_rig = make_tape_rig(tape, control)
    player = append_character(ROOT / "runnerGodotReady" / "runner.blend", "Player", -2.5)
    shadow = append_character(ROOT / "enemyRunnerGodotReady" / "blender" / "enemyRunner.blend", "Shadow", 2.5)
    add_studio_camera(scale=8.2, focus=(0,0,1.0))
    bpy.ops.object.select_all(action="DESELECT")
    player_rig = player[0]
    player_rig.select_set(True)
    bpy.context.view_layer.objects.active = player_rig
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="DESELECT")
    player_rig.pose.bones["Face_Control"].select = True
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 240
    bpy.context.scene.frame_set(1)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(source_file))
    print("CHARACTERS", player, shadow, "TAPE BONE", tape_rig.pose.bones.keys()[:])


OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
make_piece_file()
make_cutscene_file()
print("VIDEO TAPE ASSETS COMPLETE")
