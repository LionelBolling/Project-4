extends Node3D

const QTE_SECONDS := 2.0
const QTE_RADIUS := 12.0
const QTE_TIME_SCALE := 0.35
const GOAL_LAUNCH_RANGE := 110.0
const RACE_COUNTDOWN_SECONDS := 3.0
const RACE_GO_LABEL_SECONDS := 0.7
const WIN_RESULTS_SECONDS := 3.0
const NEXT_SCENE := "res://scenes/level_3_beta.tscn"
const MAX_PROJECTILE_HOLES := 96

@onready var player: MovementTestPlayer = $Player
@onready var shadow: RaceOpponent = $Enemies/Shadow
@onready var finish_line: Node3D = $FinishLine

var active_targets: Array[MonsterQteTarget] = []
var current_target: MonsterQteTarget
var phase := "APPROACH"
var qte_timer := 0.0
var action_timer := 0.0
var post_hit_timer := 0.0
var _rush_direction := Vector3.FORWARD
var _rush_destination := Vector3.ZERO
var _qte_entry_momentum := Vector3.ZERO
var _normal_time_scale := 1.0
var _prompt: Label
var _scan_timer := 0.0
var _race_state := "COUNTDOWN"
var _race_countdown := RACE_COUNTDOWN_SECONDS
var _race_go_timer := 0.0
var _race_winner := ""
var _win_transition_timer := 0.0
var _player_progress_fill: ColorRect
var _shadow_progress_fill: ColorRect
var _player_progress_face: Panel
var _shadow_progress_face: Panel
var _projectile_hole_count := 0
var _surface_replacements: Dictionary = {}
const PROGRESS_TRACK_X := 82.0
const PROGRESS_TRACK_WIDTH := 278.0

func _ready() -> void:
	_normal_time_scale = Engine.time_scale
	_create_prompt()
	shadow.set_rubberband_target(player)
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	shadow.set_physics_process(false)
	_scan_targets()

func _exit_tree() -> void:
	Engine.time_scale = _normal_time_scale

func _process(delta: float) -> void:
	_update_race_progress()
	if _race_state == "COUNTDOWN":
		_race_countdown -= delta
		if _race_countdown <= 0.0:
			_start_level_race()
		_update_prompt()
		return
	if _race_state == "FINISHED":
		if _race_winner == "PLAYER":
			_win_transition_timer -= delta
			if _win_transition_timer <= 0.0:
				get_tree().change_scene_to_file(NEXT_SCENE)
				return
		_update_prompt()
		return
	if _race_go_timer > 0.0:
		_race_go_timer = maxf(0.0, _race_go_timer - delta)
	_check_shadow_hazards()
	if _check_race_finish():
		_update_prompt()
		return
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 0.4
		_scan_targets()
	match phase:
		"APPROACH":
			_try_begin_qte()
		"QTE":
			if _touching_target():
				_fail_qte()
				return
			qte_timer -= delta / maxf(Engine.time_scale, 0.001)
			if qte_timer <= 0.0:
				_fail_qte()
		"ENEMY_RUSH":
			_advance_enemy_rush(delta)
		"POST_HIT":
			post_hit_timer -= delta
			if post_hit_timer <= 0.0:
				phase = "APPROACH"
	_update_prompt()

func _check_shadow_hazards() -> void:
	# The shadow's black trails are visual meshes, so test their ribbon paths
	# directly instead of relying on a physics collider.
	var player_center := player.global_position + Vector3.UP * 0.9
	if shadow.touches_player_hazard(player_center):
		player.play_hurt_animation()

	# Keep the projectile damage check here as well as in the projectile script
	# so the Level 1 scene consistently treats the shadow balls as hazards.
	for node in get_tree().get_nodes_in_group("rival_black_projectiles"):
		if not is_instance_valid(node) or not node is RivalBlackProjectile:
			continue
		var projectile := node as RivalBlackProjectile
		var hit_radius := projectile.player_touch_radius + projectile.projectile_radius * 0.35
		if projectile.global_position.distance_to(player_center) <= hit_radius:
			player.play_hurt_animation()
			projectile.queue_free()

