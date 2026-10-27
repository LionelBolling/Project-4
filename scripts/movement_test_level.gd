@tool
extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/movement_test_player.gd")
const RUNNER = preload("res://runner/runner.tscn")
var course_root: Node3D

func _ready() -> void:
	if Engine.is_editor_hint():
		_build_course()
		return
	_build_lighting()
	_build_course()
	_build_player()
	_build_hud()

func _build_lighting() -> void:
	var env := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_SKY
	world.sky = Sky.new()
	world.sky.sky_material = ProceduralSkyMaterial.new()
	world.glow_enabled = true
	world.glow_intensity = 1.15
	world.glow_strength = 1.25
	world.glow_bloom = 0.12
	world.glow_hdr_threshold = 0.8
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("8074b8")
	world.ambient_light_energy = 0.55
	env.environment = world
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

func _build_course() -> void:
	if has_node("CourseGeometry"):
		course_root = get_node("CourseGeometry") as Node3D
		return
	course_root = Node3D.new()
	course_root.name = "CourseGeometry"
	add_child(course_root)
	_assign_editor_owner(course_root)
	var floor_mat := _mat(Color("252044"))
	var neon_cyan := _mat(Color("1fe5dd"), 1.2)
	var neon_pink := _mat(Color("fa45b8"), 1.0)
	var gold := _mat(Color("ffc857"), 0.8)
	# Large open plaza for free movement, stopping, turning, and direction changes.
	# It connects directly to the straight acceleration runway and platform route.
	_solid(Vector3(0, -0.12, 17), Vector3(64, 0.24, 58), floor_mat)
	_solid(Vector3(0, 0.02, -17), Vector3(8, 0.08, 38), _mat(Color("39275e")))
	for x in [-4.1, 4.1]:
		_solid(Vector3(x, 0.12, -17), Vector3(0.16, 0.14, 38), neon_cyan)

	# A single straight line of platforms with wider jumps, including a long glide gap.
	var platforms := [
		[Vector3(0, 0.25, -41), Vector3(7.0, 0.5, 7.0), gold],
		[Vector3(0, 0.85, -52), Vector3(7.0, 0.5, 6.0), neon_pink],
		[Vector3(0, 1.55, -64), Vector3(7.5, 0.5, 6.0), neon_cyan],
		[Vector3(0, 0.55, -76), Vector3(8.0, 0.5, 7.0), gold],
		[Vector3(0, 1.4, -90), Vector3(7.0, 0.5, 6.5), neon_pink],
		[Vector3(0, 2.15, -104), Vector3(7.5, 0.5, 7.0), neon_cyan],
		[Vector3(0, 0.3, -118), Vector3(9.0, 0.5, 8.0), gold],
		[Vector3(0, 1.1, -132), Vector3(7.0, 0.5, 6.5), neon_pink],
		[Vector3(0, 2.0, -146), Vector3(8.0, 0.5, 7.0), neon_cyan],
		[Vector3(0, 0.4, -160), Vector3(10.0, 0.5, 9.0), gold],
	]
	for platform in platforms:
		_solid(platform[0], platform[1], platform[2])

	# More, longer wall-run surfaces alternate sides along the platform route.
	var walls := [
		[Vector3(-4.8, 4.0, -18), Vector3(0.5, 8.0, 40.0), neon_cyan],
		[Vector3(4.8, 4.0, -18), Vector3(0.5, 8.0, 40.0), neon_pink],
		[Vector3(-4.8, 4.0, -48), Vector3(0.5, 8.0, 14.0), neon_cyan],
		[Vector3(4.8, 4.0, -62), Vector3(0.5, 8.0, 14.0), neon_pink],
		[Vector3(-4.8, 4.0, -76), Vector3(0.5, 8.0, 14.0), neon_cyan],
		[Vector3(4.8, 4.0, -90), Vector3(0.5, 8.0, 14.0), neon_pink],
		[Vector3(-4.8, 4.0, -104), Vector3(0.5, 8.0, 14.0), neon_cyan],
		[Vector3(4.8, 4.0, -118), Vector3(0.5, 8.0, 14.0), neon_pink],
		[Vector3(-4.8, 4.0, -132), Vector3(0.5, 8.0, 14.0), neon_cyan],
		[Vector3(4.8, 4.0, -146), Vector3(0.5, 8.0, 14.0), neon_pink],
	]
	for wall in walls:
		_solid(wall[0], wall[1], wall[2])

	_caption("OPEN RUN + TURN AREA", Vector3(0, 2.0, 34), Color("55f5e0"))
	_caption("JUMP PLATFORMS", Vector3(0, 3.1, -39), Color("ffc857"))
	_caption("LEFT WALL RUN", Vector3(-4.2, 5.5, -45), Color("75e9ff"))
	_caption("RIGHT WALL RUN", Vector3(4.2, 5.5, -63), Color("fa76ca"))
	_caption("GLIDE GAP", Vector3(0, 3.1, -81), Color("75e9ff"))
	_caption("DIVE / PRECISION", Vector3(0, 3.0, -110), Color("ffc857"))

func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 0.05, 8)
	player.floor_snap_length = 0.35
	player.floor_max_angle = deg_to_rad(48)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	collision.position.y = 0.9
	player.add_child(collision)
	var runner := RUNNER.instantiate()
	runner.name = "Runner"
	player.add_child(runner)
	var pivot := Node3D.new()
	pivot.name = "CameraPivot"
	pivot.position.y = 1.45
	player.add_child(pivot)
	var arm := SpringArm3D.new()
	arm.name = "SpringArm3D"
	arm.spring_length = 5.2
	arm.margin = 0.25
	pivot.add_child(arm)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position.z = 0.15
	camera.fov = 78
	arm.add_child(camera)
	camera.current = true
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var title := Label.new()
	title.text = "NEON MOVEMENT LAB"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("62f4e1"))
	column.add_child(title)
	var info := Label.new()
	info.text = "WASD move freely   •   Mouse camera\nSpace jump   •   Hold Shift in air to glide\nLeft Ctrl dive   •   Esc release/capture mouse"
	info.add_theme_font_size_override("font_size", 14)
	column.add_child(info)
	var status := Label.new()
	status.name = "Status"
	status.text = "STATE  IDLE     SPEED  0.0"
	status.add_theme_color_override("font_color", Color("ffc857"))
	column.add_child(status)
	(get_node("Player") as MovementTestPlayer).status_label = status

func _solid(pos: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var kind := "Wall" if size.y >= 4.0 and size.x < 1.0 else "Floor" if size.y < 0.25 else "Platform"
	var kind_count := 1
	for sibling in course_root.get_children():
		if sibling is StaticBody3D and str(sibling.name).begins_with(kind + "_"):
			kind_count += 1
	body.name = "%s_%02d" % [kind, kind_count]
	course_root.add_child(body)
	_assign_editor_owner(body)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	_assign_editor_owner(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	_assign_editor_owner(collision)

func _mat(color: Color, glow := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material

func _caption(text: String, pos: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = text.to_pascal_case().replace(" ", "")
	label.text = text
	label.position = pos
	label.font_size = 48
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 8
	label.outline_modulate = Color("171326")
	course_root.add_child(label)
	_assign_editor_owner(label)

func _assign_editor_owner(node: Node) -> void:
	if Engine.is_editor_hint():
		var scene_root := get_tree().edited_scene_root
		if scene_root != null:
			node.owner = scene_root

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.12, 0.88)
	style.border_color = Color("46e8df")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style
