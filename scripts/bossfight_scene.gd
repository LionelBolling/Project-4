@tool
extends Node3D

signal story_finished

const SEGMENT_LENGTH := 120.0
const SEGMENT_COUNT := 3
const START_Z := 8.0
const CHASE_SECONDS := 20.0
const QTE_SECONDS := 2.0
const SHADOW_WAIT_SECONDS := 20.0
const SHADOW_STOP_DISTANCE := 20.0
const APPROACH_DISTANCE := 8.0
const MIN_SHADOW_LEAD := 12.0
const MAX_SHADOW_LEAD := 20.0
const RESULTS_PAUSE := 3.0

@onready var player: MovementTestPlayer = $Player
@onready var rival: RaceOpponent = $Rival

var phase := "COUNTDOWN"
var countdown_timer := 3.0
var chase_timer := CHASE_SECONDS
var wait_timer := SHADOW_WAIT_SECONDS
var qte_timer := QTE_SECONDS
var qte_key := ""
var successful_hits := 0
var ram_timer := 0.0
var launch_timer := 0.0
var flight_timer := 0.0
var restart_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _segments: Array[Node3D] = []
var _segment_container: Node3D
var _surface_replacements: Dictionary = {}
var _hole_count := 0
var _ram_direction := Vector3.FORWARD
var _flight_velocity := Vector3.ZERO
var _player_checkpoint := Vector3.ZERO
var _launch_spin := 1.0
var _launch_bounce_count := 0
var _ram_target := Vector3.ZERO
var _camera: Camera3D
var _camera_target: Node3D
var _camera_tracks_midpoint := false
var _camera_cut := false
var _hud_phase: Label
var _hud_progress: Label
var _hud_action: Label
var _hud_hint: Label

func _ready() -> void:
	_rng.randomize()
	_ensure_corridor()
	if Engine.is_editor_hint():
		return
	_build_lighting()
	_build_hud()
	_build_boss_camera()
	player.status_label = _hud_hint
	player.set_physics_process(false)
	rival.set_rubberband_target(player)
	rival.set_physics_process(false)
	# Layer 2 is a shadow-only backup floor hidden beneath the breakable track.
	# The player's mask remains layer 1, so holes still work for the player.
	rival.collision_mask = 3
	rival.finish_z = -1000000000.0
	rival.run_speed = 9.0
	rival.rubberband_catchup_cap = 4.5
	rival.rubberband_lead_slowdown = 0.2
	rival.global_position = Vector3(1.4, 0.05, player.global_position.z - 10.0)
	rival.visual.rotation = Vector3(0.0, PI, 0.0)
	_player_checkpoint = player.global_position
	_player_checkpoint.y = 0.05
	_update_hud()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_stream_corridor()
	if player.is_on_floor() and absf(player.global_position.x) < 4.0:
		_player_checkpoint = player.global_position
		_player_checkpoint.y = 0.05
	if player.global_position.y < -12.0 and phase not in ["PLAYER_FLIGHT", "FAIL_RECOVERY", "WIN"]:
		phase = "FAIL_RECOVERY"
		restart_timer = 0.0
	if phase in ["CHASE", "WAIT_APPROACH"] and rival.touches_player_hazard(player.global_position + Vector3.UP * 0.9):
		player.play_hurt_animation()
	match phase:
		"COUNTDOWN":
			countdown_timer -= delta
			if countdown_timer <= 0.0:
				_begin_chase_cycle()
		"CHASE":
			if _is_player_chasing_shadow():
				chase_timer -= delta
			_maintain_shadow_lead()
			if chase_timer <= 0.0:
				_begin_wait_for_approach()
		"WAIT_APPROACH":
			wait_timer -= delta
			var lead := player.global_position.z - rival.global_position.z
			if lead <= APPROACH_DISTANCE and lead >= -1.5:
				_begin_qte()
			elif wait_timer <= 0.0:
				_begin_chase_cycle()
		"QTE":
			qte_timer -= delta
			if qte_timer <= 0.0:
				_begin_shadow_ram()
		"PLAYER_RAM", "ENEMY_LAUNCH":
			pass
		"ENEMY_RAM", "PLAYER_FLIGHT":
			pass
		"FAIL_RECOVERY":
			restart_timer -= delta
			if restart_timer <= 0.0:
				_recover_after_failure()
	_update_cut_camera(delta)
	_update_hud()