func _on_rival_projectile_surface_impact(hit_position: Vector3, surface_normal: Vector3, surface: Object, projectile_radius: float) -> void:
	_projectile_hole_count += 1
	var source_body := _resolve_projectile_surface(surface)
	if source_body == null:
		return
	var hole_radius := maxf(projectile_radius * 1.35, 0.72)
	_create_projectile_hole_mark(source_body, hit_position, surface_normal, hole_radius)
	if _projectile_hole_count <= MAX_PROJECTILE_HOLES:
		_add_projectile_hole(source_body, hit_position, hole_radius)

func _resolve_projectile_surface(surface: Object) -> StaticBody3D:
	if not surface is Node:
		return null
	var current := surface as Node
	while current != null:
		if current.has_meta("level_1_hole_source"):
			var source := current.get_meta("level_1_hole_source") as StaticBody3D
			if is_instance_valid(source):
				return source
		if current is StaticBody3D:
			var collision := current.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if collision != null and collision.shape is BoxShape3D:
				return current as StaticBody3D
		current = current.get_parent()
	return null

func _add_projectile_hole(source_body: StaticBody3D, hit_position: Vector3, hole_radius: float) -> void:
	var source_id := source_body.get_instance_id()
	var replacement: Dictionary = _surface_replacements.get(source_id, {})
	var combiner := replacement.get("combiner") as CSGCombiner3D
	if not is_instance_valid(combiner):
		var collision := source_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var box_shape := collision.shape as BoxShape3D if collision != null else null
		if box_shape == null:
			return
		combiner = CSGCombiner3D.new()
		combiner.name = "ShadowProjectileHoles"
		combiner.use_collision = true
		combiner.visible = false
		combiner.collision_layer = source_body.collision_layer
		combiner.collision_mask = source_body.collision_mask
		combiner.transform = source_body.transform
		combiner.set_meta("level_1_hole_source", source_body)
		var source_mesh := source_body.get_node_or_null("Mesh") as MeshInstance3D
		var base: CSGShape3D
		if source_mesh != null and source_mesh.mesh != null:
			var mesh_base := CSGMesh3D.new()
			mesh_base.name = "StageSurface"
			mesh_base.mesh = source_mesh.mesh
			mesh_base.transform = source_mesh.transform
			if source_mesh.material_override != null:
				mesh_base.material = source_mesh.material_override
			base = mesh_base
		else:
			var box_base := CSGBox3D.new()
			box_base.name = "StageSurface"
			box_base.size = box_shape.size
			box_base.position = collision.position
			base = box_base
		combiner.add_child(base)
		source_body.get_parent().add_child(combiner)
		# Keep the authored platform mesh visible. The hidden CSG replacement
		# supplies the cut collision while the dark mark shows the opening.
		collision.disabled = true
		_surface_replacements[source_id] = {"source": source_body, "combiner": combiner}
	var subtractor := CSGSphere3D.new()
	subtractor.name = "BlackHole_%03d" % _projectile_hole_count
	subtractor.operation = CSGShape3D.OPERATION_SUBTRACTION
	subtractor.radius = hole_radius
	subtractor.radial_segments = 20
	subtractor.rings = 10
	subtractor.position = source_body.to_local(hit_position)
	combiner.add_child(subtractor)

