extends Node3D

const QTE_SECONDS := 2.0
const APPROACH_DISTANCE := 8.5
const QTE_TIME_SCALE := 0.35
const MAX_PROJECTILE_HOLES := 96
const RACE_START_Z := 8.0
const RACE_FINISH_Z := -332.0
const RACE_COUNTDOWN_SECONDS := 3.0
const RACE_GO_LABEL_SECONDS := 0.7
const WIN_RESULTS_SECONDS := 3.0
const NEXT_SCENE := "res://scenes/bossfight.tscn"
const PROGRESS_TRACK_X := 82.0
const PROGRESS_TRACK_WIDTH := 278.0

@onready var player: MovementTestPlayer = $Player
@onready var shadow: RaceOpponent = $Enemies/Shadow
@onready var monsters: Array[MonsterQteTarget] = [
	$DiscoBall,
	$Speaker,
	$Microphone,
	$DiscoBall2,
	$Speaker2,
	$Microphone2,
	$DiscoBall3,
	$DiscoBall4,
	$DiscoBall5
]

var phase := "APPROACH"
var current_target: MonsterQteTarget
var qte_timer := 0.0
var rush_timer := 0.0
var monster_rush_timer := 0.0
var post_hit_timer := 0.0
var _rush_direction := Vector3.FORWARD
var _monster_rush_direction := Vector3.FORWARD
var _rush_target_position := Vector3.ZERO
var _qte_entry_momentum := Vector3.ZERO
var _normal_time_scale := 1.0
var _safe_spawn := Vector3.ZERO
var _hud_prompt: Label
var finish_label: Label
var player_progress_fill: ColorRect
var shadow_progress_fill: ColorRect
var player_progress_face: Panel
var shadow_progress_face: Panel
var race_state := "COUNTDOWN"
var race_countdown := RACE_COUNTDOWN_SECONDS
var race_go_timer := 0.0
var win_transition_timer := 0.0
var player_won_race := false
var _qte_success_effects: Array[Dictionary] = []
var _projectile_hole_count := 0
var _surface_replacements: Dictionary = {}

func _ready() -> void:
	_normal_time_scale = Engine.time_scale
	_safe_spawn = player.global_position
	shadow.set_rubberband_target(player)
	shadow.finish_z = RACE_FINISH_Z
	shadow.run_animation_speed_multiplier = player.run_animation_speed_multiplier
	shadow.wall_run_animation_speed_multiplier = player.wall_run_animation_speed
	shadow.wall_jump_animation_speed_multiplier = player.wall_jump_animation_speed
	shadow.dive_land_animation_speed_multiplier = player.dive_land_animation_speed
	player.set_physics_process(false)
	shadow.set_physics_process(false)
	for monster in monsters:
		monster.disappeared.connect(_on_monster_disappeared)
	_build_speed_markers()
	_build_hud()
	player.status_label = null
	_update_race_hud()
	_update_hud()

func _exit_tree() -> void:
	Engine.time_scale = _normal_time_scale
	if is_instance_valid(shadow):
		shadow.stop_race()

