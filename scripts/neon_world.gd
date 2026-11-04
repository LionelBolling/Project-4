extends Node3D
## Shared city surrounding every course, with streets below the parkour route.
@export var district_length := 540.0
@export var endless := false
@export var building_offset := 0.0
@export var accent := Color("ff43c8")
@export var safety_street_y := -8.5
var _batches: Dictionary = {}
var _materials: Dictionary = {}
var _districts: Array[Node3D] = []
var _traffic: Array[Node3D] = []
var _player: Node3D
var _time := 0.0
var _street: StaticBody3D
var _last_safe_position := Vector3.ZERO

func _ready() -> void:
	call_deferred("_build")

func _build() -> void:
	_player = get_parent().get_node_or_null("Player")
	_materials["shell"] = _material(Color("101329"), false)
	_materials["roof"] = _material(Color("202547"), false)
	_materials["cyan"] = _material(Color("24dcf5"), true)
	_materials["pink"] = _material(accent, true)
	_materials["gold"] = _material(Color("ffc878"), true)
	_materials["grid"] = _material(Color("16345c"), true)
	_apply_night()
	var old_backdrop := get_parent().get_node_or_null("BackdropShapes")
	if old_backdrop:
		old_backdrop.hide()
		old_backdrop.set_process(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 48026
	var count := ceili(district_length / 60.0) + 3
	for block in range(count):
		var district := Node3D.new()
		district.name = "District_%02d" % block
		district.position.z = 60.0 - block * 60.0
		add_child(district)
		_districts.append(district)
		_build_district(district, block, rng)
		_flush(district)
	_build_landmark()
	_build_safe_street()
	if is_instance_valid(_player): _last_safe_position = _player.global_position
	for camera in get_parent().find_children("*", "Camera3D", true, false):
		if camera.get_viewport() == get_viewport(): camera.far = maxf(camera.far, 480.0)

func _material(color: Color, luminous: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	if luminous:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.65
	return mat

func _box(kind: String, p: Vector3, size: Vector3) -> void:
	if not _batches.has(kind): _batches[kind] = []
	_batches[kind].append(Transform3D(Basis.from_scale(size), p))

func _flush(parent: Node3D) -> void:
	# Hundreds of windows and facade strips share a handful of draw calls.
	for kind in _batches:
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = mesh
		instances.instance_count = _batches[kind].size()
		for i in range(instances.instance_count):
			instances.set_instance_transform(i, _batches[kind][i])
		var visual := MultiMeshInstance3D.new()
		visual.name = kind.capitalize()
		visual.multimesh = instances
		visual.material_override = _materials[kind]
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if kind in ["cyan", "pink", "gold", "grid"]:
			visual.visibility_range_end = 320.0
		parent.add_child(visual)
	_batches.clear()

func _build_district(district: Node3D, index: int, rng: RandomNumberGenerator) -> void:
	# The boulevard and grid sit far below the playable floating tracks.
	_box("shell", Vector3(0, -46, 0), Vector3(300, 2, 60))
	for z in range(-30, 31, 10):
		_box("grid", Vector3(0, -44.9, z), Vector3(300, 0.06, 0.08))
	for x in range(-150, 151, 10):
		_box("grid", Vector3(x, -44.9, 0), Vector3(0.08, 0.06, 60))
	for side_index in range(2):
		var side := -1.0 if side_index == 0 else 1.0
		var neon := "cyan" if side < 0 else "pink"
		for row in range(2):
			for slot in range(3):
				var x := side * (48.0 + building_offset + row * 46.0 + rng.randf_range(0, 12))
				var z := -22.0 + slot * 21.0 + rng.randf_range(-3, 3)
				var height := rng.randf_range(42, 88) + row * 18.0
				var width := rng.randf_range(10, 17)
				var depth := rng.randf_range(10, 16)
				var top := height - 44.0
				_solid_box(district, Vector3(x, height / 2 - 44, z), Vector3(width, height, depth), "TowerCollision")
				_box("shell", Vector3(x, height / 2 - 44, z), Vector3(width, height, depth))
				_box("roof", Vector3(x, top + 0.5, z), Vector3(width + 0.7, 1, depth + 0.7))
				for edge in [-1.0, 1.0]:
					_box(neon, Vector3(x + edge * width / 2, height / 2 - 44, z + depth / 2 + 0.06), Vector3(0.14, height, 0.14))
				_box(neon, Vector3(x, top + 1.1, z), Vector3(width + 0.8, 0.15, depth + 0.8))
				for floor_index in range(2, int(height / 3.5), 2):
					for column in range(4):
						if rng.randf() < 0.25: continue
						var wx := x - width * 0.36 + column * width * 0.24
						_box(neon if floor_index % 4 else "gold", Vector3(wx, -44 + floor_index * 3.5, z + depth / 2 + 0.08), Vector3(width * 0.12, 0.65, 0.1))
				# Inward-facing facade lights stay visible from gameplay cameras.
				for floor_index in range(3, int(height / 4.0), 2):
					_box(neon, Vector3(x - side * (width / 2 + 0.08), -44 + floor_index * 4, z), Vector3(0.1, 0.4, depth * 0.7))
				if slot == 1:
					_box(neon, Vector3(x, top + 5, z), Vector3(0.18, 8, 0.18))
		# Elevated side avenues connect blocks, leaving the course clear.
		_box("roof", Vector3(side * 35, -22, 0), Vector3(12, 1.1, 60))
		_box(neon, Vector3(side * 29, -21.35, 0), Vector3(0.16, 0.18, 60))
		_box(neon, Vector3(side * 41, -21.35, 0), Vector3(0.16, 0.18, 60))
		if index % 2 == 0:
			var sign := Label3D.new()
			sign.text = ["NEON FEVER", "REWIND", "AFTER HOURS", "TAPE CITY"][int(index / 2) % 4]
			sign.font_size = 80
			sign.pixel_size = 0.025
			sign.modulate = Color("24dcf5") if side < 0 else accent
			sign.outline_size = 10
			sign.position = Vector3(side * 45, 12, -8)
			sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			district.add_child(sign)
		var traffic := Node3D.new()
		traffic.position = Vector3(side * 35, -18, -24)
		district.add_child(traffic)
		var car := MeshInstance3D.new()
		var car_mesh := BoxMesh.new()
		car_mesh.size = Vector3(1.2, 0.25, 4)
		car.mesh = car_mesh
		car.material_override = _materials[neon]
		traffic.add_child(car)
		_traffic.append(traffic)
	# High skybridges frame the route without blocking jumps or cameras.
	if index % 3 == 0:
		_box("roof", Vector3(0, 38, -12), Vector3(108, 1.5, 5))
		_box("pink", Vector3(0, 37.1, -9.4), Vector3(108, 0.15, 0.15))
		_box("cyan", Vector3(0, 39, -14.6), Vector3(108, 0.15, 0.15))

func _build_landmark() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "HorizonHalo"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 32
	mesh.outer_radius = 33
	mesh.rings = 64
	mesh.ring_segments = 12
	ring.mesh = mesh
	ring.material_override = _materials["pink"]
	ring.rotation.x = PI / 2
	ring.position = Vector3(-80, 78, -district_length - 70)
	add_child(ring)

func _apply_night() -> void:
	for world in get_parent().find_children("*", "WorldEnvironment", true, false):
		var env: Environment = world.environment.duplicate()
		var sky := ProceduralSkyMaterial.new()
		sky.sky_top_color = Color("030517")
		sky.sky_horizon_color = Color("24113f")
		sky.ground_bottom_color = Color("030517")
		sky.ground_horizon_color = Color("24113f")
		sky.sky_energy_multiplier = 0.55
		sky.sky_curve = 0.2
		env.background_mode = Environment.BG_SKY
		env.sky = Sky.new()
		env.sky.sky_material = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("7b83c2")
		env.ambient_light_energy = 0.65
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		world.environment = env
	for sun in get_parent().find_children("*", "DirectionalLight3D", true, false):
		sun.light_color = Color("adb9ff")
		sun.light_energy = 0.75

func _process(delta: float) -> void:
	_time += delta
	for i in range(_traffic.size()):
		_traffic[i].position.z = fposmod(_time * (8.0 + i % 3) + i * 13.0, 58.0) - 29.0
	if endless and is_instance_valid(_player):
		for district in _districts:
			while district.global_position.z > _player.global_position.z + 150:
				district.position.z -= _districts.size() * 60.0

func _solid_box(parent: Node3D, p: Vector3, size: Vector3, label: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	parent.add_child(body, true)
	body.position = p
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body

func _build_safe_street() -> void:
	var length := maxf(district_length + 240, 600)
	var p := Vector3(0, safety_street_y - global_position.y, -district_length * 0.5)
	_street = _solid_box(self, p, Vector3(520, 1, length), "CityStreetSafety")
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(520, 1, length)
	mesh.mesh = box
	mesh.material_override = _materials["shell"]
	_street.add_child(mesh)
	for x in [-24, 24]:
		var strip := MeshInstance3D.new()
		var strip_mesh := BoxMesh.new()
		strip_mesh.size = Vector3(0.12, 0.04, length)
		strip.mesh = strip_mesh
		strip.position = Vector3(x, 0.53, 0)
		strip.material_override = _materials["cyan"]
		_street.add_child(strip)

func _physics_process(_dt: float) -> void:
	if not is_instance_valid(_player) or not _player is CharacterBody3D: return
	if endless and is_instance_valid(_street): _street.global_position.z = _player.global_position.z
	if _player.is_on_floor():
		if _player.global_position.y > -4:
			_last_safe_position = _player.global_position
		elif is_instance_valid(_street) and _player.global_position.y <= _street.global_position.y + 1.0:
			# A missed jump lands on the city street instead of falling forever.
			_player.global_position = _last_safe_position + Vector3.UP * 0.15
			_player.velocity = Vector3.ZERO
