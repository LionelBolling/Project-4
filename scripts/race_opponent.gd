extends CharacterBody3D
class_name RaceOpponent

const BlackProjectileScript = preload("res://scripts/rival_black_projectile.gd")

## Rival uses the player's core acceleration, top speed, jump and gravity values.
## Its AI picks a continuous cross-track target, jumps, and uses course walls.
@export var run_speed := 8.5
@export var ground_acceleration := 34.0
@export var air_acceleration := 13.0
@export var run_momentum_decay := 1.8
@export var ground_friction := 26.0
@export var reverse_braking := 42.0
@export var jump_velocity := 10.2
@export var gravity := 24.0
@export var finish_z := -192.0
@export var straight_run := false
@export var rubberband_enabled := true
@export var course_traversal_assist := false
@export_range(6.0, 32.0, 1.0) var course_scan_side_limit := 24.0
@export_range(1.0, 12.0, 0.5) var ai_glide_max_duration := 8.0
@export_range(0.2, 4.0, 0.1) var ai_glide_fall_speed := 0.6
@export_range(8.0, 16.0, 0.5) var ai_glide_speed := 11.0
@export var ai_glide_disabled_after_z := -205.0
@export var ai_glide_route_targets_after_section: PackedStringArray = ["Platform_05"]
@export var long_jump_route_start_z := -205.0
@export_range(24.0, 90.0, 2.0) var long_jump_route_scan_distance := 70.0
@export_range(10.0, 22.0, 0.5) var long_jump_course_speed := 18.5
@export_range(0.1, 1.5, 0.05) var ai_glide_landing_pause := 0.2
@export_range(1.0, 4.0, 0.1) var ai_glide_landing_timeout := 2.8
@export_range(1.0, 5.0, 0.1) var ai_glide_land_animation_speed := 3.0
@export_range(0.0, 0.25, 0.005) var rubberband_speed_per_meter := 0.07
@export_range(0.0, 5.0, 0.1) var rubberband_catchup_cap := 2.8
@export_range(0.0, 3.0, 0.1) var rubberband_lead_slowdown := 1.0
@export_range(0.1, 12.0, 0.1) var rubberband_response := 3.5
@export_range(0.1, 4.0, 0.05) var run_animation_speed_multiplier := 2.0
@export_range(0.1, 4.0, 0.05) var wall_run_animation_speed_multiplier := 2.0
@export_range(0.1, 5.0, 0.1) var wall_jump_animation_speed_multiplier := 3.6
@export_range(0.1, 5.0, 0.1) var dive_land_animation_speed_multiplier := 3.6
@export_range(1.0, 4.2, 0.1) var track_side_limit := 3.8
@export_range(0.3, 3.0, 0.1) var decision_interval_min := 0.65
@export_range(0.4, 4.0, 0.1) var decision_interval_max := 1.7
@export_range(0.0, 1.0, 0.05) var jump_chance_per_decision := 0.55
@export_range(0.0, 1.0, 0.05) var dive_chance_per_decision := 0.24
@export_range(0.1, 5.0, 0.1) var dive_cooldown := 1.8
@export_range(0.0, 10.0, 0.1) var dive_speed_bonus := 4.0
@export_range(0.0, 8.0, 0.1) var dive_ground_launch := 2.4
@export_range(0.5, 4.0, 0.1) var wall_run_duration := 1.6
@export_range(0.0, 10.0, 0.1) var wall_run_gravity := 5.5
@export_range(0.0, 10.0, 0.1) var wall_pull_strength := 2.4
@export_range(0.0, 10.0, 0.1) var wall_jump_away_strength := 6.5
@export_range(0.0, 8.0, 0.1) var wall_run_speed_gain := 2.5
@export_range(0.0, 8.0, 0.1) var wall_jump_speed_bonus := 3.5
@export_range(0.1, 3.0, 0.1) var wall_regrab_cooldown := 1.1
@export_range(48, 300, 1) var entrail_max_points := 160

@onready var visual: Node3D = $EnemyRunner
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var race_active := false
var _rng := RandomNumberGenerator.new()
var _decision_timer := 0.0
var _target_x := 1.15
var _target_forward_speed := 8.5
var _player_target: CharacterBody3D
var _rubberband_adjustment := 0.0
var _airborne := false
var _wall_running := false
var _wall_jump_animation_active := false
var _current_animation: StringName = &""
var _wall_run_timer := 0.0
var _wall_regrab_timer := 0.0
var _wall_normal := Vector3.ZERO
var _wall_direction := Vector3.FORWARD
var _wall_side := 0
var _wall_run_entry_speed := 0.0
var start_position := Vector3.ZERO
var _normal_capsule: CapsuleShape3D
var _dive_capsule: CapsuleShape3D
var _diving := false
var _dive_landing := false
var _dive_left_ground := false
var _dive_cooldown_timer := 0.0
var _dive_direction := Vector3.FORWARD
var _dive_target_speed := 0.0
var _route_landing := Vector3.ZERO
var _has_route_landing := false
var _route_landing_platform_name := ""
var _course_jump_target := Vector3.ZERO
var _has_course_jump_target := false
var _course_jump_target_name := ""
var _course_wall_route := false
var _course_wall_jump_lock := 0.0
var _ai_gliding := false
var _ai_glide_landing := false
var _ai_glide_timer := 0.0
var _ai_glide_landing_timer := 0.0
var _ai_glide_landing_done := false
var _glide_pause_position := Vector3.ZERO
var _has_glide_landing_target := false
var _glide_landing_target := Vector3.ZERO
var _last_safe_position := Vector3.ZERO
var _has_safe_position := false
var _glide_stall_timer := 0.0
var _glide_previous_distance := INF
var _air_time := 0.0
var _entrail_meshes: Array[ImmediateMesh] = []
var _entrail_paths: Array[PackedVector3Array] = []
var _entrail_materials: Array[StandardMaterial3D] = []
var _entrail_widths := [0.055, 0.075, 0.045]

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(48.0)
	_rng.randomize()
	start_position = global_position
	_last_safe_position = global_position
	_has_safe_position = true
	_normal_capsule = collision_shape.shape as CapsuleShape3D
	if _normal_capsule != null:
		_dive_capsule = _normal_capsule.duplicate() as CapsuleShape3D
		_dive_capsule.height = 0.95
	visual.rotation.y = PI
	var animation_player := visual.get("animation_player") as AnimationPlayer
	if animation_player != null:
		animation_player.animation_finished.connect(_on_wall_jump_animation_finished)
	_create_mirrored_wall_animations()
	_create_entrail_trails()
	_set_animation(&"Idle")