func _process(delta: float) -> void:
	_update_qte_success_effects(delta)
	if race_state == "COUNTDOWN":
		race_countdown -= delta
		if race_countdown > 0.0:
			finish_label.text = str(maxi(1, ceili(race_countdown)))
			_style_race_announcement(82, Color("fff07d"), Color("ff42cf"))
		else:
			_start_race()
		_update_race_hud()
		_update_hud()
		return
	if race_state == "FINISHED":
		_update_race_hud()
		_update_hud()
		if player_won_race:
			win_transition_timer -= delta
			if win_transition_timer <= 0.0:
				get_tree().change_scene_to_file(NEXT_SCENE)
		return
	if race_go_timer > 0.0:
		race_go_timer = maxf(0.0, race_go_timer - delta)
		if race_go_timer <= 0.0:
			finish_label.visible = false
	_update_race_hud()
	_check_shadow_hazards()
	if player.is_on_floor() and absf(player.global_position.x) < 6.5:
		_safe_spawn = player.global_position
		_safe_spawn.y = 0.05
	if player.global_position.y < -12.0:
		Engine.time_scale = _normal_time_scale
		_respawn_player()
		return
	if player.global_position.z <= RACE_FINISH_Z and player.velocity.z < 0.0:
		_finish_race(true)
		_update_hud()
		return
	if shadow.global_position.z <= RACE_FINISH_Z:
		_finish_race(false)
		_update_hud()
		return
	if phase == "QTE" and _player_touches_current_target():
		_fail_qte("TOUCHED THE MONSTER — COUNTERATTACK!")
		_update_hud()
		return
	match phase:
		"APPROACH":
			_reactivate_skipped_target_if_approaching()
			current_target = _next_target()
			if current_target == null:
				phase = "CLEAR"
			else:
				_check_approach()
		"QTE":
			qte_timer -= delta / maxf(Engine.time_scale, 0.001)
			if qte_timer <= 0.0:
				_fail_qte("TOO SLOW — BACK OFF TO RETRY")
		"POST_HIT":
			post_hit_timer -= delta
			if post_hit_timer <= 0.0:
				phase = "APPROACH"
	_update_hud()

func _start_race() -> void:
	race_state = "RACING"
	race_go_timer = RACE_GO_LABEL_SECONDS
	finish_label.text = "Start!"
	finish_label.visible = true
	_style_race_announcement(76, Color("7ffff0"), Color("20aaff"))
	player.jump_buffer = 0.0
	player.set_physics_process(true)
	shadow.start_race()
	shadow.set_physics_process(true)

func _finish_race(player_won: bool) -> void:
	race_state = "FINISHED"
	player_won_race = player_won
	win_transition_timer = WIN_RESULTS_SECONDS if player_won else 0.0
	Engine.time_scale = _normal_time_scale
	player.set_physics_process(false)
	shadow.stop_race()
	shadow.set_physics_process(false)
	for projectile in get_tree().get_nodes_in_group("rival_black_projectiles"):
		if is_instance_valid(projectile):
			projectile.queue_free()
	player.call("_set_animation", "Idle")
	finish_label.text = "WIN" if player_won else "LOSE"
	finish_label.visible = true
	_style_race_announcement(68, Color("ff5be5") if player_won else Color("62e8ff"), Color("ff42cf") if player_won else Color("159bff"))

func _update_race_hud() -> void:
	if player_progress_fill == null or shadow_progress_fill == null:
		return
	var total_distance := RACE_START_Z - RACE_FINISH_Z
	var player_progress := clampf((RACE_START_Z - player.global_position.z) / total_distance, 0.0, 1.0)
	var shadow_progress := clampf((RACE_START_Z - shadow.global_position.z) / total_distance, 0.0, 1.0)
	player_progress_fill.size.x = PROGRESS_TRACK_WIDTH * player_progress
	shadow_progress_fill.size.x = PROGRESS_TRACK_WIDTH * shadow_progress
	player_progress_face.position.x = PROGRESS_TRACK_X + PROGRESS_TRACK_WIDTH * player_progress - 15.0
	shadow_progress_face.position.x = PROGRESS_TRACK_X + PROGRESS_TRACK_WIDTH * shadow_progress - 15.0

func _physics_process(delta: float) -> void:
	if phase == "MONSTER_RUSH":
		_advance_monster_rush(delta)
		return
	if phase != "RUSH":
		return
	player.global_position = player.global_position.move_toward(_rush_target_position, 28.0 * delta)
	rush_timer -= delta
	if player.global_position.distance_to(_rush_target_position) <= 0.08 or rush_timer <= 0.0:
		player.global_position = _rush_target_position
		_finish_rush()

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
		_begin_rush()
	else:
		_fail_qte("WRONG KEY — BACK OFF TO RETRY")