func _input(event: InputEvent) -> void:
	if phase != "QTE" or not event is InputEventKey or not event.pressed or event.echo:
		return
	var pressed := ""
	match event.keycode:
		KEY_Q: pressed = "Q"
		KEY_E: pressed = "E"
		KEY_R: pressed = "R"
		KEY_F: pressed = "F"
		_: return
	get_viewport().set_input_as_handled()
	if pressed == qte_key:
		_begin_player_ram()
	else:
		_begin_shadow_ram()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if phase == "CHASE":
		return
	if phase == "PLAYER_RAM":
		player.global_position = player.global_position.move_toward(_ram_target, 25.0 * delta)
		ram_timer -= delta
		if player.global_position.distance_to(_ram_target) <= 0.08 or ram_timer <= 0.0:
			player.global_position = _ram_target
			_begin_enemy_launch()
	elif phase == "ENEMY_LAUNCH":
		launch_timer -= delta
		rival.velocity.y -= 24.0 * delta
		rival.move_and_slide()
		rival.visual.rotation.x += delta * 7.0
		rival.visual.rotation.z += delta * 9.0 * _launch_spin
		if rival.is_on_floor() and rival.velocity.y <= 0.0:
			_launch_bounce_count += 1
			if _launch_bounce_count == 1:
				rival.velocity = Vector3(rival.velocity.x * 0.72, 9.0, rival.velocity.z * 0.72)
				rival.visual.call("play_animation", &"Launch", 0.06)
			else:
				_finish_enemy_launch()
		elif launch_timer <= 0.0:
			_finish_enemy_launch()
	elif phase == "ENEMY_RAM":
		rival.global_position += _ram_direction * 16.0 * delta
		ram_timer -= delta
		if ram_timer <= 0.0:
			_begin_player_flight()
	elif phase == "PLAYER_FLIGHT":
		flight_timer -= delta
		_flight_velocity.y -= 24.0 * delta
		player.global_position += _flight_velocity * delta
		player.visual.rotation.z += delta * 9.0 * signf(_flight_velocity.x)
		player.visual.rotation.x += delta * 4.0
		if flight_timer <= 0.0 or player.global_position.y < -10.0:
			phase = "FAIL_RECOVERY"
			restart_timer = 0.15

func _begin_chase_cycle() -> void:
	phase = "CHASE"
	chase_timer = CHASE_SECONDS
	player.set_physics_process(true)
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	rival.global_position = Vector3(clampf(player.global_position.x + side * 2.2, -2.8, 2.8), 0.05, player.global_position.z - SHADOW_STOP_DISTANCE)
	rival.velocity = Vector3.ZERO
	rival.visual.rotation = Vector3(0.0, PI, 0.0)
	rival.set_physics_process(true)
	rival.start_race()
	_set_player_camera()
	_hud_action.text = "CHASE THE SHADOW"

func _maintain_shadow_lead() -> void:
	var lead := player.global_position.z - rival.global_position.z
	if lead < MIN_SHADOW_LEAD:
		rival.global_position.z = player.global_position.z - MIN_SHADOW_LEAD
		if not rival.race_active:
			rival.set_physics_process(true)
			rival.start_race()
	elif lead > MAX_SHADOW_LEAD:
		if rival.race_active:
			rival.stop_race()
	else:
		if not rival.race_active:
			rival.set_physics_process(true)
			rival.start_race()

func _is_player_chasing_shadow() -> bool:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_vector.length_squared() < 0.04:
		return false
	var camera_forward := -player.camera_pivot.global_basis.z
	var camera_right := player.camera_pivot.global_basis.x
	var intended_direction := (camera_right * input_vector.x - camera_forward * input_vector.y).normalized()
	var toward_shadow := rival.global_position - player.global_position
	toward_shadow.y = 0.0
	if toward_shadow.length_squared() < 0.01:
		return false
	var direction := toward_shadow.normalized()
	var horizontal_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	return intended_direction.dot(direction) > 0.5 and horizontal_velocity.length() > 2.0 and horizontal_velocity.normalized().dot(direction) > 0.35

func _begin_wait_for_approach() -> void:
	phase = "WAIT_APPROACH"
	wait_timer = SHADOW_WAIT_SECONDS
	rival.stop_race()
	rival.set_physics_process(false)
	rival.global_position.z = player.global_position.z - SHADOW_STOP_DISTANCE
	_hud_action.text = "THE SHADOW IS WAITING"