func _create_projectile_hole_mark(source_body: StaticBody3D, hit_position: Vector3, surface_normal: Vector3, hole_radius: float) -> void:
	var marker := Node3D.new()
	marker.name = "ShadowProjectileHoleMark"
	source_body.get_parent().add_child(marker)
	marker.global_position = hit_position + surface_normal * 0.035
	marker.global_basis = Basis(Quaternion(Vector3.UP, surface_normal.normalized()))
	var center := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = hole_radius * 0.78
	disk.bottom_radius = hole_radius * 0.78
	disk.height = 0.035
	disk.radial_segments = 24
	center.mesh = disk
	center.position.y = 0.01
	center.material_override = _projectile_hole_material(Color(0.001, 0.001, 0.004), Color(0.006, 0.0, 0.018), 0.08)
	marker.add_child(center)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = hole_radius * 0.78
	torus.outer_radius = hole_radius * 0.92
	torus.rings = 24
	torus.ring_segments = 8
	rim.mesh = torus
	rim.position.y = 0.015
	rim.material_override = _projectile_hole_material(Color(0.025, 0.012, 0.045), Color(0.045, 0.005, 0.08), 0.3)
	marker.add_child(rim)

func _projectile_hole_material(color: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material

func _start_level_race() -> void:
	_race_state = "RACING"
	_race_go_timer = RACE_GO_LABEL_SECONDS
	player.set_physics_process(true)
	shadow.set_physics_process(true)
	shadow.start_race()

func _check_race_finish() -> bool:
	var player_finished := _crossed_yellow_finish(player)
	var shadow_finished := _crossed_yellow_finish(shadow)
	if not player_finished and not shadow_finished:
		return false
	if player_finished and shadow_finished:
		_race_winner = "PLAYER" if player.global_position.z <= shadow.global_position.z else "SHADOW"
	else:
		_race_winner = "PLAYER" if player_finished else "SHADOW"
	_race_state = "FINISHED"
	_win_transition_timer = WIN_RESULTS_SECONDS if _race_winner == "PLAYER" else 0.0
	Engine.time_scale = _normal_time_scale
	player.set_physics_process(false)
	shadow.stop_race()
	shadow.set_physics_process(false)
	return true

func _crossed_yellow_finish(racer: Node3D) -> bool:
	var finish_z := finish_line.global_position.z
	if racer.global_position.z > finish_z or absf(racer.global_position.x - finish_line.global_position.x) > 9.5:
		return false
	var gate_bottom := finish_line.global_position.y
	var gate_top := gate_bottom + 6.2
	var racer_bottom := racer.global_position.y
	var racer_top := racer_bottom + 1.8
	return racer_top >= gate_bottom and racer_bottom <= gate_top

func _physics_process(delta: float) -> void:
	if phase != "PLAYER_RUSH" or not is_instance_valid(current_target):
		return
	player.global_position = player.global_position.move_toward(_rush_destination, 28.0 * delta)
	action_timer -= delta
	if player.global_position.distance_to(_rush_destination) <= 0.08 or action_timer <= 0.0:
		player.global_position = _rush_destination
		_finish_player_rush()

func _input(event: InputEvent) -> void:
	if phase != "QTE" or not event is InputEventKey or not event.pressed or event.echo:
		return
	var pressed := ""
	match event.keycode:
		KEY_Q: pressed = "Q"
		KEY_E: pressed = "E"
		KEY_R: pressed = "R"
		_: return
	get_viewport().set_input_as_handled()
	if pressed == current_target.required_key:
		_begin_player_rush()
	else:
		_fail_qte()

func _scan_targets() -> void:
	for node in find_children("*", "CharacterBody3D", true, false):
		var target := node as MonsterQteTarget
		if target == null or _inside_piece_library(target) or active_targets.has(target):
			continue
		active_targets.append(target)
		if not target.disappeared.is_connected(_on_monster_disappeared):
			target.disappeared.connect(_on_monster_disappeared)

func _inside_piece_library(target: Node) -> bool:
	var ancestor := target.get_parent()
	var in_library := false
	var in_enemy_tray := false
	while ancestor != null and ancestor != self:
		if ancestor.name == "Pieces_To_Copy":
			in_library = true
		if ancestor.name == "Enemy_Pieces":
			in_enemy_tray = true
		ancestor = ancestor.get_parent()
	if not in_library:
		return false
	if not in_enemy_tray:
		return true
	var original_position := Vector3.ZERO
	match target.name:
		"Copy_DiscoBall": original_position = Vector3(0.0, 0.05, 0.0)
		"Copy_Speaker": original_position = Vector3(8.0, 0.05, 0.0)
		"Copy_Microphone": original_position = Vector3(16.0, 0.05, 0.0)
		_: return false
	return target.position.is_equal_approx(original_position)

func _try_begin_qte() -> void:
	var horizontal_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal_velocity.length() < 2.0:
		return
	var nearest: MonsterQteTarget
	var nearest_gap := QTE_RADIUS
	for target in active_targets:
		if not is_instance_valid(target) or target.defeated or target.skipped:
			continue
		var gap := target.global_position - player.global_position
		gap.y = 0.0
		var distance := gap.length()
		if distance >= nearest_gap or distance < 0.001:
			continue
		nearest = target
		nearest_gap = distance
	if nearest == null:
		return
	current_target = nearest
	phase = "QTE"
	qte_timer = QTE_SECONDS
	_qte_entry_momentum = Vector3(player.velocity.x, 0.0, player.velocity.z)
	Engine.time_scale = _normal_time_scale * QTE_TIME_SCALE

func _begin_player_rush() -> void:
	if not is_instance_valid(current_target):
		phase = "APPROACH"
		Engine.time_scale = _normal_time_scale
		return
	Engine.time_scale = _normal_time_scale
	phase = "PLAYER_RUSH"
	action_timer = 0.55
	var toward := current_target.global_position - player.global_position
	toward.y = 0.0
	_rush_direction = toward.normalized() if toward.length_squared() > 0.001 else Vector3.FORWARD
	_rush_destination = current_target.global_position - _rush_direction
	_rush_destination.y = player.global_position.y
	player.set_physics_process(false)
	player.visual.rotation.y = atan2(_rush_direction.x, _rush_direction.z)
	player.call("_set_animation", "dive")

func _finish_player_rush() -> void:
	if not is_instance_valid(current_target):
		player.set_physics_process(true)
		phase = "APPROACH"
		return
	var enemy_launch_direction := _rush_direction
	var player_bounce_direction := _rush_direction
	var finish := get_node_or_null("Platforms/Platform_Finish") as Node3D
	if finish != null:
		var to_goal := finish.global_position - current_target.global_position
		to_goal.y = 0.0
		if to_goal.length_squared() > 0.001:
			player_bounce_direction = to_goal.normalized()
		if to_goal.length() <= GOAL_LAUNCH_RANGE and to_goal.length_squared() > 0.001:
			enemy_launch_direction = to_goal.normalized()
		var next_target := _get_next_route_target(current_target, finish)
		if next_target != null:
			var to_next := next_target.global_position - current_target.global_position
			to_next.y = 0.0
			if to_next.length_squared() > 0.001:
				player_bounce_direction = to_next.normalized()
	current_target.launch_from_hit(enemy_launch_direction)
	player.call("launch_from_monster_bounce", player_bounce_direction, 22.0, 26.0)
	player.set_physics_process(true)
	current_target = null
	phase = "POST_HIT"
	post_hit_timer = 0.4

func _get_next_route_target(from_target: MonsterQteTarget, finish: Node3D) -> MonsterQteTarget:
	if finish == null:
		return null
	var current_goal_distance := Vector2(
		finish.global_position.x - from_target.global_position.x,
		finish.global_position.z - from_target.global_position.z
	).length()
	var best_target: MonsterQteTarget
	var best_distance := INF
	for target in active_targets:
		if not is_instance_valid(target) or target == from_target or target.defeated or target.skipped:
			continue
		var goal_distance := Vector2(
			finish.global_position.x - target.global_position.x,
			finish.global_position.z - target.global_position.z
		).length()
		if goal_distance >= current_goal_distance:
			continue
		var distance := from_target.global_position.distance_squared_to(target.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = target
	return best_target

func _fail_qte() -> void:
	Engine.time_scale = _normal_time_scale
	if not is_instance_valid(current_target) or not _within_qte_radius():
		current_target = null
		phase = "APPROACH"
		return
	phase = "ENEMY_RUSH"
	action_timer = 0.9
	if current_target.visual.has_method("play_hurt"):
		current_target.visual.call("play_hurt", 0.06)

func _advance_enemy_rush(delta: float) -> void:
	if not is_instance_valid(current_target):
		phase = "APPROACH"
		return
	var player_aim := player.global_position + Vector3.UP * 0.6
	var toward_player := player_aim - current_target.global_position
	var direction := toward_player.normalized() if toward_player.length_squared() > 0.001 else Vector3.BACK
	current_target.global_position = current_target.global_position.move_toward(player_aim, 23.0 * delta)
	action_timer -= delta
	var horizontal_gap := Vector2(
		current_target.global_position.x - player.global_position.x,
		current_target.global_position.z - player.global_position.z
	).length()
	if horizontal_gap > 2.0 and action_timer > 0.0:
		return
	current_target.launch_from_failed_qte(-direction)
	var bump := direction * 4.5 + _qte_entry_momentum * 0.12
	player.velocity = Vector3(bump.x, 7.0, bump.z)
	player.state = "JUMPING"
	player.jump_pending = false
	player.jump_buffer = 0.0
	player.jump_start_timer = 0.0
	player.coyote_timer = 0.0
	player.air_time = 0.0
	player.was_airborne = true
	player.visual.rotation.x = 0.0
	player.call("play_hurt_animation")
	current_target = null
	phase = "POST_HIT"
	post_hit_timer = 0.45

func _within_qte_radius() -> bool:
	var gap := current_target.global_position - player.global_position
	gap.y = 0.0
	return gap.length() <= QTE_RADIUS

func _touching_target() -> bool:
	var gap := current_target.global_position - player.global_position
	gap.y = 0.0
	return gap.length() <= 1.6

func _create_prompt() -> void:
	var layer := CanvasLayer.new()
	layer.name = "EnemyQTEHUD"
	add_child(layer)
	_create_progress_hud(layer)
	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_prompt.position = Vector2(-360.0, 78.0)
	_prompt.size = Vector2(720.0, 96.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 64)
	_prompt.add_theme_color_override("font_color", Color("fff0a8"))
	_prompt.add_theme_color_override("font_outline_color", Color("ff42cf"))
	_prompt.add_theme_constant_override("outline_size", 7)
	_prompt.add_theme_color_override("font_shadow_color", Color(0.02, 0.78, 1.0, 0.9))
	_prompt.add_theme_constant_override("shadow_offset_x", 0)
	_prompt.add_theme_constant_override("shadow_offset_y", 4)
	layer.add_child(_prompt)
	_update_prompt()

func _create_progress_hud(layer: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.name = "RaceProgressPanel"
	panel.position = Vector2(20.0, 20.0)
	panel.size = Vector2(430.0, 112.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.018, 0.075, 0.88)
	panel_style.border_color = Color(0.05, 0.78, 1.0, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(panel)

	var content := Control.new()
	content.custom_minimum_size = Vector2(430.0, 112.0)
	content.size = Vector2(430.0, 112.0)
	panel.add_child(content)
	var title := Label.new()
	title.position = Vector2(12.0, 1.0)
	title.size = Vector2(260.0, 22.0)
	title.text = "RACE TO THE FINISH"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("8dfaff"))
	title.add_theme_color_override("font_outline_color", Color("123a75"))
	title.add_theme_constant_override("outline_size", 2)
	content.add_child(title)

	var player_lane := _create_progress_lane(content, "YOU", 27.0, Color("ff43cf"), "res://runner/runner.tscn")
	_player_progress_fill = player_lane.get("fill") as ColorRect
	_player_progress_face = player_lane.get("face") as Panel
	var shadow_lane := _create_progress_lane(content, "SHADOW", 65.0, Color("21c8ff"), "res://enemy_runner/enemy_runner.tscn")
	_shadow_progress_fill = shadow_lane.get("fill") as ColorRect
	_shadow_progress_face = shadow_lane.get("face") as Panel

func _create_progress_lane(parent: Control, lane_name: String, y: float, tint: Color, scene_path: String) -> Dictionary:
	var lane_label := Label.new()
	lane_label.position = Vector2(12.0, y + 5.0)
	lane_label.size = Vector2(62.0, 23.0)
	lane_label.text = lane_name
	lane_label.add_theme_font_size_override("font_size", 13)
	lane_label.add_theme_color_override("font_color", tint)
	lane_label.add_theme_color_override("font_outline_color", Color(0.015, 0.015, 0.04, 1.0))
	lane_label.add_theme_constant_override("outline_size", 2)
	parent.add_child(lane_label)

	var track := ColorRect.new()
	track.position = Vector2(PROGRESS_TRACK_X, y + 13.0)
	track.size = Vector2(PROGRESS_TRACK_WIDTH, 7.0)
	track.color = Color(0.18, 0.16, 0.27, 0.95)
	parent.add_child(track)
	var fill := ColorRect.new()
	fill.size = Vector2(0.0, 7.0)
	fill.color = tint
	track.add_child(fill)

	var marker_back := Panel.new()
	marker_back.position = Vector2(PROGRESS_TRACK_X - 15.0, y + 1.0)
	marker_back.size = Vector2(30.0, 30.0)
	var marker_style := StyleBoxFlat.new()
	marker_style.bg_color = Color(0.035, 0.025, 0.09, 1.0)
	marker_style.border_color = tint
	marker_style.set_border_width_all(2)
	marker_style.set_corner_radius_all(15)
	marker_back.clip_contents = true
	marker_back.add_theme_stylebox_override("panel", marker_style)
	parent.add_child(marker_back)
	var face := TextureRect.new()
	face.name = lane_name + "Face"
	face.position = Vector2(1.0, 1.0)
	face.size = Vector2(28.0, 28.0)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture = _create_character_face_texture(scene_path)
	marker_back.add_child(face)

	var finish_label := Label.new()
	finish_label.position = Vector2(PROGRESS_TRACK_X + PROGRESS_TRACK_WIDTH + 5.0, y + 5.0)
	finish_label.size = Vector2(52.0, 22.0)
	finish_label.text = "FINISH"
	finish_label.add_theme_font_size_override("font_size", 10)
	finish_label.add_theme_color_override("font_color", Color("ffe88c"))
	parent.add_child(finish_label)
	return {"fill": fill, "face": marker_back}

func _create_character_face_texture(scene_path: String) -> Texture2D:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	var viewport := SubViewport.new()
	viewport.size = Vector2i(96, 96)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var portrait_root := Node3D.new()
	viewport.add_child(portrait_root)
	var portrait := packed.instantiate() as Node3D
	if portrait == null:
		viewport.queue_free()
		return null
	portrait_root.add_child(portrait)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.52, 1.65)
	camera.fov = 34.0
	portrait_root.add_child(camera)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-15.0, 25.0, 0.0)
	light.light_energy = 1.8
	portrait_root.add_child(light)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.72, 0.88)
	environment.ambient_light_energy = 0.8
	environment_node.environment = environment
	portrait_root.add_child(environment_node)
	# Keep the viewport owned by the HUD for its full lifetime.
	get_node("EnemyQTEHUD").add_child(viewport)
	return viewport.get_texture()