func _check_approach() -> void:
	var horizontal_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if player.global_position.z < current_target.global_position.z - 2.0 and horizontal_velocity.z < -2.0:
		current_target.skipped = true
		current_target = null
		_hud_prompt.text = "MONSTER SKIPPED"
		return
	var horizontal_gap := current_target.global_position - player.global_position
	horizontal_gap.y = 0.0
	if horizontal_gap.length() > APPROACH_DISTANCE or horizontal_velocity.length() < 2.0:
		return
	var toward := horizontal_gap.normalized()
	if horizontal_velocity.normalized().dot(toward) < 0.25:
		return
	phase = "QTE"
	qte_timer = QTE_SECONDS
	_qte_entry_momentum = Vector3(player.velocity.x, 0.0, player.velocity.z)
	Engine.time_scale = _normal_time_scale * QTE_TIME_SCALE
	_hud_prompt.text = "PRESS  %s" % current_target.required_key

func _reactivate_skipped_target_if_approaching() -> void:
	var horizontal_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal_velocity.length() < 2.0:
		return
	for monster in monsters:
		if not is_instance_valid(monster) or monster.defeated or not monster.skipped:
			continue
		var toward_monster := monster.global_position - player.global_position
		toward_monster.y = 0.0
		if toward_monster.length() > APPROACH_DISTANCE:
			continue
		if horizontal_velocity.normalized().dot(toward_monster.normalized()) > 0.25:
			monster.skipped = false

func _begin_rush() -> void:
	_start_rush()

func _start_rush() -> void:
	Engine.time_scale = _normal_time_scale
	phase = "RUSH"
	rush_timer = 0.55
	player.set_physics_process(false)
	var toward := current_target.global_position - player.global_position
	toward.y = 0.0
	_rush_direction = toward.normalized() if toward.length_squared() > 0.001 else Vector3.FORWARD
	_rush_target_position = current_target.global_position - _rush_direction * 1.0
	_rush_target_position.y = player.global_position.y
	player.visual.rotation.y = atan2(_rush_direction.x, _rush_direction.z)
	player.call("_set_animation", "dive")
	_hud_prompt.text = "GO!"

func _spawn_qte_success_effect() -> void:
	var effect_root := Node3D.new()
	effect_root.name = "QteSuccessNotes"
	player.add_child(effect_root)
	effect_root.position = Vector3(0.0, 2.4, 0.0)
	var colors := [Color("36caff"), Color("ff55c8")]
	for index in range(2):
		var note := Node3D.new()
		note.name = "SuccessNoteBlue" if index == 0 else "SuccessNotePink"
		note.position = Vector3(-0.48 if index == 0 else 0.48, 0.0, 0.0)
		_build_success_note_mesh(note, colors[index], index == 1)
		effect_root.add_child(note)
		var glow := OmniLight3D.new()
		glow.name = "BlueSuccessLight" if index == 0 else "PinkSuccessLight"
		glow.position = Vector3(-0.48 if index == 0 else 0.48, 0.05, 0.1)
		glow.light_color = colors[index]
		glow.light_energy = 1.5
		glow.omni_range = 3.5
		effect_root.add_child(glow)
	_qte_success_effects.append({"root": effect_root, "elapsed": 0.0})