func _begin_qte() -> void:
	phase = "QTE"
	qte_timer = QTE_SECONDS
	_player_checkpoint = player.global_position
	_player_checkpoint.y = 0.05
	var keys := ["Q", "E", "R", "F"]
	qte_key = keys[_rng.randi_range(0, keys.size() - 1)]
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.set_physics_process(false)
	_hud_action.text = "PRESS  " + qte_key
	_set_cut_camera(null, true)

func _begin_player_ram() -> void:
	if has_meta("story_round"): player.apply_story_qte(true)
	phase = "PLAYER_RAM"
	_clear_corridor_holes()
	ram_timer = 0.5
	var toward_shadow := rival.global_position - player.global_position
	toward_shadow.y = 0.0
	if toward_shadow.length() < 0.01:
		toward_shadow = Vector3.FORWARD
	var direction := toward_shadow.normalized()
	player.visual.rotation.y = atan2(direction.x, direction.z)
	_ram_target = rival.global_position - direction * 0.9
	_ram_target.y = player.global_position.y
	player.call("_set_animation", "dive")
	successful_hits += 1
	_hud_action.text = "HIT!  %d / 4" % successful_hits
	_set_cut_camera(rival, false)

func _begin_enemy_launch() -> void:
	phase = "ENEMY_LAUNCH"
	launch_timer = 3.2
	_launch_bounce_count = 0
	rival.stop_race()
	rival.set_physics_process(false)
	player.set_physics_process(false)
	rival.global_position.y = maxf(rival.global_position.y, 0.05)
	rival.velocity = Vector3(_rng.randf_range(-2.0, 2.0), 17.0, 28.0)
	_launch_spin = -1.0 if _rng.randf() < 0.5 else 1.0
	rival.visual.rotation = Vector3(0.0, PI, 0.0)
	rival.visual.call("play_animation", &"Launch", 0.08)
	var animation_player := rival.visual.get("animation_player") as AnimationPlayer
	if animation_player != null:
		animation_player.speed_scale = 1.0
	_set_cut_camera(rival, false)

func _finish_enemy_launch() -> void:
	rival.velocity = Vector3.ZERO
	rival.visual.rotation = Vector3(0.0, PI, 0.0)
	if successful_hits >= 4:
		phase = "WIN"
		_hud_action.text = "YOU WIN!"
		player.set_physics_process(false)
		rival.set_physics_process(false)
		if has_meta("story_round"):
			story_finished.emit()
		return
	_begin_chase_cycle()

func _begin_shadow_ram() -> void:
	if phase not in ["QTE", "WAIT_APPROACH"]:
		return
	if has_meta("story_round"): player.apply_story_qte(false)
	phase = "ENEMY_RAM"
	_clear_corridor_holes()
	ram_timer = 0.2
	_player_checkpoint = player.global_position
	_player_checkpoint.y = 0.05
	player.velocity = Vector3.ZERO
	player.call("play_hurt_animation")
	player.set_physics_process(false)
	var toward_player := player.global_position - rival.global_position
	toward_player.y = 0.0
	_ram_direction = toward_player.normalized() if toward_player.length() > 0.01 else Vector3.BACK
	_hud_action.text = "SHADOW RAM!"
	_set_cut_camera(player, false)

func _begin_player_flight() -> void:
	phase = "PLAYER_FLIGHT"
	flight_timer = 1.5
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	_flight_velocity = Vector3(side * 15.0, 11.0, -1.5)

func _recover_after_failure() -> void:
	_player_checkpoint = _find_safe_respawn_position(_player_checkpoint)
	player.spawn_position = _player_checkpoint
	player.global_position = _player_checkpoint
	player.velocity = Vector3.ZERO
	player.call("_respawn_at_start")
	player.set_physics_process(true)
	_begin_chase_cycle()

