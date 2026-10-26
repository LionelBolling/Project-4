extends Node
## Applies authored Blender face keys alongside a Godot AnimationPlayer.
## Face shader drivers are exported as discrete events in this companion JSON.
@export var enabled: bool = true
var _player: AnimationPlayer
var _face
var _tracks: Dictionary = {}
var _last_event: String = ""

func _ready() -> void:
	load_tracks()

func load_tracks(path: String = "res://runner/animations/face_animation_tracks.json") -> bool:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Runner: could not read face animation tracks: " + path)
		return false
	_tracks = parsed.get("animations", {})
	_last_event = ""
	return true

func bind_player(player: AnimationPlayer, controller: Node) -> void:
	_player = player
	_face = controller
	_last_event = ""

func apply_animation_face(animation_name: String, time_seconds: float, force: bool = false) -> bool:
	if _face == null:
		return false
	var name := animation_name
	if not _tracks.has(name):
		for candidate in _tracks:
			if name.ends_with("/" + str(candidate)) or name.ends_with("_" + str(candidate)):
				name = str(candidate)
				break
	if not _tracks.has(name):
		return false
	var events: Array = _tracks[name].get("events", [])
	var event: Dictionary = {}
	for entry in events:
		if float(entry.get("time", 0.0)) <= time_seconds + 0.00001:
			event = entry
		else:
			break
	if event.is_empty():
		return false
	var event_key := name + ":" + str(event.get("time"))
	if force or event_key != _last_event:
		_face.set_eyes(str(event.get("eyes", "neutral")))
		_face.set_brows(str(event.get("eyebrows", "regular")))
		_face.set_mouth(str(event.get("mouth", "smile")))
		_last_event = event_key
	return true

func _process(_delta: float) -> void:
	if enabled and is_instance_valid(_player) and not _player.current_animation.is_empty():
		apply_animation_face(_player.current_animation, _player.current_animation_position)
