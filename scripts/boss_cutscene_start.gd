extends Node3D

const BOSS_SCENE := "res://scenes/bossfight.tscn"
const CLIP_NAME := "cutscene1"
const FADE_SECONDS := 0.8
const CAMERA_OFFSET := Vector3(0.0, 0.25, 7.5)

@onready var cutscene: Node3D = $Cutscene1
@onready var camera: Camera3D = $Camera3D

var animation_player: AnimationPlayer
var player_skeleton: Skeleton3D
var head_bone := -1
var fade_cover: ColorRect
var elapsed := 0.0
var duration := 5.0
var transitioning := false

func _ready() -> void:
	animation_player = cutscene.get_node("AnimationPlayer") as AnimationPlayer
	player_skeleton = cutscene.get_node("Player | Runner_Rig controls/Skeleton3D") as Skeleton3D
	head_bone = player_skeleton.find_bone("Head_2")
	duration = animation_player.get_animation(CLIP_NAME).length
	_create_fade_cover()
	animation_player.play(CLIP_NAME)
	animation_player.seek(0.0, true)
	_update_camera(1.0)
	camera.make_current()

func _process(delta: float) -> void:
	if transitioning:
		return
	elapsed = minf(duration, elapsed + delta)
	_update_camera(minf(1.0, delta * 4.0))
	fade_cover.color.a = smoothstep(maxf(0.0, duration - FADE_SECONDS), duration, elapsed)
	if elapsed >= duration:
		transitioning = true
		preload("res://scripts/city_progress.gd").travel(get_tree(), BOSS_SCENE, true)

func _update_camera(weight: float) -> void:
	var focus := player_skeleton.global_position + Vector3.UP * 1.45
	if head_bone >= 0:
		focus = (player_skeleton.global_transform * player_skeleton.get_bone_global_pose(head_bone)).origin
	camera.global_position = camera.global_position.lerp(focus + CAMERA_OFFSET, weight)
	camera.look_at(focus, Vector3.UP)

func _create_fade_cover() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FadeToBoss"
	layer.layer = 90
	add_child(layer)
	fade_cover = ColorRect.new()
	fade_cover.name = "BlackCover"
	fade_cover.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade_cover)
	fade_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