func _find_safe_respawn_position(preferred: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var x_candidates := [0.0, clampf(preferred.x, -3.4, 3.4), -2.4, 2.4]
	var z_offsets := [0.0, 3.0, -3.0, 6.0, -6.0, 10.0, -10.0, 14.0, -14.0]
	for z_offset in z_offsets:
		for x_value in x_candidates:
			var query := PhysicsRayQueryParameters3D.create(
				Vector3(x_value, preferred.y + 12.0, preferred.z + z_offset),
				Vector3(x_value, preferred.y - 18.0, preferred.z + z_offset)
			)
			query.collision_mask = 1
			var hit := space.intersect_ray(query)
			if not hit.is_empty() and Vector3(hit.normal).dot(Vector3.UP) > 0.75:
				var grounded_position: Vector3 = hit.position
				return Vector3(x_value, grounded_position.y + 0.06, preferred.z + z_offset)
	# Regenerate the floor segment under the fallback point if the corridor has
	# already streamed past this location or the available floor was holed out.
	var fallback := Vector3(0.0, 0.06, preferred.z)
	var segment_center := START_Z - 60.0 - floorf((START_Z - preferred.z) / SEGMENT_LENGTH) * SEGMENT_LENGTH
	var has_segment := false
	for segment in _segments:
		if absf(segment.position.z - segment_center) < 1.0:
			has_segment = true
			break
	if not has_segment:
		_create_corridor_segment(segment_center)
	return fallback

func _set_player_camera() -> void:
	_camera_cut = false
	_camera_tracks_midpoint = false
	_camera_target = null
	_camera.current = false
	player.camera.current = true

func _set_cut_camera(target: Node3D, midpoint: bool) -> void:
	_camera_cut = true
	_camera_target = target
	_camera_tracks_midpoint = midpoint
	player.camera.current = false
	_camera.current = true

func _update_cut_camera(delta: float) -> void:
	if not _camera_cut or _camera == null:
		return
	var focus := player.global_position + Vector3.UP * 1.1
	if _camera_tracks_midpoint:
		focus = (player.global_position + rival.global_position) * 0.5 + Vector3.UP * 1.15
	elif is_instance_valid(_camera_target):
		focus = _camera_target.global_position + Vector3.UP * 1.15
	var target_position := focus + Vector3(3.0, 1.8, -4.0)
	target_position.x = clampf(target_position.x, -4.15, 4.15)
	var smoothed_position := _camera.global_position.lerp(target_position, 1.0 - exp(-5.0 * delta))
	smoothed_position.x = clampf(smoothed_position.x, -4.2, 4.2)
	var camera_ray := PhysicsRayQueryParameters3D.create(focus, smoothed_position)
	camera_ray.collision_mask = 1
	camera_ray.exclude = [player.get_rid(), rival.get_rid()]
	var obstruction := get_world_3d().direct_space_state.intersect_ray(camera_ray)
	if not obstruction.is_empty():
		var ray_direction := (smoothed_position - focus).normalized()
		smoothed_position = obstruction.position - ray_direction * 0.3
	_camera.global_position = smoothed_position
	_camera.look_at(focus, Vector3.UP)

func _build_boss_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "BossEncounterCamera"
	_camera.fov = 62.0
	_camera.current = false
	add_child(_camera)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 16.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "SHADOW CHASE"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("62f4e1"))
	stack.add_child(title)
	_hud_phase = Label.new()
	_hud_phase.add_theme_color_override("font_color", Color("ffe385"))
	stack.add_child(_hud_phase)
	_hud_progress = Label.new()
	_hud_progress.add_theme_color_override("font_color", Color("ff83cb"))
	stack.add_child(_hud_progress)
	_hud_hint = Label.new()
	_hud_hint.text = "WASD run   Mouse camera   Space jump   Shift glide   Ctrl dive"
	_hud_hint.add_theme_font_size_override("font_size", 14)
	stack.add_child(_hud_hint)
	_hud_action = Label.new()
	_hud_action.set_anchors_preset(Control.PRESET_CENTER)
	_hud_action.position = Vector2(-260.0, -80.0)
	_hud_action.size = Vector2(520.0, 120.0)
	_hud_action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_action.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_action.add_theme_font_size_override("font_size", 50)
	_hud_action.add_theme_color_override("font_color", Color("ffe385"))
	layer.add_child(_hud_action)

func _update_hud() -> void:
	if _hud_phase == null:
		return
	match phase:
		"COUNTDOWN": _hud_phase.text = "CHASE BEGINS  %.1f" % countdown_timer
		"CHASE": _hud_phase.text = "CHASE  %.1f s" % maxf(chase_timer, 0.0)
		"WAIT_APPROACH": _hud_phase.text = "SHADOW WAITS  %.1f s" % maxf(wait_timer, 0.0)
		"QTE": _hud_phase.text = "QUICK TIME  %.1f s" % maxf(qte_timer, 0.0)
		"WIN": _hud_phase.text = "THE SHADOW IS DEFEATED"
		_: _hud_phase.text = phase.replace("_", " ")
	_hud_progress.text = "SHADOW HITS  %d / 4" % successful_hits