func reset_for_race() -> void:
	race_active = false
	global_position = start_position
	velocity = Vector3.ZERO
	_airborne = false
	_wall_running = false
	_wall_jump_animation_active = false
	_wall_run_timer = 0.0
	_wall_regrab_timer = 0.0
	_diving = false
	_dive_landing = false
	_dive_left_ground = false
	_dive_cooldown_timer = 0.0
	_ai_gliding = false
	_ai_glide_landing = false
	_ai_glide_landing_timer = 0.0
	_ai_glide_landing_done = false
	_has_glide_landing_target = false
	_has_course_jump_target = false
	_glide_stall_timer = 0.0
	_glide_previous_distance = INF
	_air_time = 0.0
	_set_dive_collision(false, true)
	for index in range(_entrail_paths.size()):
		_entrail_paths[index] = PackedVector3Array()
		_entrail_meshes[index].clear_surfaces()
	_wall_normal = Vector3.ZERO
	_wall_direction = Vector3.FORWARD
	_wall_side = 0
	_decision_timer = 0.0
	_target_x = start_position.x
	_target_forward_speed = run_speed
	_rubberband_adjustment = 0.0
	visual.rotation = Vector3(0.0, PI, 0.0)
	_set_animation(&"Idle")

func start_race() -> void:
	race_active = true
	_airborne = false
	_decision_timer = 0.0
	_rubberband_adjustment = 0.0
	_target_x = global_position.x
	_set_animation(&"Run")
	_pick_race_intent()

func stop_race() -> void:
	race_active = false
	_wall_running = false
	_wall_jump_animation_active = false
	_diving = false
	_dive_landing = false
	_ai_gliding = false
	_ai_glide_landing = false
	_ai_glide_landing_timer = 0.0
	_ai_glide_landing_done = false
	_has_glide_landing_target = false
	_set_dive_collision(false, true)
	velocity.x = 0.0
	velocity.z = 0.0
	_set_animation(&"Idle")

