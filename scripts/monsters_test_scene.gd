extends Node3D

const QTE_SECONDS := 2.0
const APPROACH_DISTANCE := 8.5
const QTE_TIME_SCALE := 0.35

@onready var player: MovementTestPlayer = $Player
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
var _hud_speed: Label
var _hud_status: Label
var _hud_prompt: Label
var _qte_success_effects: Array[Dictionary] = []

func _ready() -> void:
	_normal_time_scale = Engine.time_scale
	_safe_spawn = player.global_position
	for monster in monsters:
		monster.disappeared.connect(_on_monster_disappeared)
	_build_environment()
	_build_speed_markers()
	_build_hud()
	player.status_label = _hud_speed
	_update_hud()

func _exit_tree() -> void:
	Engine.time_scale = _normal_time_scale

func _process(delta: float) -> void:
	_update_qte_success_effects(delta)
	if player.is_on_floor() and absf(player.global_position.x) < 6.5:
		_safe_spawn = player.global_position
		_safe_spawn.y = 0.05
	if player.global_position.y < -12.0:
		Engine.time_scale = _normal_time_scale
		_respawn_player()
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

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8074b8")
	environment.ambient_light_energy = 0.7
	environment.glow_enabled = true
	environment.glow_intensity = 0.9
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

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
	title.text = "MONSTER TEST RUN"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("62f4e1"))
	stack.add_child(title)
	_hud_speed = Label.new()
	_hud_speed.text = "STATE  IDLE     SPEED  0.0"
	_hud_speed.add_theme_color_override("font_color", Color("b9faff"))
	stack.add_child(_hud_speed)
	_hud_status = Label.new()
	_hud_status.add_theme_color_override("font_color", Color("ffe385"))
	stack.add_child(_hud_status)
	var controls := Label.new()
	controls.text = "WASD run   Mouse camera   Space jump   Shift glide   Ctrl dive"
	controls.add_theme_font_size_override("font_size", 14)
	stack.add_child(controls)
	_hud_prompt = Label.new()
	_hud_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_hud_prompt.position = Vector2(-330.0, -75.0)
	_hud_prompt.size = Vector2(660.0, 110.0)
	_hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_prompt.add_theme_font_size_override("font_size", 46)
	_hud_prompt.add_theme_color_override("font_color", Color("ffe385"))
	layer.add_child(_hud_prompt)

func _update_hud() -> void:
	if _hud_status == null:
		return
	var defeated_count := 0
	for monster in monsters:
		if is_instance_valid(monster) and monster.defeated:
			defeated_count += 1
	if phase == "QTE":
		_hud_status.text = "%s   QTE  %.1f s" % [current_target.title, maxf(qte_timer, 0.0)]
	elif phase == "CLEAR":
		_hud_status.text = "MONSTER PATH CLEARED"
	else:
		var target := _next_target()
		_hud_status.text = "%d / %d DEFEATED   %s" % [defeated_count, monsters.size(), target.title if target != null else "CLEAR"]
	if phase == "APPROACH":
		_hud_prompt.text = "RUN NEAR THE NEXT MONSTER"

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