func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.12, 0.9)
	style.border_color = Color("46e8df")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style

func _build_lighting() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8074b8")
	environment.ambient_light_energy = 0.65
	environment.glow_enabled = true
	environment.glow_intensity = 1.1
	environment.glow_strength = 1.2
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _ensure_corridor() -> void:
	_segment_container = get_node_or_null("EndlessCorridor") as Node3D
	if _segment_container == null:
		_segment_container = Node3D.new()
		_segment_container.name = "EndlessCorridor"
		add_child(_segment_container)
		_set_owner_if_editing(_segment_container)
	for child in _segment_container.get_children():
		if child is Node3D:
			_segments.append(child as Node3D)
	if _segments.is_empty():
		for index in range(SEGMENT_COUNT):
			_create_corridor_segment(START_Z - SEGMENT_LENGTH * 0.5 - float(index) * SEGMENT_LENGTH)
	_segments.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.position.z < b.position.z)

func _create_corridor_segment(center_z: float) -> void:
	var segment := Node3D.new()
	segment.name = "BossCorridorSegment_%03d" % _segments.size()
	segment.position.z = center_z
	_segment_container.add_child(segment)
	_set_owner_if_editing(segment)
	var asphalt := _material(Color("272044"))
	var cyan := _material(Color("28e9ee"), 1.4)
	var pink := _material(Color("ff43bd"), 1.2)
	_add_solid(segment, "Raceway", Vector3(0.0, -0.14, 0.0), Vector3(9.5, 0.28, SEGMENT_LENGTH), asphalt)
	_add_shadow_safety_floor(segment)
	_add_solid(segment, "LeftWall", Vector3(-5.0, 2.25, 0.0), Vector3(0.5, 4.5, SEGMENT_LENGTH), cyan)
	_add_solid(segment, "RightWall", Vector3(5.0, 2.25, 0.0), Vector3(0.5, 4.5, SEGMENT_LENGTH), pink)
	_add_decor(segment, "LeftNeonStripe", Vector3(-4.55, 0.025, 0.0), Vector3(0.10, 0.035, SEGMENT_LENGTH - 0.5), cyan)
	_add_decor(segment, "RightNeonStripe", Vector3(4.55, 0.025, 0.0), Vector3(0.10, 0.035, SEGMENT_LENGTH - 0.5), pink)
	_segments.append(segment)