func _physics_process(delta: float) -> void:
	if not race_active:
		return
	_wall_regrab_timer = maxf(0.0, _wall_regrab_timer - delta)
	_course_wall_jump_lock = maxf(0.0, _course_wall_jump_lock - delta)
	_dive_cooldown_timer = maxf(0.0, _dive_cooldown_timer - delta)
	if is_on_floor() and not _ai_gliding and not _wall_running:
		_last_safe_position = global_position
		_has_safe_position = true
	if _dive_landing:
		_update_dive_landing(delta)
		return
	if _diving:
		_update_dive(delta)
		return
	if _ai_gliding:
		_update_ai_glide(delta)
		return
	if _ai_glide_landing:
		_global_position_during_glide_pause()
		_ai_glide_landing_timer -= delta
		if (_ai_glide_landing_done and _ai_glide_landing_timer <= 0.0) or _ai_glide_landing_timer <= ai_glide_landing_pause - ai_glide_landing_timeout:
			_ai_glide_landing = false
			_airborne = false
			_last_safe_position = global_position
			_has_safe_position = true
			_set_animation(&"Run")
		return
	_set_dive_collision(false)

	var grounded := is_on_floor()
	var wall_jump_started := false
	if course_traversal_assist and grounded and not _wall_running and not _ai_glide_landing:
		_has_course_jump_target = false
		_update_course_traversal()
		if _should_jump_course_gap():
			_has_course_jump_target = _has_route_landing
			if _has_course_jump_target:
				_course_jump_target = _route_landing
				_course_jump_target_name = _route_landing_platform_name
			else:
				_course_jump_target_name = ""
				_course_jump_target_name = _route_landing_platform_name
			velocity.y = jump_velocity
			if _has_course_jump_target and global_position.z <= long_jump_route_start_z:
				var jump_direction := Vector3(_course_jump_target.x - global_position.x, 0.0, _course_jump_target.z - global_position.z).normalized()
				velocity.x = jump_direction.x * long_jump_course_speed
				velocity.z = jump_direction.z * long_jump_course_speed
			_airborne = true
			grounded = false
			_set_animation(&"jumpRise")
			_spawn_three_black_projectiles()
	if _wall_running:
		_wall_run_timer -= delta
		if grounded:
			_wall_running = false
			_airborne = false
			_set_animation(&"Run")
		elif not _wall_is_near():
			_wall_running = false
			_wall_regrab_timer = wall_regrab_cooldown
			_airborne = true
			_set_animation(&"jumpFall")
		elif _wall_run_timer <= 0.0:
			_perform_wall_jump()
			wall_jump_started = true

	if _wall_running:
		velocity.y = move_toward(velocity.y, 0.0, wall_run_gravity * delta)
		var wall_elapsed := wall_run_duration - _wall_run_timer
		var wall_speed := minf(maxf(_wall_run_entry_speed, run_speed) + wall_elapsed * wall_run_speed_gain, run_speed + 4.0)
		_wall_run_entry_speed = wall_speed
		var wall_motion := _wall_direction * wall_speed - _wall_normal * wall_pull_strength
		velocity.x = wall_motion.x
		velocity.z = wall_motion.z
	else:
		if grounded:
			_air_time = 0.0
			if _airborne and velocity.y <= 0.0:
				_airborne = false
				if not _ai_glide_landing:
					_set_animation(&"Run")
			if not _airborne:
				velocity.y = 0.0
		elif not wall_jump_started:
			_airborne = true
			_air_time += delta
			velocity.y -= gravity * delta
			if not straight_run:
				_try_start_wall_run()

		if not wall_jump_started and not _wall_running and not _diving:
			_decision_timer -= delta
			if _decision_timer <= 0.0:
				_pick_race_intent()

		if not _wall_running and not _diving:
			var lateral_error := _target_x - global_position.x
			var lateral_speed := clampf(lateral_error * 1.6, -3.6, 3.6)
			# Keep forward progress while allowing the rival to weave freely across the lane.
			var desired_direction := Vector3(lateral_speed, 0.0, -1.0).normalized()
			if course_traversal_assist and _has_course_jump_target and global_position.z <= long_jump_route_start_z:
				var to_route_target := _course_jump_target - global_position
				to_route_target.y = 0.0
				if to_route_target.length_squared() > 0.01:
					desired_direction = to_route_target.normalized()
			var horizontal := Vector3(velocity.x, 0.0, velocity.z)
			var acceleration := ground_acceleration if grounded else air_acceleration
			var current_speed := horizontal.length()
			var desired_speed := _get_rubberband_speed(delta)
			if current_speed > 1.0 and horizontal.normalized().dot(desired_direction) < -0.2:
				horizontal = horizontal.move_toward(Vector3.ZERO, reverse_braking * delta)
			else:
				var speed_adjustment := run_momentum_decay if current_speed > desired_speed else acceleration
				var steered_speed := move_toward(current_speed, desired_speed, speed_adjustment * delta)
				if current_speed < 0.01:
					horizontal = desired_direction * steered_speed
				else:
					var steering_weight := clampf(acceleration * delta / maxf(current_speed, 0.01), 0.0, 1.0)
					var steered_direction := horizontal.normalized().slerp(desired_direction, steering_weight).normalized()
					horizontal = steered_direction * steered_speed
			velocity.x = horizontal.x
			velocity.z = horizontal.z

	if course_traversal_assist and not grounded and not _wall_running and _air_time >= 0.45 and velocity.y <= 0.5 and _should_use_ai_glide():
		_ai_gliding = true
		_ai_glide_landing = false
		_ai_glide_timer = ai_glide_max_duration
		_glide_stall_timer = 0.0
		_glide_previous_distance = INF
		_has_glide_landing_target = _has_course_jump_target or _has_route_landing
		if _has_course_jump_target:
			_glide_landing_target = _course_jump_target
		elif _has_route_landing:
			_glide_landing_target = _route_landing
		velocity.y = minf(velocity.y, 1.5)
		_set_animation(&"glideFloat")
		_update_ai_glide(delta)
		return

	move_and_slide()
	if _try_course_landing_cheat():
		return
	_finish_physics_step(delta)

func _should_use_ai_glide() -> bool:
	if global_position.z <= ai_glide_disabled_after_z and not ai_glide_route_targets_after_section.has(_course_jump_target_name):
		return false
	if not _has_route_landing:
		return true
	var landing_distance := Vector2(_route_landing.x - global_position.x, _route_landing.z - global_position.z).length()
	return landing_distance > 9.0 and not _has_course_floor_at(global_position.x, global_position.z - 4.0)

