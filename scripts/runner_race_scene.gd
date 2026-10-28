@tool
extends Node3D

signal story_finished

const TRACK_LENGTH := 210.0
const START_Z := 8.0
const FINISH_Z := -192.0
const MAX_PROJECTILE_HOLES := 96

@onready var player: MovementTestPlayer = $Player
@onready var rival: RaceOpponent = $Rival

var race_state := "COUNTDOWN"
var countdown_time := 3.2
var finish_label: Label
var progress_label: Label
var player_status_label: Label
var restart_timer := 0.0
var projectile_hole_count := 0
var surface_replacements: Dictionary = {}
var hole_visuals: Array[Node3D] = []
const RESULTS_PAUSE := 3.0

func _ready() -> void:
	_build_track()
	if Engine.is_editor_hint():
		return
	_build_lighting()
	_build_hud()
	player.status_label = player_status_label
	rival.set_rubberband_target(player)
	rival.run_animation_speed_multiplier = player.run_animation_speed_multiplier
	rival.wall_run_animation_speed_multiplier = player.wall_run_animation_speed
	rival.wall_jump_animation_speed_multiplier = player.wall_jump_animation_speed
	rival.dive_land_animation_speed_multiplier = player.dive_land_animation_speed
	player.set_physics_process(false)
	rival.set_physics_process(false)
	_update_race_hud()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if race_state == "COUNTDOWN":
		countdown_time -= delta
		if countdown_time > 0.0:
			finish_label.text = str(ceili(countdown_time))
		else:
			_start_race()
	elif race_state == "RACING":
		_update_race_hud()
		if rival.touches_player_hazard(player.global_position + Vector3.UP * 0.9):
			player.play_hurt_animation()
		if player.global_position.z <= _finish_position() and player.velocity.z < 0.0:
			_finish_race(true)
		elif rival.global_position.z <= _finish_position():
			_finish_race(false)
	elif race_state == "FINISHED":
		_update_race_hud()
		restart_timer -= delta
		if restart_timer <= 0.0:
			_restart_race()

func _start_race() -> void:
	race_state = "RACING"
	finish_label.text = "GO!"
	player.jump_buffer = 0.0
	player.set_physics_process(true)
	rival.start_race()
	rival.set_physics_process(true)

func _finish_race(player_won: bool) -> void:
	race_state = "FINISHED"
	restart_timer = RESULTS_PAUSE
	_clear_rival_projectiles()
	player.set_physics_process(false)
	rival.stop_race()
	rival.set_physics_process(false)
	player.call("_set_animation", "Idle")
	finish_label.text = "YOU WIN!" if player_won else "RIVAL WINS"
	if has_meta("story_round"):
		finish_label.text = ""
		if player_won:
			race_state = "STORY_COMPLETE"
			story_finished.emit()

func _restart_race() -> void:
	_clear_environment_holes()
	player.call("_respawn_at_start")
	rival.reset_for_race()
	player.set_physics_process(false)
	rival.set_physics_process(false)
	race_state = "COUNTDOWN"
	countdown_time = 3.2
	finish_label.text = "3"
	if has_node("StoryCourse"):
		$StoryCourse.reset()

func _on_rival_projectile_surface_impact(hit_position: Vector3, surface_normal: Vector3, surface: Object, projectile_radius: float) -> void:
	projectile_hole_count += 1
	var hole_radius := maxf(projectile_radius * 1.35, 0.72)
	_create_hole_visual(hit_position, surface_normal, hole_radius)
	if projectile_hole_count <= MAX_PROJECTILE_HOLES:
		_add_csg_hole(surface, hit_position, hole_radius)

func _add_csg_hole(surface: Object, hit_position: Vector3, hole_radius: float) -> void:
	var source_body := _resolve_race_surface(surface)
	if source_body == null:
		return
	var surface_key := source_body.get_instance_id()
	var replacement: Dictionary = surface_replacements.get(surface_key, {})
	var combiner := replacement.get("combiner") as CSGCombiner3D
	if not is_instance_valid(combiner):
		var collision_shape := source_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var box_shape := collision_shape.shape as BoxShape3D if collision_shape != null else null
		if box_shape == null:
			return
		combiner = CSGCombiner3D.new()
		combiner.name = "RivalImpactHoles"
		combiner.use_collision = true
		combiner.collision_layer = source_body.collision_layer
		combiner.collision_mask = source_body.collision_mask
		combiner.transform = source_body.transform
		combiner.set_meta("race_hole_source", source_body)
		var base_box := CSGBox3D.new()
		base_box.name = "SurfaceBase"
		base_box.size = box_shape.size
		base_box.position = collision_shape.position
		var source_mesh := source_body.get_node_or_null("Mesh") as MeshInstance3D
		if source_mesh != null:
			base_box.material = source_mesh.material_override
		combiner.add_child(base_box)
		source_body.get_parent().add_child(combiner)
		source_body.visible = false
		collision_shape.disabled = true
		surface_replacements[surface_key] = {"combiner": combiner, "source": source_body}

	var subtractor := CSGSphere3D.new()
	subtractor.name = "BlackHole_%02d" % projectile_hole_count
	subtractor.operation = CSGShape3D.OPERATION_SUBTRACTION
	subtractor.radius = hole_radius
	subtractor.radial_segments = 16
	subtractor.rings = 8
	subtractor.position = source_body.to_local(hit_position)
	combiner.add_child(subtractor)

