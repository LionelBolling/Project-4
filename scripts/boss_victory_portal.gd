extends Node3D

const ENDING_SCENE := "res://scenes/final_ending.tscn"
const DURATION := 8.4
const TAPE_START := Vector3(-0.95, 0.82, 0.1)
const TAPE_SLOT := Vector3(0.1, 1.05, -1.0)
const TAPE_INSIDE := Vector3(0.1, 0.82, -1.4)

@onready var player_actor: Node3D = $Player
@onready var shadow_actor: Node3D = $Shadow
@onready var boombox: Node3D = $Boombox
@onready var tape: Node3D = $TapeSource
@onready var portal: Node3D = $Portal
@onready var portal_light: OmniLight3D = $Portal/PortalLight
@onready var camera: Camera3D = $Camera3D

var elapsed := 0.0
var fade_cover: ColorRect
var transitioning := false

func _ready() -> void:
	player_actor.call("play_animation", &"Idle", 0.0)
	shadow_actor.call("play_animation", &"hurt", 0.0)
	var carried_box := player_actor.find_child("Boombox_Root", true, false) as Node3D
	if carried_box != null:
		carried_box.hide()
	_create_fade()
	_update_shot(0.0)
	camera.make_current()

func _process(delta: float) -> void:
	if transitioning:
		return
	elapsed = minf(DURATION, elapsed + delta)
	_update_shot(elapsed)
	if elapsed >= DURATION:
		transitioning = true
		get_tree().change_scene_to_file(ENDING_SCENE)

func _update_shot(t: float) -> void:
	var reach := smoothstep(1.1, 3.7, t)
	var insert := smoothstep(3.7, 4.6, t)
	player_actor.position = Vector3(-1.4, 0.05, -0.25).lerp(Vector3(-1.02, 0.05, -0.43), reach)
	player_actor.rotation.y = lerpf(0.22, -0.18, reach)
	player_actor.rotation.z = -0.07 * sin(reach * PI)
	tape.position = TAPE_START.lerp(TAPE_SLOT, reach).lerp(TAPE_INSIDE, insert)
	tape.rotation = Vector3(-PI / 2.0 + insert * 0.16, sin(t * 1.5) * 0.08 * (1.0 - insert), 0.0)
	tape.scale = Vector3.ONE * lerpf(0.35, 0.29, insert)
	tape.visible = t < 4.6
	_pose_player_reach(t)
	boombox.rotation.z = sin(t * 1.7) * 0.025 if t < 4.6 else sin(t * 15.0) * 0.055 * (1.0 - smoothstep(5.8, 7.0, t))
	var opening := smoothstep(4.55, 6.7, t)
	portal.scale = Vector3.ONE * maxf(0.001, opening)
	portal.rotation.z = sin(t * 2.0) * 0.06 * opening
	portal_light.light_energy = opening * 4.5
	var focus := Vector3(0.0, 1.0, -1.7).lerp(Vector3(0.0, 2.0, -4.0), smoothstep(4.6, 7.0, t))
	camera.position = Vector3(3.0, 2.2, 5.0).lerp(Vector3(2.2, 2.8, 4.2), smoothstep(2.0, 6.5, t))
	camera.look_at(focus, Vector3.UP)
	fade_cover.color.a = smoothstep(7.55, DURATION, t)

func _pose_player_reach(t: float) -> void:
	var rig: Skeleton3D = player_actor.skeleton
	rig.clear_bones_global_pose_override()
	var weight := smoothstep(0.5, 1.5, t) * (1.0 - smoothstep(4.4, 5.2, t))
	if weight <= 0.0:
		return
	player_actor.animation_player.advance(0.0)
	var target := rig.to_local(tape.global_position + Vector3(-0.18, 0.0, 0.04))
	for names in [["UpperArm.L", "Forearm.L"], ["Forearm.L", "Hand.L"]]:
		var bone := rig.find_bone(names[0])
		var child := rig.find_bone(names[1])
		if bone < 0 or child < 0:
			continue
		var pose := rig.get_bone_global_pose(bone)
		var direction := (rig.get_bone_global_pose(child).origin - pose.origin).normalized()
		var desired := (target - pose.origin).normalized()
		pose.basis = Basis(Quaternion(direction, desired)) * pose.basis
		rig.set_bone_global_pose_override(bone, pose, weight, true)

func _create_fade() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FadeToEnding"
	layer.layer = 90
	add_child(layer)
	fade_cover = ColorRect.new()
	fade_cover.name = "BlackCover"
	fade_cover.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade_cover)
	fade_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
