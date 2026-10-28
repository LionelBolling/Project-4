@tool
extends Node3D
## Shared interface for all three monster scenes. No movement or combat AI.
const Eyes = preload("eye_controller.gd")
const Toon = preload("toon_materials.gd")
signal animation_finished(animation_name: StringName)

@export_file("*.json") var config_file: String = ""
@export var autoplay_animation: StringName = &"idle"
@export var toon_enabled: bool = true:
	set(value):
		toon_enabled = value
		if is_inside_tree():
			call_deferred("_apply_materials")
@export_enum("normal", "hurt") var preview_eyes: String = "normal":
	set(value):
		preview_eyes = value
		if Engine.is_editor_hint() and eye_controller != null:
			eye_controller.set_eyes(StringName(value))

var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var eye_controller
var _config: Dictionary = {}
var _manual_eyes: bool = false

func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(config_file))
	if parsed is Dictionary:
		_config = parsed
	var model := get_node("Model")
	var players := model.find_children("*", "AnimationPlayer", true, false)
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if not players.is_empty():
		animation_player = players[0] as AnimationPlayer
	if not skeletons.is_empty():
		skeleton = skeletons[0] as Skeleton3D
	eye_controller = Eyes.new()
	if not eye_controller.bind_model(model):
		push_error("Monster: normal or hurt eye mesh was not imported")
	_apply_materials()
	_configure_loops()
	if Engine.is_editor_hint():
		eye_controller.set_eyes(StringName(preview_eyes))
		return
	if animation_player != null:
		animation_player.animation_finished.connect(_on_animation_finished)
		if not autoplay_animation.is_empty():
			play_animation(autoplay_animation, 0.0)

func _apply_materials() -> void:
	var model := get_node_or_null("Model")
	if model != null:
		Toon.apply(model, _config.get("flat_materials", []), toon_enabled)

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
	for entry in _config.get("animations", []):
		var clip := _resolve_clip(StringName(str(entry["name"])))
		if not clip.is_empty():
			animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if bool(entry.get("loop", true)) else Animation.LOOP_NONE

func play_animation(name: StringName, blend_seconds: float = 0.12) -> bool:
	var clip := _resolve_clip(name)
	if clip.is_empty():
		return false
	_manual_eyes = false
	animation_player.play(clip, maxf(blend_seconds, 0.0))
	animation_player.advance(0.0)
	apply_animation_eyes(name, 0.0)
	return true

func play_idle(blend_seconds: float = 0.12) -> bool:
	return play_animation(&"idle", blend_seconds)

func play_hurt(blend_seconds: float = 0.08) -> bool:
	return play_animation(&"hurt", blend_seconds)

func set_eyes(expression_name: StringName) -> bool:
	_manual_eyes = true
	return eye_controller.set_eyes(expression_name) if eye_controller != null else false

func resume_animation_eyes() -> void:
	_manual_eyes = false

func apply_animation_eyes(clip: StringName, position_seconds: float) -> void:
	if eye_controller == null:
		return
	var name := str(clip).get_slice("/", str(clip).get_slice_count("/") - 1)
	for entry in _config.get("animations", []):
		if str(entry["name"]) != name:
			continue
		var state: StringName = &"hurt" if name == "hurt" else &"normal"
		for event in entry.get("eye_events", []):
			if float(event["time"]) <= position_seconds + 0.0001:
				state = StringName(str(event["eyes"]))
			else:
				break
		eye_controller.set_eyes(state)
		return

func get_animation_names() -> PackedStringArray:
	return animation_player.get_animation_list() if animation_player != null else PackedStringArray()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _manual_eyes or animation_player == null:
		return
	if animation_player.is_playing():
		apply_animation_eyes(animation_player.current_animation, animation_player.current_animation_position)

func _on_animation_finished(name: StringName) -> void:
	animation_finished.emit(name)