func _build_success_note_mesh(note: Node3D, color: Color, double_note: bool) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	if double_note:
		for x in [-0.26, 0.26]:
			var head := SphereMesh.new()
			head.radius = 0.2
			head.height = 0.24
			_add_note_part(note, head, material, Vector3(x, 0.0, 0.0), Vector3(0.0, 0.0, -0.32), Vector3(1.2, 0.8, 0.55))
			var stem := CylinderMesh.new()
			stem.top_radius = 0.035
			stem.bottom_radius = 0.035
			stem.height = 0.82
			_add_note_part(note, stem, material, Vector3(x + 0.12, 0.39, 0.0), Vector3.ZERO, Vector3.ONE)
		_add_note_flag(note, material, Vector3(-0.14, 0.77, 0.0), 0.66)
	else:
		var head := SphereMesh.new()
		head.radius = 0.2
		head.height = 0.24
		_add_note_part(note, head, material, Vector3(-0.08, 0.0, 0.0), Vector3(0.0, 0.0, -0.32), Vector3(1.2, 0.8, 0.55))
		var stem := CylinderMesh.new()
		stem.top_radius = 0.035
		stem.bottom_radius = 0.035
		stem.height = 0.82
		_add_note_part(note, stem, material, Vector3(0.16, 0.39, 0.0), Vector3.ZERO, Vector3.ONE)
		_add_note_flag(note, material, Vector3(0.16, 0.78, 0.0), 0.0)