func _update_ai_glide(delta: float) -> void:
	_ai_glide_timer -= delta
	if not _has_glide_landing_target:
		_update_course_traversal()
		if _has_route_landing and _route_landing.z < global_position.z - 3.0:
			_glide_landing_target = _route_landing
			_has_glide_landing_target = true
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var desired := Vector3(0.0, 0.0, -1.0) * ai_glide_speed
	var horizontal_distance := INF
	if _has_glide_landing_target:
		var to_landing := Vector3(
			_glide_landing_target.x - global_position.x,
			0.0,
			_glide_landing_target.z - global_position.z
		)
		horizontal_distance = to_landing.length()
		var stopping_speed := sqrt(2.0 * 14.0 * horizontal_distance)
		var target_speed := minf(ai_glide_speed, stopping_speed)
		if horizontal_distance > 0.15:
			desired = to_landing.normalized() * target_speed
		else:
			desired = Vector3.ZERO
	horizontal = horizontal.move_toward(desired, maxf(air_acceleration, 18.0) * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	var target_fall_speed := ai_glide_fall_speed
	if _has_glide_landing_target:
		var time_to_landing := maxf(horizontal_distance / maxf(ai_glide_speed, 0.1), 0.25)
		var height_to_drop := global_position.y - _glide_landing_target.y - 0.25
		target_fall_speed = clampf(height_to_drop / time_to_landing, 0.2, 4.5)
	velocity.y = move_toward(velocity.y, -target_fall_speed, gravity * 0.35 * delta)
	move_and_slide()
	if is_on_floor():
		_ai_gliding = false
		_ai_glide_landing = true
		_ai_glide_landing_timer = ai_glide_landing_pause
		_ai_glide_landing_done = false
		_has_glide_landing_target = false
		_airborne = false
		_air_time = 0.0
		velocity.y = 0.0
		_glide_pause_position = global_position
		_set_animation(&"glideLand")
	else:
		if _has_glide_landing_target:
			if horizontal_distance > 3.0 and horizontal_distance >= _glide_previous_distance - 0.025:
				_glide_stall_timer += delta
			else:
				_glide_stall_timer = 0.0
			_glide_previous_distance = horizontal_distance
			if global_position.y < _glide_landing_target.y - 1.25:
				_recover_to_glide_landing()
		elif _has_safe_position and global_position.y < _last_safe_position.y - 5.0:
			_recover_to_glide_landing()
		if _ai_gliding and (_ai_glide_timer <= 0.0 or _glide_stall_timer >= 1.0):
			_recover_to_glide_landing()
	_finish_physics_step(delta)

func _recover_to_glide_landing() -> void:
	var recovery_point := _glide_landing_target if _has_glide_landing_target else _last_safe_position
	if not _has_glide_landing_target and not _has_safe_position:
		return
	_ai_gliding = false
	_ai_glide_landing = true
	_has_glide_landing_target = false
	_airborne = false
	_air_time = 0.0
	global_position = recovery_point + Vector3.UP * 0.08
	velocity = Vector3(0.0, -2.0, 0.0)
	move_and_slide()
	if is_on_floor():
		_last_safe_position = global_position
		_has_safe_position = true
	velocity = Vector3.ZERO
	_glide_pause_position = global_position
	_ai_glide_landing_timer = ai_glide_landing_pause
	_ai_glide_landing_done = false
	_set_animation(&"glideLand")

func _global_position_during_glide_pause() -> void:
	global_position = _glide_pause_position
	velocity = Vector3.ZERO
	apply_floor_snap()
	move_and_slide()
	if is_on_floor():
		_glide_pause_position = global_position

func _update_dive(delta: float) -> void:
	var grounded := is_on_floor()
	if not grounded:
		_dive_left_ground = true
		velocity.y -= gravity * 0.72 * delta
	elif _dive_left_ground:
		_diving = false
		_dive_landing = true
		_airborne = false
		velocity.y = 0.0
		_set_animation(&"diveLand")
		var animation_player := visual.get("animation_player") as AnimationPlayer
		if animation_player != null:
			animation_player.speed_scale = dive_land_animation_speed_multiplier
		_set_dive_collision(false)
		_update_dive_landing(delta)
		return

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var dive_velocity := _dive_direction * _dive_target_speed
	horizontal = horizontal.move_toward(dive_velocity, 5.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()
	_set_dive_collision(true)
	_finish_physics_step(delta)

func _update_dive_landing(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() > run_speed:
		horizontal = horizontal.move_toward(horizontal.normalized() * run_speed, run_momentum_decay * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()
	_set_dive_collision(false)
	_finish_physics_step(delta)

func _finish_physics_step(delta: float) -> void:
	_update_entrail_trails()
	_update_facing(delta)
	_update_animation_speed()
	if global_position.z <= finish_z:
		global_position.z = finish_z
		stop_race()

func _begin_dive() -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	_dive_direction = horizontal.normalized() if horizontal.length() > 1.0 else Vector3.FORWARD
	if _dive_direction.dot(Vector3.FORWARD) < 0.2:
		_dive_direction = _dive_direction.slerp(Vector3.FORWARD, 0.55).normalized()
	_dive_target_speed = minf(horizontal.length() + dive_speed_bonus, run_speed + 6.0)
	_dive_cooldown_timer = dive_cooldown
	_diving = true
	_dive_landing = false
	_dive_left_ground = not is_on_floor()
	_airborne = true
	if not _dive_left_ground:
		velocity.y = maxf(velocity.y, dive_ground_launch)
	velocity.x = _dive_direction.x * _dive_target_speed
	velocity.z = _dive_direction.z * _dive_target_speed
	_set_dive_collision(true)
	_set_animation(&"dive")
	_spawn_three_black_projectiles()

func set_rubberband_target(target: CharacterBody3D) -> void:
	_player_target = target

func _get_rubberband_speed(delta: float) -> float:
	var wanted_adjustment := 0.0
	if rubberband_enabled and is_instance_valid(_player_target):
		# Positive gap means the rival is behind because the finish is at negative Z.
		var gap := global_position.z - _player_target.global_position.z
		wanted_adjustment = clampf(gap * rubberband_speed_per_meter, -rubberband_lead_slowdown, rubberband_catchup_cap)
	_rubberband_adjustment = move_toward(_rubberband_adjustment, wanted_adjustment, rubberband_response * delta)
	return clampf(_target_forward_speed + _rubberband_adjustment, run_speed - rubberband_lead_slowdown, run_speed + rubberband_catchup_cap)

func _create_entrail_trails() -> void:
	var tints := [Color(0.006, 0.004, 0.012, 0.96), Color(0.018, 0.012, 0.026, 0.90), Color(0.003, 0.003, 0.006, 0.92)]
	for index in range(3):
		var trail_material := StandardMaterial3D.new()
		trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		trail_material.vertex_color_use_as_albedo = true
		trail_material.albedo_color = tints[index]
		var trail_mesh := ImmediateMesh.new()
		var trail_instance := MeshInstance3D.new()
		trail_instance.name = "RivalDarkEntrail_%d" % index
		trail_instance.top_level = true
		trail_instance.mesh = trail_mesh
		add_child(trail_instance)
		_entrail_meshes.append(trail_mesh)
		_entrail_materials.append(trail_material)
		_entrail_paths.append(PackedVector3Array())

func _update_entrail_trails() -> void:
	if _entrail_meshes.is_empty():
		return
	var motion := Vector3(velocity.x, 0.0, velocity.z).normalized()
	if motion.length_squared() < 0.01:
		motion = Vector3.FORWARD
	var side := motion.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = visual.global_basis.x.normalized()
	var base := visual.to_global(Vector3(0.0, 1.05, -0.30))
	var side_offsets := [-0.19, 0.0, 0.19]
	var height_offsets := [0.08, -0.08, 0.18]
	for index in range(_entrail_paths.size()):
		var origin: Vector3 = base + side * side_offsets[index] + Vector3.UP * height_offsets[index]
		var points := _entrail_paths[index]
		if points.is_empty():
			for step in range(9):
				var progress := float(step) / 8.0
				points.append(origin - motion * 0.5 * (1.0 - progress))
		elif points[points.size() - 1].distance_to(origin) > 0.055:
			points.append(origin)
		while points.size() > entrail_max_points:
			points.remove_at(0)
		_entrail_paths[index] = points
		_draw_entrail_ribbon(_entrail_meshes[index], points, _entrail_materials[index], _entrail_widths[index])

func _draw_entrail_ribbon(ribbon: ImmediateMesh, points: PackedVector3Array, material: StandardMaterial3D, width: float) -> void:
	ribbon.clear_surfaces()
	if points.size() < 2:
		return
	ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for index in range(points.size() - 1):
		var start := points[index]
		var finish := points[index + 1]
		var direction := (finish - start).normalized()
		var view_direction := (global_position + Vector3.UP - (start + finish) * 0.5).normalized()
		var side := direction.cross(view_direction).normalized()
		if side.length_squared() < 0.001:
			side = Vector3.UP.cross(direction).normalized()
		if side.length_squared() < 0.001:
			side = Vector3.RIGHT
		var fade := lerpf(0.16, 0.92, float(index + 1) / float(points.size() - 1))
		var segment_width := lerpf(width * 0.35, width, float(index + 1) / float(points.size() - 1))
		var offset := side * segment_width
		ribbon.surface_set_color(Color(1.0, 1.0, 1.0, fade))
		ribbon.surface_add_vertex(start - offset)
		ribbon.surface_add_vertex(start + offset)
		ribbon.surface_add_vertex(finish + offset)
		ribbon.surface_add_vertex(start - offset)
		ribbon.surface_add_vertex(finish + offset)
		ribbon.surface_add_vertex(finish - offset)
	ribbon.surface_end()

func touches_player_hazard(player_center: Vector3, body_radius: float = 0.78, trail_radius: float = 0.48) -> bool:
	if player_center.distance_to(global_position + Vector3.UP * 0.9) <= body_radius:
		return true
	for points in _entrail_paths:
		for index in range(points.size() - 1):
			var start := points[index]
			var segment := points[index + 1] - start
			var length_squared := segment.length_squared()
			var fraction := 0.0 if length_squared <= 0.000001 else clampf((player_center - start).dot(segment) / length_squared, 0.0, 1.0)
			if player_center.distance_to(start + segment * fraction) <= trail_radius:
				return true
	return false

func _set_dive_collision(diving: bool, force_restore: bool = false) -> void:
	if collision_shape == null or _normal_capsule == null or _dive_capsule == null:
		return
	if diving:
		collision_shape.shape = _dive_capsule
		collision_shape.position.y = _dive_capsule.height * 0.5
		return
	if not force_restore and not _can_restore_capsule():
		return
	collision_shape.shape = _normal_capsule
	collision_shape.position.y = _normal_capsule.height * 0.5

func _can_restore_capsule() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _normal_capsule
	query.transform = Transform3D(global_basis, global_position + Vector3.UP * (_normal_capsule.height * 0.5))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _try_start_wall_run() -> void:
	if _wall_regrab_timer > 0.0 or Vector2(velocity.x, velocity.z).length() < 5.0:
		return
	for side in [-1, 1]:
		var direction := Vector3.RIGHT * float(side)
		var query := PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * 0.9,
			global_position + Vector3.UP * 0.9 + direction * 1.35
		)
		query.exclude = [get_rid()]
		query.collision_mask = collision_mask
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or absf(hit.normal.y) >= 0.25:
			continue
		var horizontal := Vector3(velocity.x, 0.0, velocity.z)
		if horizontal.dot(-hit.normal) < -0.2:
			continue
		_wall_side = side
		_wall_normal = hit.normal
		_wall_direction = Vector3.UP.cross(_wall_normal).normalized()
		if _wall_direction.dot(Vector3.FORWARD) < 0.0:
			_wall_direction = -_wall_direction
		_wall_run_entry_speed = horizontal.length()
		_wall_run_timer = wall_run_duration
		_wall_running = true
		_airborne = true
		velocity.y = 0.0
		_set_animation(&"wallRunRightMirrored" if _wall_side > 0 else &"wallRunRight")
		return

func _wall_is_near() -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.9,
		global_position + Vector3.UP * 0.9 - _wall_normal * 1.35
	)
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _perform_wall_jump() -> void:
	_wall_running = false
	_wall_regrab_timer = wall_regrab_cooldown
	if course_traversal_assist:
		_course_wall_jump_lock = 2.4
		_has_course_jump_target = _has_route_landing
		if _has_course_jump_target:
			_course_jump_target = _route_landing
	_airborne = true
	_wall_jump_animation_active = true
	var jump_speed := minf(_wall_run_entry_speed + wall_jump_speed_bonus, run_speed + 6.0)
	var jump_horizontal := _wall_direction * jump_speed + _wall_normal * wall_jump_away_strength
	velocity.x = jump_horizontal.x
	velocity.z = jump_horizontal.z
	velocity.y = jump_velocity
	_target_x = clampf(global_position.x + _wall_normal.x * 2.4, -track_side_limit, track_side_limit)
	_set_animation(&"wallRunLeftJump" if _wall_side < 0 else &"wallRunRightJump")
	_spawn_three_black_projectiles()

func _pick_race_intent() -> void:
	_decision_timer = _rng.randf_range(decision_interval_min, maxf(decision_interval_min, decision_interval_max))
	if straight_run:
		_target_x = start_position.x
		_target_forward_speed = run_speed
		return
	if course_traversal_assist:
		_update_course_traversal()
		_target_forward_speed = run_speed
		return
	var candidate := global_position.x
	for attempt in range(4):
		candidate = _rng.randf_range(-track_side_limit, track_side_limit)
		if absf(candidate - global_position.x) > 1.15:
			break
	_target_x = candidate
	_target_forward_speed = run_speed * _rng.randf_range(0.90, 1.0)
	if _dive_cooldown_timer <= 0.0 and Vector2(velocity.x, velocity.z).length() > 4.0 and _rng.randf() < dive_chance_per_decision:
		_begin_dive()
		return
	if is_on_floor() and _rng.randf() < jump_chance_per_decision:
		var nearest_side := 1.0 if global_position.x >= 0.0 else -1.0
		if _rng.randf() >= 0.75:
			nearest_side = -nearest_side
		_target_x = nearest_side * track_side_limit
		velocity.y = jump_velocity
		_airborne = true
		_set_animation(&"jumpRise")
		_spawn_three_black_projectiles()

func _update_course_traversal() -> void:
	var landing := _find_route_landing()
	_has_route_landing = not landing.is_empty()
	_course_wall_route = false
	if _has_route_landing:
		_route_landing = landing.get("landing_point", landing.position)
		_route_landing_platform_name = str(landing.get("landing_platform_name", ""))
		_target_x = clampf(_route_landing.x, -course_scan_side_limit, course_scan_side_limit)
	elif _course_wall_jump_lock <= 0.0:
		var wall_side := _find_course_wall_side()
		if wall_side != 0:
			_course_wall_route = true
			_target_x = float(wall_side) * minf(track_side_limit - 0.6, 5.5)
	else:
		# Stay near the center of the course while searching for the next surface.
		_target_x = clampf(0.0, -track_side_limit, track_side_limit)

func _should_jump_course_gap() -> bool:
	if not _has_route_landing:
		return not _has_course_floor_at(global_position.x, global_position.z - 3.2)
	if _route_landing.z >= global_position.z - 3.0:
		return false
	var landing_delta := _route_landing - global_position
	landing_delta.y = 0.0
	var max_jump_target := long_jump_route_scan_distance if global_position.z <= long_jump_route_start_z else 24.0
	if landing_delta.length() > max_jump_target:
		return false
	return not _has_course_floor_at(global_position.x, global_position.z - 3.2)

func _find_route_landing() -> Dictionary:
	var space := get_world_3d().direct_space_state
	var best_hit: Dictionary = {}
	var best_distance := INF
	var current_floor := _get_current_floor_collider()
	var lateral_offsets := [-22.0, -18.0, -14.0, -10.0, -6.0, -3.0, 0.0, 3.0, 6.0, 10.0, 14.0, 18.0, 22.0]
	var forward_steps := [5.0, 7.0, 9.0, 11.0, 13.0]
	if global_position.z <= long_jump_route_start_z:
		forward_steps = [5.0, 10.0, 15.0, 20.0, 30.0, 40.0, 50.0, 60.0, long_jump_route_scan_distance]
	for forward_distance in forward_steps:
		for lateral in lateral_offsets:
			var sample_x: float = clampf(global_position.x + float(lateral), -course_scan_side_limit, course_scan_side_limit)
			var sample_z: float = global_position.z - float(forward_distance)
			var query := PhysicsRayQueryParameters3D.create(
				Vector3(sample_x, global_position.y + 10.0, sample_z),
				Vector3(sample_x, global_position.y - 14.0, sample_z)
			)
			query.exclude = [get_rid()]
			query.collision_mask = collision_mask
			var hit := space.intersect_ray(query)
			if hit.is_empty() or hit.normal.y < 0.55:
				continue
			if hit.get("collider") == current_floor:
				continue
			var landing_point := _platform_landing_point(hit)
			if landing_point.z >= global_position.z - 3.0:
				continue
			var height_delta: float = landing_point.y - global_position.y
			if height_delta > 7.5 or height_delta < -10.0:
				continue
			var horizontal_distance := Vector2(landing_point.x - global_position.x, landing_point.z - global_position.z).length()
			var max_route_distance := long_jump_route_scan_distance if global_position.z <= long_jump_route_start_z else 24.0
			if horizontal_distance < 4.0 or horizontal_distance > max_route_distance:
				continue
			if horizontal_distance < best_distance:
				best_distance = horizontal_distance
				best_hit = hit
				best_hit["landing_point"] = landing_point
				var collider := hit.get("collider") as Node
				best_hit["landing_platform_name"] = str(collider.name) if collider != null else ""
	return best_hit

func _get_current_floor_collider() -> Object:
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.0,
		global_position + Vector3.DOWN * 2.5
	)
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") if not hit.is_empty() and hit.normal.y >= 0.55 else null

func _platform_landing_point(hit: Dictionary) -> Vector3:
	var collider := hit.get("collider") as Node3D
	if collider != null:
		var shapes := collider.find_children("CollisionShape3D", "CollisionShape3D", true, false)
		for shape_node in shapes:
			var collision := shape_node as CollisionShape3D
			if collision == null or collision.disabled:
				continue
			var box := collision.shape as BoxShape3D
			if box == null:
				continue
			var center := collision.global_position
			var top := center.y + box.size.y * collision.global_basis.y.length() * 0.5
			return Vector3(center.x, top + 0.03, center.z)
	return hit.position

func _try_course_landing_cheat() -> bool:
	if not course_traversal_assist or global_position.z > long_jump_route_start_z or not _has_course_jump_target:
		return false
	if is_on_floor() or velocity.y >= 0.0 or global_position.y >= _course_jump_target.y - 1.25:
		return false
	global_position = _course_jump_target + Vector3.UP * 0.08
	velocity = Vector3(0.0, -2.0, 0.0)
	move_and_slide()
	if not is_on_floor():
		apply_floor_snap()
	_has_course_jump_target = false
	_airborne = false
	_air_time = 0.0
	_ai_glide_landing = true
	_ai_glide_landing_timer = ai_glide_landing_pause
	_ai_glide_landing_done = false
	_glide_pause_position = global_position
	_set_animation(&"jumpLand")
	return true

func _find_course_wall_side() -> int:
	var best_side := 0
	var best_distance := INF
	for side in [-1, 1]:
		var direction := Vector3.RIGHT * float(side)
		var query := PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * 1.0,
			global_position + Vector3.UP * 1.0 + direction * 8.0
		)
		query.exclude = [get_rid()]
		query.collision_mask = collision_mask
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or absf(hit.normal.y) > 0.25:
			continue
		var distance: float = global_position.distance_to(hit.position)
		if distance < best_distance:
			best_distance = distance
			best_side = side
	return best_side