func _update_race_progress() -> void:
	if _player_progress_fill == null or _shadow_progress_fill == null:
		return
	var start_z := player.global_position.z if _race_state == "COUNTDOWN" else 8.0
	var finish_z := finish_line.global_position.z
	var total_distance := maxf(start_z - finish_z, 0.01)
	var player_progress := clampf((start_z - player.global_position.z) / total_distance, 0.0, 1.0)
	var shadow_progress := clampf((start_z - shadow.global_position.z) / total_distance, 0.0, 1.0)
	_player_progress_fill.size.x = PROGRESS_TRACK_WIDTH * player_progress
	_shadow_progress_fill.size.x = PROGRESS_TRACK_WIDTH * shadow_progress
	_player_progress_face.position.x = PROGRESS_TRACK_X + PROGRESS_TRACK_WIDTH * player_progress - 15.0
	_shadow_progress_face.position.x = PROGRESS_TRACK_X + PROGRESS_TRACK_WIDTH * shadow_progress - 15.0

func _update_prompt() -> void:
	if _prompt == null:
		return
	_prompt.visible = true
	if _race_state == "COUNTDOWN":
		_prompt.text = str(maxi(1, ceili(_race_countdown)))
		_set_prompt_style(82, Color("fff07d"), Color("ff42cf"))
	elif _race_state == "FINISHED":
		_prompt.text = "WIN" if _race_winner == "PLAYER" else "LOSE"
		_set_prompt_style(68, Color("ff5be5") if _race_winner == "PLAYER" else Color("62e8ff"), Color("ff42cf") if _race_winner == "PLAYER" else Color("159bff"))
	elif _race_go_timer > 0.0:
		_prompt.text = "Start!"
		_set_prompt_style(76, Color("7ffff0"), Color("20aaff"))
	elif phase == "QTE" and is_instance_valid(current_target):
		_prompt.text = "PRESS  %s" % current_target.required_key
		_set_prompt_style(40, Color("fff0a8"), Color("ff42cf"))
	elif phase == "PLAYER_RUSH":
		_prompt.text = "GO!"
		_set_prompt_style(48, Color("7ffff0"), Color("20aaff"))
	elif phase == "ENEMY_RUSH":
		_prompt.text = "WRONG KEY — WATCH OUT!"
		_set_prompt_style(36, Color("ff74d8"), Color("b8008c"))
	else:
		_prompt.text = ""
		_prompt.visible = false

