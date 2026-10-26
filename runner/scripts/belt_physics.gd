extends Node
## Godot 4.5+ native spring modifier. Only Belt_01 through Belt_06 are simulated.
## Body/case colliders read existing poses; no rest bone or other bone is modified.
signal configured
var root_stiffness: float = 1.5
var tip_stiffness: float = 0.35
var drag: float = 0.30
var gravity: float = 1.0
var wind: Vector3 = Vector3.ZERO
var teleport_distance: float = 1.5
var enabled: bool = true
var simulator: SpringBoneSimulator3D
var _skeleton: Skeleton3D
var _config: Dictionary = {}
var _last_anchor: Vector3
var _has_anchor: bool = false
var _pelvis: int = -1
var _ready_chain: bool = false

func bind_skeleton(skeleton: Skeleton3D, config_path: String = "res://runner/assets/belt_config.json") -> bool:
	if skeleton == null:
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(config_path))
	if not parsed is Dictionary:
		push_error("Runner: belt configuration is missing")
		return false
	var chain: Array = parsed.get("bone_names", [])
	if chain.size() != 6:
		return false
	for i in range(chain.size()):
		var index := skeleton.find_bone(str(chain[i]))
		if index < 0 or (i > 0 and skeleton.get_bone_parent(index) != skeleton.find_bone(str(chain[i - 1]))):
			push_error("Runner: the six original belt bones must form one chain")
			return false
	_skeleton = skeleton
	_config = parsed
	_pelvis = skeleton.find_bone("Pelvis")
	call_deferred("_create_simulator")
	return true

func _create_simulator() -> void:
	if not is_instance_valid(_skeleton):
		return
	if is_instance_valid(simulator):
		simulator.queue_free()
	simulator = SpringBoneSimulator3D.new()
	simulator.name = "BeltSpringPhysics"
	simulator.active = false
	_skeleton.add_child(simulator)
	simulator.setting_count = 1
	var chain: Array = _config["bone_names"]
	simulator.set_root_bone_name(0, str(chain[0]))
	simulator.set_end_bone_name(0, str(chain[5]))
	simulator.set_extend_end_bone(0, true)
	simulator.set_end_bone_direction(0, SpringBoneSimulator3D.BONE_DIRECTION_PLUS_Y)
	simulator.set_end_bone_length(0, float(_config["last_bone_length"]))
	# World center retains inertia when the whole character moves or turns.
	simulator.set_center_from(0, SpringBoneSimulator3D.CENTER_FROM_WORLD_ORIGIN)
	simulator.set_individual_config(0, true)
	for definition in _config.get("colliders", []):
		if _skeleton.find_bone(str(definition["bone"])) < 0:
			continue
		var collider := SpringBoneCollisionCapsule3D.new()
		collider.name = "BeltCollider_" + str(definition["name"])
		simulator.add_child(collider)
		collider.bone_name = str(definition["bone"])
		collider.radius = float(definition["radius"])
		collider.height = float(definition["height"])
		var offset: Array = definition.get("position_offset", [0, 0, 0])
		collider.position_offset = Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
		if definition.has("rotation_axis"):
			var axis: Array = definition["rotation_axis"]
			collider.rotation_offset = Quaternion(Vector3(float(axis[0]), float(axis[1]), float(axis[2])).normalized(), float(definition["rotation_angle"]))
	simulator.set_enable_all_child_collisions(0, true)
	call_deferred("_finish_setup")

func _finish_setup() -> void:
	if not is_instance_valid(simulator):
		return
	var chain: Array = _config["bone_names"]
	if simulator.get_joint_count(0) != 6:
		push_error("Runner: belt spring chain did not resolve to the six belt joints")
		return
	for i in range(6):
		if simulator.get_joint_bone_name(0, i) != str(chain[i]):
			push_error("Runner: belt spring joint name mismatch")
			return
	_ready_chain = true
	apply_tuning()
	set_enabled(enabled)
	reset_motion()
	configured.emit()

func apply_tuning() -> void:
	if not _ready_chain or not is_instance_valid(simulator):
		return
	for i in range(6):
		var weight := float(i) / 5.0
		simulator.set_joint_stiffness(0, i, lerpf(root_stiffness, tip_stiffness, weight))
		simulator.set_joint_drag(0, i, clampf(drag, 0.0, 1.0))
		simulator.set_joint_gravity(0, i, maxf(gravity, 0.0))
		simulator.set_joint_gravity_direction(0, i, Vector3.DOWN)
		simulator.set_joint_radius(0, i, lerpf(float(_config.get("root_radius", 0.012)), float(_config.get("tip_radius", 0.032)), weight))
	simulator.external_force = wind

func set_enabled(value: bool) -> void:
	enabled = value
	if _ready_chain and is_instance_valid(simulator):
		simulator.active = value
		simulator.influence = 1.0 if value else 0.0
		if value:
			reset_motion()

func reset_motion() -> void:
	_has_anchor = false
	if _ready_chain and is_instance_valid(simulator):
		simulator.reset()

func _process(delta: float) -> void:
	if not _ready_chain or not is_instance_valid(_skeleton) or not is_instance_valid(simulator):
		return
	simulator.external_force = wind
	var anchor := _skeleton.global_position
	if _pelvis >= 0:
		anchor = _skeleton.global_transform * _skeleton.get_bone_global_pose(_pelvis).origin
	if not _has_anchor or anchor.distance_to(_last_anchor) > teleport_distance or delta > 0.25:
		simulator.reset()
	_last_anchor = anchor
	_has_anchor = true

func _exit_tree() -> void:
	# The simulator belongs to the model's skeleton and shares its lifetime.
	# Keeping it attached also supports removing/readding a pooled character.
	_has_anchor = false
