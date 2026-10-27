extends Node
## Independent painted enemy expression layers. Attach beneath the imported character,
## or call bind_face(character_root). No skeleton or movement code is required.
## Add variants through exported dictionaries or register_texture(), without
## changing the head mesh. Textures use the supplied aligned 1024x512 templates.

signal expression_changed(state: Dictionary)

@export var face_root: NodePath
@export var automatic_blinking: bool = true
@export_range(0.05, 30.0) var blink_interval_min: float = 3.0
@export_range(0.05, 30.0) var blink_interval_max: float = 6.0
@export_range(0.02, 1.0) var blink_duration: float = 0.12
@export var eye_textures: Dictionary = {}
@export var brow_textures: Dictionary = {}
@export var mouth_textures: Dictionary = {}
@export var nose_textures: Dictionary = {}
@export var expression_presets: Dictionary = {}

const DEFAULT_EYES = {
	"neutral": preload("res://enemy_runner/textures/face/eyes/neutral.png"),
	"closed": preload("res://enemy_runner/textures/face/eyes/closed.png"),
	"surprised": preload("res://enemy_runner/textures/face/eyes/surprised.png"),
}
const DEFAULT_BROWS = {
	"regular": preload("res://enemy_runner/textures/face/eyebrows/regular.png"),
	"expressive": preload("res://enemy_runner/textures/face/eyebrows/expressive.png"),
}
const DEFAULT_MOUTH = {
	"smile": preload("res://enemy_runner/textures/face/mouth/smile.png"),
	"frown": preload("res://enemy_runner/textures/face/mouth/frown.png"),
	"open": preload("res://enemy_runner/textures/face/mouth/open.png"),
}
const DEFAULT_NOSE = {"regular": preload("res://enemy_runner/textures/face/nose/regular.png")}
const DEFAULT_PRESETS = {
	"neutral": {"eyes": "neutral", "brows": "regular", "mouth": "smile"},
	"smile": {"eyes": "neutral", "brows": "regular", "mouth": "smile"},
	"closed": {"eyes": "closed", "brows": "regular", "mouth": "smile"},
	"surprised": {"eyes": "surprised", "brows": "expressive", "mouth": "open"},
	"frown": {"eyes": "neutral", "brows": "expressive", "mouth": "frown"},
	"open": {"eyes": "neutral", "brows": "regular", "mouth": "open"},
}
const PATCH_NAMES = {"eyes": "Face_Eyes", "brows": "Face_Brows", "nose": "Face_Nose", "mouth": "Face_Mouth"}

var _libraries: Dictionary = {}
var _presets: Dictionary = {}
var _meshes: Dictionary = {}
var _materials: Dictionary = {}
var _state: Dictionary = {"eyes": "neutral", "brows": "regular", "nose": "regular", "mouth": "smile"}
var _displayed_eyes: String = "neutral"
var _blink_remaining: float = 0.0
var _until_blink: float = 4.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_ensure_libraries()
	var root: Node = get_node_or_null(face_root) if not face_root.is_empty() else get_parent()
	if root != null:
		bind_face(root)
	_schedule_blink()

func _ensure_libraries() -> void:
	if not _libraries.is_empty():
		return
	_libraries = {"eyes": DEFAULT_EYES.duplicate(), "brows": DEFAULT_BROWS.duplicate(),
		"mouth": DEFAULT_MOUTH.duplicate(), "nose": DEFAULT_NOSE.duplicate()}
	for pair in [["eyes", eye_textures], ["brows", brow_textures], ["mouth", mouth_textures], ["nose", nose_textures]]:
		for key in pair[1]:
			if pair[1][key] is Texture2D:
				_libraries[pair[0]][_key(str(key))] = pair[1][key]
	_presets = DEFAULT_PRESETS.duplicate(true)
	for key in expression_presets:
		_presets[_key(str(key))] = expression_presets[key]