func _resolve_race_surface(surface: Object) -> StaticBody3D:
	if not surface is Node:
		return null
	var current := surface as Node
	while current != null:
		if current.has_meta("race_hole_source"):
			var source := current.get_meta("race_hole_source") as StaticBody3D
			if is_instance_valid(source):
				return source
		if current is StaticBody3D and current.name in ["Raceway", "LeftWall", "RightWall"]:
			return current as StaticBody3D
		current = current.get_parent()
	return null

func _create_hole_visual(hit_position: Vector3, surface_normal: Vector3, hole_radius: float) -> void:
	var marker := Node3D.new()
	marker.name = "ProjectileHoleMark"
	add_child(marker)
	marker.global_position = hit_position + surface_normal * 0.012
	marker.global_basis = Basis(Quaternion(Vector3.UP, surface_normal.normalized()))

	var center := MeshInstance3D.new()
	center.name = "DarkHoleCenter"
	var disk := CylinderMesh.new()
	disk.top_radius = hole_radius * 0.78
	disk.bottom_radius = hole_radius * 0.78
	disk.height = 0.035
	disk.radial_segments = 24
	center.mesh = disk
	center.position.y = -0.12
	center.material_override = _hole_material(Color(0.001, 0.001, 0.004), Color(0.006, 0.0, 0.018), 0.08)
	marker.add_child(center)

	var rim := MeshInstance3D.new()
	rim.name = "DarkHoleRim"
	var torus := TorusMesh.new()
	torus.inner_radius = hole_radius * 0.78
	torus.outer_radius = hole_radius * 0.91
	torus.rings = 24
	torus.ring_segments = 8
	rim.mesh = torus
	rim.position.y = 0.015
	rim.material_override = _hole_material(Color(0.025, 0.012, 0.045), Color(0.045, 0.005, 0.08), 0.3)
	marker.add_child(rim)
	hole_visuals.append(marker)