func _set_prompt_style(font_size: int, font_color: Color, outline_color: Color) -> void:
	_prompt.add_theme_font_size_override("font_size", font_size)
	_prompt.add_theme_color_override("font_color", font_color)
	_prompt.add_theme_color_override("font_outline_color", outline_color)

func _ready_enemy_count() -> int:
	var count := 0
	for target in active_targets:
		if is_instance_valid(target) and not target.defeated and not target.skipped:
			count += 1
	return count

func _on_monster_disappeared(world_position: Vector3) -> void:
	_spawn_smoke(world_position + Vector3.UP * 1.25, Color(0.08, 0.74, 1.0, 0.78))
	_spawn_smoke(world_position + Vector3.UP * 1.25 + Vector3.RIGHT * 0.35, Color(1.0, 0.06, 0.58, 0.78))

func _spawn_smoke(world_position: Vector3, tint: Color) -> void:
	var burst := GPUParticles3D.new()
	burst.one_shot = true
	burst.amount = 20
	burst.lifetime = 0.9
	burst.explosiveness = 0.9
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.18
	particle_mesh.height = 0.36
	burst.draw_pass_1 = particle_mesh
	var particle := ParticleProcessMaterial.new()
	particle.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle.emission_sphere_radius = 0.25
	particle.direction = Vector3.UP
	particle.spread = 180.0
	particle.initial_velocity_min = 1.0
	particle.initial_velocity_max = 3.0
	particle.gravity = Vector3(0.0, 1.0, 0.0)
	particle.color = tint
	burst.process_material = particle
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = tint
	glow.emission_enabled = true
	glow.emission = Color(tint.r, tint.g, tint.b)
	glow.emission_energy_multiplier = 0.8
	burst.material_override = glow
	add_child(burst)
	burst.global_position = world_position
	burst.finished.connect(burst.queue_free)
	burst.emitting = true