func _add_note_part(parent: Node3D, mesh: Mesh, material: Material, part_position: Vector3, part_rotation: Vector3, part_scale: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = part_position
	part.rotation = part_rotation
	part.scale = part_scale
	parent.add_child(part)

func _add_note_flag(parent: Node3D, material: Material, flag_position: Vector3, horizontal_offset: float) -> void:
	var flag_mesh := ArrayMesh.new()
	var vertices := PackedVector3Array([
		Vector3(0.0, 0.08, 0.0),
		Vector3(horizontal_offset + 0.12, 0.04, 0.0),
		Vector3(horizontal_offset + 0.2, -0.13, 0.0),
		Vector3(horizontal_offset * 0.42, -0.07, 0.0)
	])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	flag_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_add_note_part(parent, flag_mesh, material, flag_position, Vector3.ZERO, Vector3.ONE)

func _update_qte_success_effects(delta: float) -> void:
	for index in range(_qte_success_effects.size() - 1, -1, -1):
		var effect := _qte_success_effects[index]
		var root := effect["root"] as Node3D
		if not is_instance_valid(root):
			_qte_success_effects.remove_at(index)
			continue
		var elapsed := float(effect["elapsed"]) + delta
		var progress := clampf(elapsed / 1.0, 0.0, 1.0)
		effect["elapsed"] = elapsed
		_qte_success_effects[index] = effect
		root.position.y += delta * 1.5
		root.scale = Vector3.ONE * (0.85 + 0.25 * sin(progress * PI))
		for child in root.get_children():
			if child is Node3D and child.name.begins_with("SuccessNote"):
				for part in child.get_children():
					if part is GeometryInstance3D:
						part.transparency = progress
			elif child is OmniLight3D:
				child.light_energy = 1.5 * (1.0 - progress)
		if elapsed >= 1.0:
			root.queue_free()
			_qte_success_effects.remove_at(index)

func _finish_rush() -> void:
	current_target.launch_from_hit(_rush_direction)
	_spawn_qte_success_effect()
	player.call("launch_from_monster_bounce", Vector3.FORWARD, 22.0, 26.0)
	player.set_physics_process(true)
	phase = "POST_HIT"
	post_hit_timer = 0.45
	current_target = null
	_hud_prompt.text = "MONSTER LAUNCHED — SPEED BOOST!"

func _fail_qte(message: String) -> void:
	if current_target == null:
		return
	if not _player_within_qte_radius():
		Engine.time_scale = _normal_time_scale
		current_target = null
		phase = "APPROACH"
		return
	Engine.time_scale = _normal_time_scale
	phase = "MONSTER_RUSH"
	monster_rush_timer = 1.0
	current_target.visual.call("play_hurt", 0.06)
	_hud_prompt.text = message

func _player_within_qte_radius() -> bool:
	if not is_instance_valid(current_target):
		return false
	var gap := current_target.global_position - player.global_position
	gap.y = 0.0
	return gap.length() <= APPROACH_DISTANCE

func _player_touches_current_target() -> bool:
	if not is_instance_valid(current_target):
		return false
	var player_capsule := player.collision_shape.shape as CapsuleShape3D
	var monster_capsule := current_target.collision_shape.shape as CapsuleShape3D
	if player_capsule == null or monster_capsule == null:
		return player.global_position.distance_to(current_target.global_position) <= 1.5
	var player_scale := player.collision_shape.global_basis.get_scale()
	var monster_scale := current_target.collision_shape.global_basis.get_scale()
	var player_radius := player_capsule.radius * player_scale.x
	var monster_radius := monster_capsule.radius * monster_scale.x
	var player_half_segment := maxf(player_capsule.height * player_scale.y * 0.5 - player_radius, 0.0)
	var monster_half_segment := maxf(monster_capsule.height * monster_scale.y * 0.5 - monster_radius, 0.0)
	var player_center := player.collision_shape.global_position
	var monster_center := current_target.collision_shape.global_position
	var vertical_gap := maxf(absf(player_center.y - monster_center.y) - player_half_segment - monster_half_segment, 0.0)
	var horizontal_gap := Vector2(player_center.x - monster_center.x, player_center.z - monster_center.z).length()
	return Vector2(horizontal_gap, vertical_gap).length() <= player_radius + monster_radius + 0.1

func _advance_monster_rush(delta: float) -> void:
	if not is_instance_valid(current_target):
		phase = "APPROACH"
		return
	var player_aim := player.global_position + Vector3.UP * 0.6
	var toward_player := player_aim - current_target.global_position
	_monster_rush_direction = toward_player.normalized() if toward_player.length_squared() > 0.001 else Vector3.BACK
	current_target.global_position = current_target.global_position.move_toward(player_aim, 23.0 * delta)
	monster_rush_timer -= delta
	var horizontal_gap := Vector2(
		current_target.global_position.x - player.global_position.x,
		current_target.global_position.z - player.global_position.z
	).length()
	if horizontal_gap <= 2.0 or monster_rush_timer <= 0.0:
		current_target.launch_from_failed_qte(-_monster_rush_direction)
		var bump_direction := _monster_rush_direction
		var bump_velocity := bump_direction * 4.5 + _qte_entry_momentum * 0.12
		player.velocity = Vector3(bump_velocity.x, 7.0, bump_velocity.z)
		player.state = "JUMPING"
		player.jump_pending = false
		player.jump_buffer = 0.0
		player.jump_start_timer = 0.0
		player.coyote_timer = 0.0
		player.air_time = 0.0
		player.was_airborne = true
		player.visual.rotation.x = 0.0
		player.call("_set_animation", "jumpRise")
		player.set_physics_process(true)
		player.call("play_hurt_animation")
		phase = "POST_HIT"
		post_hit_timer = 0.45
		current_target = null
		_hud_prompt.text = "MONSTER HIT — BUMPED BACK!"

func _on_monster_disappeared(world_position: Vector3) -> void:
	var smoke_origin := world_position + Vector3.UP * 1.25
	_spawn_smoke_puff(smoke_origin + Vector3.LEFT * 0.2, Color(0.08, 0.74, 1.0, 0.78))
	_spawn_smoke_puff(smoke_origin + Vector3.RIGHT * 0.2, Color(1.0, 0.06, 0.58, 0.78))

func _spawn_smoke_puff(world_position: Vector3, tint: Color) -> void:
	var burst := GPUParticles3D.new()
	burst.name = "MonsterNeonSmoke"
	burst.one_shot = true
	burst.amount = 28
	burst.lifetime = 1.15
	burst.explosiveness = 0.9
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.22
	particle_mesh.height = 0.44
	burst.draw_pass_1 = particle_mesh
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.28
	particle_material.direction = Vector3(0.0, 1.0, 0.0)
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 1.0
	particle_material.initial_velocity_max = 3.5
	particle_material.gravity = Vector3(0.0, 1.2, 0.0)
	particle_material.damping_min = 1.0
	particle_material.damping_max = 2.2
	particle_material.scale_min = 0.55
	particle_material.scale_max = 1.35
	particle_material.color = tint
	var fade := Gradient.new()
	fade.add_point(0.0, tint)
	fade.add_point(0.72, Color(tint.r, tint.g, tint.b, 0.38))
	fade.add_point(1.0, Color(tint.r, tint.g, tint.b, 0.0))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	particle_material.color_ramp = fade_texture
	burst.process_material = particle_material
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glow.albedo_color = tint
	glow.emission_enabled = true
	glow.emission = Color(tint.r, tint.g, tint.b)
	glow.emission_energy_multiplier = 0.75
	burst.material_override = glow
	add_child(burst)
	burst.global_position = world_position
	burst.finished.connect(burst.queue_free)
	burst.emitting = true

func _next_target() -> MonsterQteTarget:
	for monster in monsters:
		if is_instance_valid(monster) and not monster.defeated and not monster.skipped:
			return monster
	return null

func _respawn_player() -> void:
	player.spawn_position = _safe_spawn
	player.global_position = _safe_spawn
	player.velocity = Vector3.ZERO
	player.call("_respawn_at_start")
	player.set_physics_process(true)
	current_target = null
	phase = "APPROACH"

func _build_speed_markers() -> void:
	var marker_root := Node3D.new()
	marker_root.name = "SpeedDistanceMarks"
	add_child(marker_root)
	var minor_material := _speed_mark_material(Color("48b8c8"), 0.35)
	var cyan_material := _speed_mark_material(Color("38e8f5"), 1.0)
	var pink_material := _speed_mark_material(Color("ff55c8"), 0.95)
	var minor_mesh := BoxMesh.new()
	minor_mesh.size = Vector3(15.4, 0.035, 0.08)
	var major_mesh := BoxMesh.new()
	major_mesh.size = Vector3(15.4, 0.045, 0.18)
	for index in range(70):
		var marker := MeshInstance3D.new()
		marker.name = "Distance_%03d" % index
		marker.position = Vector3(0.0, 0.025, 10.0 - float(index) * 5.0)
		if index % 5 == 0:
			marker.mesh = major_mesh
			marker.material_override = cyan_material if int(index / 5) % 2 == 0 else pink_material
		else:
			marker.mesh = minor_mesh
			marker.material_override = minor_material
		marker_root.add_child(marker)

func _speed_mark_material(color: Color, glow: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = glow
	return material

func _check_shadow_hazards() -> void:
	if shadow.touches_player_hazard(player.global_position + Vector3.UP * 0.9):
		player.play_hurt_animation()

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
		if current.has_meta("level_3_hole_source"):
			var source := current.get_meta("level_3_hole_source") as StaticBody3D
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
		combiner.set_meta("level_3_hole_source", source_body)
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
	rim.position.y = 0.03
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

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "RaceHUD"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(20.0, 20.0)
	panel.custom_minimum_size = Vector2(430.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	panel.add_child(stack)
	var player_lane := _create_progress_lane(stack, "YOU", Color("ff43cf"), "res://runner/runner.tscn")
	player_progress_fill = player_lane.get("fill") as ColorRect
	player_progress_face = player_lane.get("face") as Panel
	var shadow_lane := _create_progress_lane(stack, "SHADOW", Color("21c8ff"), "res://enemy_runner/enemy_runner.tscn")
	shadow_progress_fill = shadow_lane.get("fill") as ColorRect
	shadow_progress_face = shadow_lane.get("face") as Panel
	finish_label = Label.new()
	finish_label.text = "3"
	finish_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	finish_label.position = Vector2(-360.0, 78.0)
	finish_label.size = Vector2(720.0, 96.0)
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_race_announcement(82, Color("fff07d"), Color("ff42cf"))
	layer.add_child(finish_label)
	_hud_prompt = Label.new()
	_hud_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_hud_prompt.position = Vector2(-330.0, -75.0)
	_hud_prompt.size = Vector2(660.0, 110.0)
	_hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_prompt.add_theme_font_size_override("font_size", 46)
	_hud_prompt.add_theme_color_override("font_color", Color("ffe385"))
	_hud_prompt.visible = false
	layer.add_child(_hud_prompt)

func _update_hud() -> void:
	if _hud_prompt == null:
		return
	_hud_prompt.visible = race_state == "RACING" and race_go_timer <= 0.0 and phase == "QTE" and is_instance_valid(current_target)
	if _hud_prompt.visible:
		_hud_prompt.text = "PRESS  %s" % current_target.required_key
		_hud_prompt.add_theme_font_size_override("font_size", 40)
		_hud_prompt.add_theme_color_override("font_color", Color("fff0a8"))
		_hud_prompt.add_theme_color_override("font_outline_color", Color("ff42cf"))
		_hud_prompt.add_theme_constant_override("outline_size", 5)

func _create_progress_lane(parent: Control, lane_name: String, tint: Color, scene_path: String) -> Dictionary:
	var row := Control.new()
	row.custom_minimum_size = Vector2(430.0, 34.0)
	row.size = Vector2(430.0, 34.0)
	parent.add_child(row)
	var lane_label := Label.new()
	lane_label.position = Vector2(2.0, 5.0)
	lane_label.size = Vector2(68.0, 23.0)
	lane_label.text = lane_name
	lane_label.add_theme_font_size_override("font_size", 13)
	lane_label.add_theme_color_override("font_color", tint)
	lane_label.add_theme_color_override("font_outline_color", Color(0.015, 0.015, 0.04, 1.0))
	lane_label.add_theme_constant_override("outline_size", 2)
	row.add_child(lane_label)
	var track := ColorRect.new()
	track.position = Vector2(PROGRESS_TRACK_X, 13.0)
	track.size = Vector2(PROGRESS_TRACK_WIDTH, 7.0)
	track.color = Color(0.18, 0.16, 0.27, 0.95)
	row.add_child(track)
	var fill := ColorRect.new()
	fill.size = Vector2(0.0, 7.0)
	fill.color = tint
	track.add_child(fill)
	var marker := Panel.new()
	marker.position = Vector2(PROGRESS_TRACK_X - 15.0, 1.0)
	marker.size = Vector2(30.0, 30.0)
	marker.clip_contents = true
	var marker_style := StyleBoxFlat.new()
	marker_style.bg_color = Color(0.035, 0.025, 0.09, 1.0)
	marker_style.border_color = tint
	marker_style.set_border_width_all(2)
	marker_style.set_corner_radius_all(15)
	marker.add_theme_stylebox_override("panel", marker_style)
	row.add_child(marker)
	var face := TextureRect.new()
	face.position = Vector2(1.0, 1.0)
	face.size = Vector2(28.0, 28.0)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture = _create_character_face_texture(scene_path)
	marker.add_child(face)
	return {"fill": fill, "face": marker}

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
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.72, 0.88)
	environment.ambient_light_energy = 0.8
	world.environment = environment
	portrait_root.add_child(world)
	layer_add_portrait_viewport(viewport)
	return viewport.get_texture()

func layer_add_portrait_viewport(viewport: SubViewport) -> void:
	var layer := get_node_or_null("RaceHUD") as CanvasLayer
	if layer == null:
		layer = find_child("RaceHUD", false, false) as CanvasLayer
	if layer != null:
		layer.add_child(viewport)

func _style_race_announcement(font_size: int, font_color: Color, outline_color: Color) -> void:
	finish_label.add_theme_font_size_override("font_size", font_size)
	finish_label.add_theme_color_override("font_color", font_color)
	finish_label.add_theme_color_override("font_outline_color", outline_color)
	finish_label.add_theme_constant_override("outline_size", 7)
	finish_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.78, 1.0, 0.9))
	finish_label.add_theme_constant_override("shadow_offset_x", 0)
	finish_label.add_theme_constant_override("shadow_offset_y", 4)

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