func _add_shadow_safety_floor(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "ShadowSafetyFloor"
	body.position = Vector3(0.0, -0.14, 0.0)
	body.collision_layer = 2
	body.collision_mask = 0
	parent.add_child(body)
	_set_owner_if_editing(body)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(9.5, 0.28, SEGMENT_LENGTH)
	collision.shape = shape
	body.add_child(collision)
	_set_owner_if_editing(collision)

func _stream_corridor() -> void:
	if _segments.is_empty():
		return
	var lead_z := minf(player.global_position.z, rival.global_position.z)
	var front_segment := _segments[0]
	for segment in _segments:
		if segment.position.z < front_segment.position.z:
			front_segment = segment
	if lead_z >= front_segment.position.z - SEGMENT_LENGTH * 0.5 + 38.0:
		return
	_create_corridor_segment(front_segment.position.z - SEGMENT_LENGTH)
	var rear_segment := _segments[0]
	for segment in _segments:
		if segment.position.z > rear_segment.position.z:
			rear_segment = segment
	_forget_segment_surfaces(rear_segment)
	_segments.erase(rear_segment)
	rear_segment.queue_free()

func _forget_segment_surfaces(segment: Node3D) -> void:
	var bodies := segment.find_children("*", "StaticBody3D", true, false)
	for body in bodies:
		_surface_replacements.erase(body.get_instance_id())

func _add_solid(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 1
	parent.add_child(body)
	_set_owner_if_editing(body)
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.material_override = material
	body.add_child(visual)
	_set_owner_if_editing(visual)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_set_owner_if_editing(collision)

func _add_decor(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = position
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.material_override = material
	parent.add_child(visual)
	_set_owner_if_editing(visual)

func _set_owner_if_editing(node: Node) -> void:
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

func _on_rival_projectile_surface_impact(hit_position: Vector3, surface_normal: Vector3, surface: Object, projectile_radius: float) -> void:
	_hole_count += 1
	var source_body := _resolve_surface_source(surface)
	if source_body != null:
		_add_csg_hole(source_body, hit_position, projectile_radius * 1.35)
	_create_hole_mark(source_body, hit_position, surface_normal, projectile_radius * 1.35)

func _clear_corridor_holes() -> void:
	# Clear projectiles already in flight so they cannot immediately punch new
	# holes after the QTE resolves.
	for projectile in get_tree().get_nodes_in_group("rival_black_projectiles"):
		if is_instance_valid(projectile):
			projectile.queue_free()
	for surface_id in _surface_replacements.keys():
		var data: Dictionary = _surface_replacements[surface_id]
		var source := data.get("source") as StaticBody3D
		var combiner := data.get("combiner") as CSGCombiner3D
		if is_instance_valid(source):
			source.visible = true
			var collision := source.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if collision != null:
				collision.disabled = false
		if is_instance_valid(combiner):
			combiner.queue_free()
	_surface_replacements.clear()
	for marker in find_children("ShadowHoleMark", "Node3D", true, false):
		marker.queue_free()

func _resolve_surface_source(surface: Object) -> StaticBody3D:
	if not surface is Node:
		return null
	var current := surface as Node
	while current != null:
		if current.has_meta("boss_hole_source"):
			var source := current.get_meta("boss_hole_source") as StaticBody3D
			if is_instance_valid(source):
				return source
		if current is StaticBody3D and current.name in ["Raceway", "LeftWall", "RightWall"]:
			return current as StaticBody3D
		current = current.get_parent()
	return null

func _add_csg_hole(source_body: StaticBody3D, hit_position: Vector3, hole_radius: float) -> void:
	var surface_id := source_body.get_instance_id()
	var data: Dictionary = _surface_replacements.get(surface_id, {})
	var combiner := data.get("combiner") as CSGCombiner3D
	if not is_instance_valid(combiner):
		var collision := source_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var box_shape := collision.shape as BoxShape3D if collision != null else null
		if box_shape == null:
			return
		combiner = CSGCombiner3D.new()
		combiner.name = "ShadowProjectileHoles"
		combiner.use_collision = true
		combiner.collision_layer = source_body.collision_layer
		combiner.collision_mask = source_body.collision_mask
		combiner.transform = source_body.transform
		combiner.set_meta("boss_hole_source", source_body)
		var base := CSGBox3D.new()
		base.name = "CorridorSurface"
		base.size = box_shape.size
		base.position = collision.position
		var mesh := source_body.get_node_or_null("Mesh") as MeshInstance3D
		if mesh != null:
			base.material = mesh.material_override
		combiner.add_child(base)
		source_body.get_parent().add_child(combiner)
		source_body.visible = false
		collision.disabled = true
		_surface_replacements[surface_id] = {"source": source_body, "combiner": combiner}
	var subtractor := CSGSphere3D.new()
	subtractor.name = "ShadowHole_%03d" % _hole_count
	subtractor.operation = CSGShape3D.OPERATION_SUBTRACTION
	subtractor.radius = hole_radius
	subtractor.radial_segments = 16
	subtractor.rings = 8
	subtractor.position = source_body.to_local(hit_position)
	combiner.add_child(subtractor)

func _create_hole_mark(source_body: StaticBody3D, hit_position: Vector3, surface_normal: Vector3, hole_radius: float) -> void:
	if source_body == null:
		return
	var marker := Node3D.new()
	marker.name = "ShadowHoleMark"
	source_body.get_parent().add_child(marker)
	marker.global_position = hit_position + surface_normal * 0.012
	marker.global_basis = Basis(Quaternion(Vector3.UP, surface_normal.normalized()))
	var disk := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = hole_radius * 0.78
	cylinder.bottom_radius = hole_radius * 0.78
	cylinder.height = 0.035
	disk.mesh = cylinder
	disk.position.y = -0.12
	disk.material_override = _dark_hole_material()
	marker.add_child(disk)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = hole_radius * 0.78
	torus.outer_radius = hole_radius * 0.92
	torus.rings = 24
	torus.ring_segments = 8
	rim.mesh = torus
	rim.position.y = 0.015
	rim.material_override = _dark_hole_material(true)
	marker.add_child(rim)

func _dark_hole_material(rim: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.008, 0.003, 0.018) if rim else Color(0.001, 0.001, 0.004)
	material.emission_enabled = rim
	if rim:
		material.emission = Color(0.045, 0.005, 0.08)
		material.emission_energy_multiplier = 0.3
	return material