func _has_course_floor_at(sample_x: float, sample_z: float) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(sample_x, global_position.y + 8.0, sample_z),
		Vector3(sample_x, global_position.y - 12.0, sample_z)
	)
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < 0.55:
		return false
	var height_delta: float = hit.position.y - global_position.y
	return height_delta <= 5.5 and height_delta >= -8.0

func _spawn_three_black_projectiles() -> void:
	if not is_instance_valid(_player_target) or get_parent() == null:
		return
	var race_scene := get_parent()
	var side_sign := -1.0 if global_position.x > 0.0 else 1.0
	var side_direction := Vector3.RIGHT * side_sign
	var forward := Vector3(velocity.x, 0.0, velocity.z).normalized()
	if forward.length_squared() < 0.01:
		forward = Vector3.FORWARD
	var start := global_position + Vector3.UP * 1.2
	var offsets := [-0.7, 0.0, 0.7]
	var launch_directions := [
		(forward + Vector3.UP * 0.12 - side_direction * 0.28).normalized(),
		(forward + side_direction * 0.65 + Vector3.UP * 0.12).normalized(),
		(forward - side_direction * 0.55 - Vector3.UP * 0.08).normalized()
	]
	var surface_hints := [
		Vector3.DOWN + forward * 0.25,
		side_direction + forward * 0.15,
		Vector3.DOWN + forward * 0.55
	]
	var impact_receiver := get_tree().current_scene
	if impact_receiver == null or not impact_receiver.has_method("_on_rival_projectile_surface_impact"):
		impact_receiver = race_scene
	for index in range(3):
		var projectile := BlackProjectileScript.new()
		race_scene.add_child(projectile)
		projectile.global_position = start + side_direction * offsets[index]
		if impact_receiver.has_method("_on_rival_projectile_surface_impact"):
			projectile.surface_impact.connect(Callable(impact_receiver, "_on_rival_projectile_surface_impact"))
		projectile.launch(_player_target, launch_directions[index], surface_hints[index])

