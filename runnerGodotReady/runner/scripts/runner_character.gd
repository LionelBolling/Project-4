@tool
extends Node3D
## Reusable visual character asset; instance beneath your game's movement controller.
const Facial = preload("facial_controller.gd")
const FaceSync = preload("face_animation_sync.gd")
const Belt = preload("belt_physics.gd")
const CelMaterials = preload("cel_materials.gd")

signal animation_finished(animation_name: StringName)
signal expression_changed(state: Dictionary)
@export var autoplay_animation: StringName = &"Idle"
@export var cel_shading_enabled: bool = true:
	set(value):
		cel_shading_enabled = value
		if is_inside_tree():
			call_deferred("_apply_materials")
@export var use_authored_face_keys: bool = true
@export var automatic_blinking: bool = true
@export_group("Belt physics")
@export var belt_physics_enabled: bool = true
@export_range(0.0, 10.0) var belt_root_stiffness: float = 1.5
@export_range(0.0, 10.0) var belt_tip_stiffness: float = 0.35
@export_range(0.0, 1.0) var belt_drag: float = 0.30
@export_range(0.0, 10.0) var belt_gravity: float = 1.0
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var face_controller
var face_animation
var belt

func _ready() -> void:
	_apply_materials()
	var model := get_node("Model")
	var players := model.find_children("*", "AnimationPlayer", true, false)
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if players.is_empty() or skeletons.is_empty():
		push_error("Runner: imported skeleton or animation player is missing")
		return
	animation_player = players[0] as AnimationPlayer
	skeleton = skeletons[0] as Skeleton3D
	_configure_loops()
	if Engine.is_editor_hint():
		return
	animation_player.animation_finished.connect(_on_animation_finished)
	face_controller = Facial.new()
	face_controller.name = "FacialController"
	face_controller.automatic_blinking = automatic_blinking and not use_authored_face_keys
	add_child(face_controller)
	face_controller.bind_face(model)
	face_controller.expression_changed.connect(_on_expression_changed)
	face_animation = FaceSync.new()
	face_animation.name = "AuthoredFaceKeys"
	face_animation.enabled = use_authored_face_keys
	add_child(face_animation)
	face_animation.bind_player(animation_player, face_controller)
	belt = Belt.new()
	belt.name = "BeltPhysics"
	belt.enabled = belt_physics_enabled
	belt.root_stiffness = belt_root_stiffness
	belt.tip_stiffness = belt_tip_stiffness
	belt.drag = belt_drag
	belt.gravity = belt_gravity
	add_child(belt)
	belt.bind_skeleton(skeleton)
	if not autoplay_animation.is_empty():
		play_animation(autoplay_animation, 0.0)

func _apply_materials() -> void:
	var model := get_node_or_null("Model")
	if model != null:
		CelMaterials.apply(model, cel_shading_enabled)

func _resolve_clip(requested: StringName) -> StringName:
	if animation_player == null:
		return &""
	if animation_player.has_animation(requested):
		return requested
	for clip in animation_player.get_animation_list():
		if str(clip).ends_with("/" + str(requested)):
			return clip
	return &""

func _configure_loops() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://runner/animations/animations.json"))
	if not parsed is Dictionary:
		return
	for metadata in parsed.get("animations", []):
		var clip := _resolve_clip(StringName(str(metadata["name"])))
		if not clip.is_empty():
			animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if bool(metadata.get("loop", false)) else Animation.LOOP_NONE

func play_animation(name: StringName, blend_seconds: float = 0.12) -> bool:
	var clip := _resolve_clip(name)
	if clip.is_empty():
		return false
	animation_player.play(clip, maxf(blend_seconds, 0.0))
	animation_player.advance(0.0)
	resume_authored_face_keys()
	if face_animation != null:
		face_animation.apply_animation_face(str(clip), 0.0, true)
	if belt != null and blend_seconds <= 0.0:
		belt.reset_motion()
	return true

func get_animation_names() -> PackedStringArray:
	return animation_player.get_animation_list() if animation_player != null else PackedStringArray()

func _manual_face() -> void:
	if face_animation != null:
		face_animation.enabled = false
	if face_controller != null:
		face_controller.automatic_blinking = automatic_blinking

func set_eyes(expression: String) -> bool:
	_manual_face()
	return face_controller.set_eyes(expression) if face_controller != null else false

func set_brows(expression: String) -> bool:
	_manual_face()
	return face_controller.set_brows(expression) if face_controller != null else false

func set_mouth(expression: String) -> bool:
	_manual_face()
	return face_controller.set_mouth(expression) if face_controller != null else false

func set_expression(expression: String) -> bool:
	_manual_face()
	return face_controller.set_expression(expression) if face_controller != null else false

func restore_neutral() -> void:
	_manual_face()
	if face_controller != null:
		face_controller.restore_neutral()

func resume_authored_face_keys() -> void:
	if face_animation != null:
		face_animation.enabled = use_authored_face_keys
	if face_controller != null:
		face_controller.automatic_blinking = automatic_blinking and not use_authored_face_keys

func apply_animation_face(clip: String, playback_seconds: float) -> bool:
	return face_animation.apply_animation_face(clip, playback_seconds) if face_animation != null else false

func set_belt_physics_enabled(value: bool) -> void:
	belt_physics_enabled = value
	if belt != null:
		belt.set_enabled(value)

func reset_belt_motion() -> void:
	if belt != null:
		belt.reset_motion()

func _on_animation_finished(name: StringName) -> void:
	animation_finished.emit(name)

func _on_expression_changed(state: Dictionary) -> void:
	expression_changed.emit(state)