func _hole_material(color: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material

func _clear_rival_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("rival_black_projectiles"):
		projectile.queue_free()

func _clear_environment_holes() -> void:
	for replacement in surface_replacements.values():
		var source_body := replacement.get("source") as StaticBody3D
		var combiner := replacement.get("combiner") as CSGCombiner3D
		if is_instance_valid(source_body):
			source_body.visible = true
			var collision_shape := source_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if collision_shape != null:
				collision_shape.disabled = false
		if is_instance_valid(combiner):
			combiner.queue_free()
	for marker in hole_visuals:
		if is_instance_valid(marker):
			marker.queue_free()
	hole_visuals.clear()
	surface_replacements.clear()
	projectile_hole_count = 0

func _finish_position() -> float:
	return FINISH_Z

func _update_race_hud() -> void:
	var total_distance := START_Z - _finish_position()
	var player_progress := clampf((START_Z - player.global_position.z) / total_distance, 0.0, 1.0)
	var rival_progress := clampf((START_Z - rival.global_position.z) / total_distance, 0.0, 1.0)
	progress_label.text = "YOU  %3.0f%%     RIVAL  %3.0f%%" % [player_progress * 100.0, rival_progress * 100.0]
	player_status_label.text = "STATE  %s     SPEED  %.1f" % [player.state, Vector2(player.velocity.x, player.velocity.z).length()]

func _build_track() -> void:
	if has_node("CourseGeometry"):
		return
	var course := Node3D.new()
	course.name = "CourseGeometry"
	add_child(course)
	_assign_owner(course)
	var asphalt := _material(Color("272044"))
	var cyan := _material(Color("28e9ee"), 1.4)
	var pink := _material(Color("ff43bd"), 1.2)
	var gold := _material(Color("ffd05c"), 1.2)

	# A straight, continuous race lane with tall side walls and roomy running width.
	_add_solid(course, "Raceway", Vector3(0.0, -0.14, -92.0), Vector3(9.5, 0.28, TRACK_LENGTH), asphalt)
	_add_solid(course, "LeftWall", Vector3(-5.0, 2.25, -92.0), Vector3(0.5, 4.5, TRACK_LENGTH), cyan)
	_add_solid(course, "RightWall", Vector3(5.0, 2.25, -92.0), Vector3(0.5, 4.5, TRACK_LENGTH), pink)
	_add_decor(course, "LeftFloorStripe", Vector3(-4.55, 0.025, -92.0), Vector3(0.10, 0.035, TRACK_LENGTH - 0.5), cyan)
	_add_decor(course, "RightFloorStripe", Vector3(4.55, 0.025, -92.0), Vector3(0.10, 0.035, TRACK_LENGTH - 0.5), pink)
	for mark_index in range(20):
		var mark_z := 2.0 - float(mark_index) * 10.0
		_add_decor(course, "DistanceMark_%02d" % mark_index, Vector3(0.0, 0.012, mark_z), Vector3(0.12, 0.025, 2.2), cyan)

	_add_solid(course, "StartLine", Vector3(0.0, 0.025, START_Z), Vector3(9.1, 0.04, 0.65), gold)
	_add_gate(course, "StartGate", START_Z, gold)
	_add_solid(course, "FinishLine", Vector3(0.0, 0.026, FINISH_Z), Vector3(9.1, 0.045, 1.1), gold)
	_add_gate(course, "FinishGate", FINISH_Z, gold)
	_add_caption(course, "START", Vector3(0.0, 4.0, START_Z - 1.0), Color("ffe385"))
	_add_caption(course, "FINISH", Vector3(0.0, 4.0, FINISH_Z - 2.0), Color("ffe385"))

func _add_gate(parent: Node3D, prefix: String, z: float, material: Material) -> void:
	_add_decor(parent, prefix + "LeftPost", Vector3(-4.45, 2.05, z), Vector3(0.3, 4.1, 0.3), material)
	_add_decor(parent, prefix + "RightPost", Vector3(4.45, 2.05, z), Vector3(0.3, 4.1, 0.3), material)
	_add_decor(parent, prefix + "Header", Vector3(0.0, 4.0, z), Vector3(9.2, 0.3, 0.3), material)

func _add_solid(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	parent.add_child(body)
	_assign_owner(body)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	_assign_owner(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	_assign_owner(collision)

func _add_decor(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = position
	visual.mesh = mesh
	visual.material_override = material
	parent.add_child(visual)
	_assign_owner(visual)

func _add_caption(parent: Node3D, text: String, position: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = text + "Sign"
	label.text = text
	label.position = position
	label.font_size = 48
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 8
	label.outline_modulate = Color("171326")
	parent.add_child(label)
	_assign_owner(label)

func _assign_owner(node: Node) -> void:
	if not Engine.is_editor_hint():
		return
	var scene_root := get_tree().edited_scene_root
	if scene_root != null:
		node.owner = scene_root

func _material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.72
	if glow > 0.0:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = glow
	return result

func _build_lighting() -> void:
	var world := Environment.new()
	world.background_mode = Environment.BG_SKY
	world.sky = Sky.new()
	world.sky.sky_material = ProceduralSkyMaterial.new()
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("8074b8")
	world.ambient_light_energy = 0.6
	world.glow_enabled = true
	world.glow_intensity = 1.1
	world.glow_strength = 1.2
	world.glow_bloom = 0.1
	world.glow_hdr_threshold = 0.8
	var environment := WorldEnvironment.new()
	environment.environment = world
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 16.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "NEON RACE"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("62f4e1"))
	stack.add_child(title)
	progress_label = Label.new()
	progress_label.text = "YOU   0%     RIVAL   0%"
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color("ffe385"))
	stack.add_child(progress_label)
	player_status_label = Label.new()
	player_status_label.text = "STATE  IDLE     SPEED  0.0"
	player_status_label.add_theme_color_override("font_color", Color("ff83cb"))
	stack.add_child(player_status_label)
	var controls := Label.new()
	controls.text = "WASD run   Mouse camera   Space jump   Shift glide   Ctrl dive"
	controls.add_theme_font_size_override("font_size", 14)
	stack.add_child(controls)
	finish_label = Label.new()
	finish_label.text = "3"
	finish_label.set_anchors_preset(Control.PRESET_CENTER)
	finish_label.position = Vector2(-100.0, -90.0)
	finish_label.size = Vector2(200.0, 100.0)
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finish_label.add_theme_font_size_override("font_size", 72)
	finish_label.add_theme_color_override("font_color", Color("ffe385"))
	layer.add_child(finish_label)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.12, 0.88)
	style.border_color = Color("46e8df")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style