func _update_facing(delta: float) -> void:
	var motion := Vector2(_wall_direction.x, _wall_direction.z) if _wall_running else Vector2(velocity.x, velocity.z)
	if motion.length_squared() < 0.04:
		return
	var desired_yaw := atan2(motion.x, motion.y)
	visual.rotation.y = lerp_angle(visual.rotation.y, desired_yaw, 1.0 - exp(-11.0 * delta))

func _update_animation_speed() -> void:
	if _ai_gliding or _ai_glide_landing:
		return
	if _diving or _dive_landing:
		return
	if _airborne:
		if velocity.y < 0.0 and not _wall_jump_animation_active and _current_animation != &"jumpFall":
			_set_animation(&"jumpFall")
		return
	if _current_animation == &"Run":
		var animation_player := visual.get("animation_player") as AnimationPlayer
		if animation_player != null:
			var speed_factor := clampf(Vector2(velocity.x, velocity.z).length() / maxf(run_speed, 0.01), 0.35, 1.65)
			animation_player.speed_scale = run_animation_speed_multiplier * speed_factor

func _set_animation(animation_name: StringName) -> void:
	if _current_animation == animation_name:
		return
	_current_animation = animation_name
	visual.call("play_animation", animation_name, 0.12)
	var animation_player := visual.get("animation_player") as AnimationPlayer
	if animation_player == null:
		return
	if animation_name == &"Run":
		animation_player.speed_scale = run_animation_speed_multiplier
	elif animation_name in [&"wallRunRight", &"wallRunRightMirrored"]:
		animation_player.speed_scale = wall_run_animation_speed_multiplier
	elif animation_name in [&"wallRunRightJump", &"wallRunLeftJump"]:
		animation_player.speed_scale = wall_jump_animation_speed_multiplier
	elif animation_name == &"diveLand":
		animation_player.speed_scale = dive_land_animation_speed_multiplier
	elif animation_name == &"glideLand":
		animation_player.speed_scale = ai_glide_land_animation_speed
	else:
		animation_player.speed_scale = 1.0

