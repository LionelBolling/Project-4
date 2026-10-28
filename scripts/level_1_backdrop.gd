extends Node3D

@export_range(0.0, 2.0, 0.05) var float_height := 0.45
@export_range(0.0, 2.0, 0.05) var rotation_speed := 0.32

@onready var _camera_pivot: Node3D = get_parent().get_node("Player/CameraPivot")
@onready var _camera: Camera3D = get_parent().get_node("Player/CameraPivot/SpringArm3D/Camera3D")

var _base_positions: Array[Vector3] = []
var _base_rolls: Array[float] = []
var _phase_offsets: Array[float] = []

func _ready() -> void:
	_create_sky_shapes()
	for index in range(get_child_count()):
		var shape := get_child(index) as Node3D
		_base_positions.append(shape.position)
		_base_rolls.append(shape.rotation.z)
		_phase_offsets.append(float(index) * 1.71)

func _create_sky_shapes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4182026
	var palette := [Color("19cbb9"), Color("ffe34f"), Color("ff668e"), Color("7857cc"), Color("42bdf4"), Color("ff9c48")]
	var materials: Array[StandardMaterial3D] = []
	for color in palette:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.18
		materials.append(material)
	var circle_mesh := SphereMesh.new()
	circle_mesh.radius = 0.8
	circle_mesh.height = 1.6
	var triangle_mesh := CylinderMesh.new()
	triangle_mesh.top_radius = 0.72
	triangle_mesh.bottom_radius = 0.72
	triangle_mesh.height = 0.22
	triangle_mesh.radial_segments = 3
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.34
	ring_mesh.outer_radius = 0.46
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(2.0, 0.2, 0.42)
	var square_mesh := BoxMesh.new()
	square_mesh.size = Vector3(0.95, 0.95, 0.16)
	var mesh_options: Array[Mesh] = [circle_mesh, triangle_mesh, ring_mesh, bar_mesh, square_mesh]
	var shape_count := 84
	for index in range(shape_count):
		var angle := TAU * float(index) / float(shape_count) + rng.randf_range(-0.04, 0.04)
		var radius := rng.randf_range(62.0, 118.0)
		var shape := Node3D.new()
		shape.name = "SkyShape_%02d" % index
		shape.position = Vector3(sin(angle) * radius, rng.randf_range(8.0, 58.0), cos(angle) * radius)
		shape.rotation.z = rng.randf_range(-0.45, 0.45)
		add_child(shape)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh_options[index % mesh_options.size()]
		mesh_instance.material_override = materials[rng.randi_range(0, materials.size() - 1)]
		match index % mesh_options.size():
			0:
				mesh_instance.scale = Vector3(1.0, 1.0, 0.18) * rng.randf_range(1.0, 2.4)
			1, 2:
				mesh_instance.rotation_degrees.x = 90.0
				mesh_instance.scale = Vector3.ONE * rng.randf_range(1.0, 2.0)
			3:
				mesh_instance.scale = Vector3(rng.randf_range(0.8, 1.8), 1.0, 1.0)
			4:
				mesh_instance.scale = Vector3.ONE * rng.randf_range(0.9, 1.9)
		shape.add_child(mesh_instance)

func _process(delta: float) -> void:
	if is_instance_valid(_camera_pivot):
		global_position = _camera_pivot.global_position
	var time := Time.get_ticks_msec() * 0.001
	for index in range(get_child_count()):
		var shape := get_child(index) as Node3D
		shape.position.y = _base_positions[index].y + sin(time * 0.9 + _phase_offsets[index]) * float_height
		var direction := 1.0 if index % 2 == 0 else -1.0
		if is_instance_valid(_camera):
			shape.look_at(_camera.global_position, Vector3.UP)
			shape.rotate_object_local(Vector3(0.0, 0.0, 1.0), _base_rolls[index] + time * rotation_speed * direction)