func bind_face(root: Node) -> bool:
	_ensure_libraries()
	_meshes.clear()
	_materials.clear()
	var complete := true
	var priority := 1
	for system in PATCH_NAMES:
		var patch := root.find_child(PATCH_NAMES[system], true, false) as MeshInstance3D
		if patch == null:
			complete = false
			continue
		var material := StandardMaterial3D.new()
		material.resource_name = "RunnerFace_" + str(system)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_BACK
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		material.albedo_color = Color.WHITE
		material.render_priority = priority
		priority += 1
		patch.material_override = material
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_meshes[system] = patch
		_materials[system] = material
	for system in _state:
		_apply(system, _state[system])
	return complete

func _key(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "_")

func _apply(system: String, expression: String) -> void:
	if _materials.has(system):
		var material: StandardMaterial3D = _materials[system]
		material.albedo_texture = _libraries[system][expression]
	if system == "eyes":
		_displayed_eyes = expression

func _valid(system: String, expression: String) -> bool:
	_ensure_libraries()
	return _libraries.has(system) and _libraries[system].has(expression) and _libraries[system][expression] is Texture2D

func _set_part(system: String, expression_name: String) -> bool:
	var expression := _key(expression_name)
	if system == "brows" and expression in ["angled", "expressive/angled"]:
		expression = "expressive"
	if not _valid(system, expression):
		return false
	_state[system] = expression
	if system == "eyes":
		_blink_remaining = 0.0
		_schedule_blink()
	_apply(system, expression)
	expression_changed.emit(get_state())
	return true

func set_eyes(expression_name: String) -> bool:
	return _set_part("eyes", expression_name)

func set_brows(expression_name: String) -> bool:
	return _set_part("brows", expression_name)

func set_mouth(expression_name: String) -> bool:
	return _set_part("mouth", expression_name)

func set_nose(expression_name: String = "regular") -> bool:
	return _set_part("nose", expression_name)

func set_expression(expression_name: String) -> bool:
	_ensure_libraries()
	var name := _key(expression_name)
	if not _presets.has(name) or not _presets[name] is Dictionary:
		return false
	var preset: Dictionary = _presets[name]
	# Validate the whole combination before changing any layer.
	for system in ["eyes", "brows", "mouth"]:
		if not preset.has(system) or not _valid(system, _key(str(preset[system]))):
			return false
	set_eyes(str(preset["eyes"]))
	set_brows(str(preset["brows"]))
	set_mouth(str(preset["mouth"]))
	return true

func restore_neutral() -> void:
	set_expression("neutral")
	set_nose("regular")

func register_texture(system_name: String, expression_name: String, texture: Texture2D) -> bool:
	_ensure_libraries()
	var system := _key(system_name)
	if system == "eyebrows":
		system = "brows"
	var expression := _key(expression_name)
	if not _libraries.has(system) or texture == null or expression.is_empty():
		return false
	_libraries[system][expression] = texture
	return true

func get_state() -> Dictionary:
	var state := _state.duplicate()
	state["displayed_eyes"] = _displayed_eyes
	state["blinking"] = _blink_remaining > 0.0
	return state

func available_expressions(system_name: String) -> Array:
	_ensure_libraries()
	var system := _key(system_name)
	if system == "eyebrows":
		system = "brows"
	if not _libraries.has(system):
		return []
	var result: Array = _libraries[system].keys()
	result.sort()
	return result

func _schedule_blink() -> void:
	_until_blink = _rng.randf_range(maxf(.05, blink_interval_min), maxf(blink_interval_min, blink_interval_max))

func blink_now() -> bool:
	_ensure_libraries()
	if _state["eyes"] == "closed" or not _valid("eyes", "closed"):
		return false
	_blink_remaining = maxf(.02, blink_duration)
	_apply("eyes", "closed")
	return true

func _process(delta: float) -> void:
	if _blink_remaining > 0.0:
		_blink_remaining -= delta
		if _blink_remaining <= 0.0:
			_blink_remaining = 0.0
			_apply("eyes", _state["eyes"])
			_schedule_blink()
		return
	if automatic_blinking:
		_until_blink -= delta
		if _until_blink <= 0.0:
			blink_now()
			_schedule_blink()