func _create_mirrored_wall_animations() -> void:
	var animation_player := visual.get("animation_player") as AnimationPlayer
	if animation_player == null:
		return
	var library := AnimationLibrary.new()
	_add_mirrored_clip(animation_player, library, &"wallRunRight", &"wallRunRightMirrored")
	_add_mirrored_clip(animation_player, library, &"wallRunRightJump", &"wallRunLeftJump")
	if library.get_animation_list().is_empty():
		return
	var error := animation_player.add_animation_library(&"RivalWallMirrors", library)
	if error != OK:
		push_warning("Could not register mirrored rival wall animations: %s" % error_string(error))

func _add_mirrored_clip(animation_player: AnimationPlayer, library: AnimationLibrary, source_name: StringName, mirrored_name: StringName) -> void:
	if animation_player.has_animation(mirrored_name):
		return
	var source_clip := _resolve_animation_clip(animation_player, source_name)
	if source_clip.is_empty():
		return
	var mirrored := animation_player.get_animation(source_clip).duplicate(true) as Animation
	for track in range(mirrored.get_track_count()):
		var path_text := str(mirrored.track_get_path(track))
		if not path_text.contains("Skeleton3D:"):
			continue
		path_text = path_text.replace(".L", ".TMP_SIDE").replace(".R", ".L").replace(".TMP_SIDE", ".R")
		mirrored.track_set_path(track, NodePath(path_text))
		for key in range(mirrored.track_get_key_count(track)):
			var value: Variant = mirrored.track_get_key_value(track, key)
			if mirrored.track_get_type(track) == Animation.TYPE_POSITION_3D and value is Vector3:
				mirrored.track_set_key_value(track, key, Vector3(-value.x, value.y, value.z))
			elif mirrored.track_get_type(track) == Animation.TYPE_ROTATION_3D and value is Quaternion:
				mirrored.track_set_key_value(track, key, Quaternion(value.x, -value.y, -value.z, value.w).normalized())
	if library.add_animation(mirrored_name, mirrored) != OK:
		push_warning("Could not create mirrored rival animation %s" % mirrored_name)

func _resolve_animation_clip(animation_player: AnimationPlayer, animation_name: StringName) -> StringName:
	if animation_player.has_animation(animation_name):
		return animation_name
	for clip in animation_player.get_animation_list():
		if str(clip).ends_with("/" + str(animation_name)):
			return clip
	return &""

func _on_wall_jump_animation_finished(animation_name: StringName) -> void:
	var name := str(animation_name)
	if (name.ends_with("glideLand") or name.ends_with("jumpLand")) and _ai_glide_landing:
		_ai_glide_landing_done = true
		return
	if name.ends_with("diveLand") and _dive_landing:
		_dive_landing = false
		_dive_left_ground = false
		_airborne = false
		_set_dive_collision(false)
		_set_animation(&"Run")
		return
	if not name.ends_with("wallRunRightJump") and not name.ends_with("wallRunLeftJump"):
		return
	_wall_jump_animation_active = false
	if race_active and _airborne and velocity.y < 0.0:
		_set_animation(&"jumpFall")
