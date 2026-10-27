extends CharacterBody3D
class_name MovementTestPlayer

## Free directional platforming controller used by scenes/movement_test.tscn.
@export var run_speed := 8.5
@export var ground_acceleration := 34.0
@export var air_acceleration := 13.0
@export_range(0.0, 10.0, 0.1) var run_momentum_decay := 1.8
@export var ground_friction := 26.0
@export var stop_braking_friction := 52.0
@export var reverse_braking := 42.0
@export var jump_velocity := 10.2
@export_range(0.0, 0.4, 0.01) var jump_takeoff_animation_delay := 0.14
@export var gravity := 24.0
@export var jump_buffer_seconds := 0.16
@export var coyote_seconds := 0.13
@export var turn_sharpness := 13.0
@export_range(0.0, 0.5, 0.01) var turn_lean_strength := 0.22
@export_range(0.1, 4.0, 0.05) var run_animation_speed_multiplier := 2.0
@export_range(0.1, 4.0, 0.05) var jump_start_animation_speed_multiplier := 2.0
@export var dive_speed := 18.0
@export var dive_duration := 0.95
@export var dive_cooldown := 0.55
@export var dive_repeat_speed_increment := 0.2
@export var dive_ground_launch := 3.2
@export var dive_land_jump_vertical_speed := 13.0
@export var dive_land_jump_horizontal_speed := 20.0
@export var dive_land_jump_cancel_window := 0.45
@export_range(0.0, 1.5, 0.05) var dive_body_pitch := 1.0
@export var dive_pivot_height := 0.9
@export_range(0.5, 5.0, 0.1) var dive_land_animation_speed := 3.6
@export_range(0.5, 5.0, 0.1) var landing_animation_speed := 3.0
@export var wall_run_duration := 4.0
@export var wall_run_gravity := 5.5
@export var wall_run_wall_pull := 7.0
@export_range(0.1, 4.0, 0.05) var wall_run_animation_speed := 2.0
@export var wall_slide_gravity := 10.0
@export var wall_slide_speed := 5.0
@export var wall_jump_strength := 10.0
@export var wall_jump_away_strength := 14.0
@export_range(0.5, 4.0, 0.1) var wall_jump_animation_speed := 3.6
@export var glide_gravity := 2.0
@export var glide_speed := 12.0
@export var glide_steering_acceleration := 18.0
@export var glide_fall_speed_limit := 0.8
@export var glide_delay := 0.10
@export var glide_max_duration := 3.5
@export_range(0.5, 5.0, 0.1) var glide_start_animation_speed := 3.0
@export_group("Boombox beat")
@export_range(0.2, 1.5, 0.01) var speaker_beat_period := 0.5
@export_range(0.0, 0.8, 0.01) var speaker_pulse_amount := 0.32
@export_range(0.05, 0.4, 0.01) var speaker_pulse_rise_fraction := 0.16
@export var mouse_sensitivity := 0.0025
@export var camera_base_distance := 5.8
@export var camera_speed_distance_bonus := 1.2
@export var camera_distance_smoothing := 5.0
@export var camera_follow_height := 1.85
@export var fall_reset_height := -18.0
@export_range(0.0, 0.4, 0.01) var landing_squash_strength := 0.18
@export_range(0.0, 0.4, 0.01) var wall_impact_squash_strength := 0.14
@export var squash_spring_strength := 120.0
@export var squash_damping := 20.0
@export_range(0.5, 5.0, 0.1) var hurt_animation_speed_multiplier := 2.5
@export_range(0.2, 3.0, 0.1) var hurt_contact_cooldown := 1.1
@export_range(0.05, 1.0, 0.05) var hurt_movement_speed_multiplier := 0.2

@onready var visual: Node3D = $Runner
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var anim: AnimationPlayer
var state := "IDLE"
var yaw := 0.0
var pitch := -0.18
var jump_buffer := 0.0
var jump_start_timer := 0.0
var jump_pending := false
var coyote_timer := 0.0
var dive_timer := 0.0
var dive_target_speed := 0.0
var dive_lockout := 0.0
var dive_repeat_speed_bonus := 0.0
var dive_landing_timer := 0.0
var dive_left_ground := false
var dive_jump_animation_active := false
var wall_timer := 0.0
var wall_side := 0
var wall_normal := Vector3.ZERO
var wall_run_direction := Vector3.ZERO
var wall_run_entry_speed := 0.0
var wall_regrab_lock := 0.0
var wall_jump_animation_active := false
var wall_jump_animation_name := "wallRunRightJump"
var glide_timer := 0.0
var glide_animation_active := false
var glide_press_armed := false
var air_time := 0.0
var was_airborne := false
var previous_state := ""
var normal_capsule_height := 1.8
var normal_capsule_y := 0.9
var dive_capsule_height := 0.92
var lean := 0.0
var jump_was_held := false
var status_label: Label
var glide_used_this_air := false
var spawn_position := Vector3.ZERO
var base_visual_scale := Vector3.ONE
var body_scale_effect := Vector3.ZERO
var body_scale_velocity := Vector3.ZERO
var wall_impact_cooldown := 0.0
var cyan_glide_points := PackedVector3Array()
var pink_glide_points := PackedVector3Array()
var cyan_glide_mesh: ImmediateMesh
var pink_glide_mesh: ImmediateMesh
var cyan_glide_material: StandardMaterial3D
var pink_glide_material: StandardMaterial3D
var glide_trail_fade := 0.0
var last_glide_trail_origin := ""
var boombox_root: Node3D
var speaker_pivots: Array[Node3D] = []
var speaker_base_scales: Array[Vector3] = []
var speaker_beat_time := 0.0
var hurt_animation_timer := 0.0
var hurt_contact_cooldown_timer := 0.0

func _ready() -> void:
	spawn_position = global_position
	base_visual_scale = visual.scale
	boombox_root = visual.find_child("Boombox_Root", true, false) as Node3D
	if boombox_root != null:
		for pivot_name in ["Boombox_SpeakerPivot_L", "Boombox_SpeakerPivot_R"]:
			var pivot := boombox_root.find_child(pivot_name, true, false) as Node3D
			if pivot != null:
				speaker_pivots.append(pivot)
				speaker_base_scales.append(pivot.scale)
	_register_inputs()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_pivot.position.y = camera_follow_height
	spring_arm.spring_length = camera_base_distance
	spring_arm.add_excluded_object(get_rid())
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		anim = players[0] as AnimationPlayer
		_create_mirrored_wall_jump_animation()
		_create_mirrored_wall_run_animation()
		_ensure_wall_run_animation_loops()
	_create_glide_light_trails()
	_set_animation("Idle")

func _process(delta: float) -> void:
	_update_boombox_beat(delta)

func _update_boombox_beat(delta: float) -> void:
	if speaker_pivots.is_empty():
		return
	speaker_beat_time = fposmod(speaker_beat_time + delta, maxf(speaker_beat_period, 0.01))
	var phase := speaker_beat_time / maxf(speaker_beat_period, 0.01)
	var pulse: float
	if phase < speaker_pulse_rise_fraction:
		var rise := phase / maxf(speaker_pulse_rise_fraction, 0.01)
		pulse = 1.0 - pow(1.0 - rise, 3.0)
	else:
		var decay := (phase - speaker_pulse_rise_fraction) / (1.0 - speaker_pulse_rise_fraction)
		pulse = pow(1.0 - decay, 1.7)
	for index in range(speaker_pivots.size()):
		var pivot := speaker_pivots[index]
		if is_instance_valid(pivot):
			pivot.scale = speaker_base_scales[index] * (1.0 + speaker_pulse_amount * pulse)

func _register_inputs() -> void:
	var bindings := {
		"move_forward": KEY_W, "move_back": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D,
		"jump": KEY_SPACE, "dive": KEY_CTRL, "glide": KEY_SHIFT
	}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var binding_exists := false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventKey and existing.physical_keycode == bindings[action]:
				binding_exists = true
				break
		if binding_exists: continue
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -0.85, 0.35)
		camera_pivot.rotation = Vector3(pitch, yaw, 0)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		elif event.keycode == KEY_SPACE:
			jump_buffer = jump_buffer_seconds
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if global_position.y < fall_reset_height:
		_respawn_at_start()
		return
	jump_buffer = maxf(0.0, jump_buffer - delta)
	hurt_animation_timer = maxf(0.0, hurt_animation_timer - delta)
	hurt_contact_cooldown_timer = maxf(0.0, hurt_contact_cooldown_timer - delta)
	dive_lockout = maxf(0.0, dive_lockout - delta)
	wall_impact_cooldown = maxf(0.0, wall_impact_cooldown - delta)
	if not Input.is_action_pressed("dive"):
		dive_repeat_speed_bonus = 0.0
	wall_regrab_lock = maxf(0.0, wall_regrab_lock - delta)
	var grounded := is_on_floor()
	var landed_from_glide := was_airborne and (glide_used_this_air or glide_animation_active)
	if state not in ["DIVING", "DIVE_LANDING"] and _capsule_is_diving() and _can_restore_capsule():
		_set_capsule(false)
	if grounded:
		coyote_timer = coyote_seconds
		air_time = 0.0
		glide_timer = 0.0
		glide_used_this_air = false
		glide_press_armed = false
		if was_airborne and state != "DIVING":
			if landed_from_glide:
				state = "LANDING"
				wall_jump_animation_active = false
				dive_left_ground = false
				dive_timer = 0.0
				dive_repeat_speed_bonus = 0.0
				var glide_landing_speed := Vector2(velocity.x, velocity.z).length()
				if glide_landing_speed > run_speed:
					var capped_speed := Vector2(velocity.x, velocity.z).normalized() * run_speed
					velocity.x = capped_speed.x
					velocity.z = capped_speed.y
				_set_animation("glideLand")
				glide_animation_active = false
			elif dive_left_ground:
				_begin_dive_landing()
			elif state != "DIVE_LANDING":
				state = "LANDING"
				wall_jump_animation_active = false
				_set_animation("jumpLand")
				glide_animation_active = false
		was_airborne = false
		wall_timer = 0.0
		if state in ["FALLING", "GLIDING", "WALL_RUNNING", "WALL_SLIDING", "JUMPING"]:
			state = "LANDING"
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		air_time += delta
		if Input.is_action_just_pressed("glide"):
			glide_press_armed = true
		was_airborne = true
	if state == "DIVE_LANDING" and grounded and jump_buffer > 0.0 and _is_near_animation_end("diveLand", dive_land_jump_cancel_window) and _can_restore_capsule():
		jump_buffer = 0.0
		dive_repeat_speed_bonus = 0.0
		_set_capsule(false)
		_begin_dive_recovery_jump()

	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_forward := -camera_pivot.global_basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()
	var cam_right := camera_pivot.global_basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()
	var wish_dir := (cam_right * input_2d.x + cam_forward * -input_2d.y).normalized()
	var glide_held := Input.is_action_pressed("glide")
	var glide_landing_locked := state == "LANDING" and _is_animation_playing("glideLand")
	if jump_pending:
		jump_start_timer = maxf(0.0, jump_start_timer - delta)
		if jump_start_timer <= 0.0:
			jump_pending = false
			velocity.y = jump_velocity
			state = "JUMPING"
			_set_animation("jumpRise")

	if not glide_landing_locked and Input.is_action_just_pressed("dive") and dive_lockout <= 0.0 and state not in ["DIVING", "DIVE_LANDING", "GLIDING", "WALL_RUNNING", "WALL_SLIDING"]:
		_begin_dive(wish_dir)
	if not glide_landing_locked and jump_buffer > 0.0 and coyote_timer > 0.0 and state not in ["DIVING", "DIVE_LANDING", "WALL_RUNNING", "WALL_SLIDING"] and not jump_pending:
		jump_buffer = 0.0
		coyote_timer = 0.0
		if grounded:
			jump_pending = true
			jump_start_timer = jump_takeoff_animation_delay
			velocity.y = 0.0
			state = "JUMPING"
			_set_animation("jumpStart")
		else:
			velocity.y = jump_velocity
			state = "JUMPING"
			_set_animation("jumpStart")

	if not grounded and state not in ["WALL_RUNNING", "WALL_SLIDING"]:
		if state == "GLIDING":
			if glide_held and glide_timer < glide_max_duration:
				glide_timer += delta
			else:
				state = "FALLING"
				if not glide_animation_active:
					_set_animation("jumpFall")
		elif glide_held and glide_press_armed and air_time >= glide_delay and glide_timer < glide_max_duration and not glide_used_this_air and not wall_jump_animation_active:
			var was_diving := state == "DIVING"
			state = "GLIDING"
			glide_timer = 0.0
			glide_used_this_air = true
			glide_press_armed = false
			glide_animation_active = true
			if was_diving:
				dive_timer = 0.0
				dive_left_ground = false
				dive_repeat_speed_bonus = 0.0
				if _can_restore_capsule():
					_set_capsule(false)
			_set_animation("glideStart")
		else:
			if velocity.y <= 0.0 and state == "JUMPING":
				state = "FALLING"
				if not glide_animation_active:
					_set_animation("jumpFall")
		if state in ["JUMPING", "FALLING"] and air_time > 0.12:
			_try_wall_run(wish_dir)

	var horizontal := Vector3(velocity.x, 0, velocity.z)
	if state == "LANDING" and _is_animation_playing("glideLand"):
		# Keep the glide landing pose unobstructed and hold the player in place
		# until its full recovery animation has finished.
		horizontal = Vector3.ZERO
		velocity.y = 0.0
	elif state == "DIVING":
		if dive_timer > 0.0:
			dive_timer = maxf(0.0, dive_timer - delta)
			var dive_dir := Vector3(velocity.x, 0, velocity.z).normalized()
			if dive_dir.length_squared() < 0.01:
				dive_dir = visual.global_basis.z
			horizontal = horizontal.move_toward(dive_dir * dive_target_speed, 22.0 * delta)
		elif is_on_floor() and not dive_left_ground:
			# A low ceiling can prevent a ground dive from leaving the floor.
			_end_dive()
		else:
			# Keep the dive pose and low collision profile while falling; only the
			# initial forward burst is timed. Ground contact starts diveLand.
			horizontal = horizontal.move_toward(Vector3.ZERO, ground_friction * 0.08 * delta)
		velocity.y -= gravity * 0.72 * delta
	elif state == "DIVE_LANDING":
		# Carry the dive's forward momentum through the landing animation, then recover.
		horizontal = horizontal.move_toward(Vector3.ZERO, ground_friction * 0.72 * delta)
	elif state in ["WALL_RUNNING", "WALL_SLIDING"]:
		if jump_buffer > 0.0:
			jump_buffer = 0.0
			var away_from_wall := Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()
			var tangent_momentum := horizontal.slide(away_from_wall)
			horizontal = tangent_momentum + away_from_wall * wall_jump_away_strength
			velocity.x = horizontal.x
			velocity.z = horizontal.z
			velocity.y = wall_jump_strength
			wall_regrab_lock = 0.65
			state = "JUMPING"
			wall_jump_animation_active = true
			wall_jump_animation_name = "wallRunLeftJump" if wall_side < 0 else "wallRunRightJump"
			_set_animation(wall_jump_animation_name)
		elif state == "WALL_RUNNING":
			wall_timer -= delta
			# Hold height and run along the wall for the configured duration.
			horizontal = wall_run_direction * wall_run_entry_speed - wall_normal * wall_run_wall_pull
			velocity.y = move_toward(velocity.y, 0.0, wall_run_gravity * delta)
			if not _wall_still_near():
				wall_regrab_lock = 0.65
				state = "FALLING"
				_set_animation("jumpFall")
			elif wall_timer <= 0.0:
				state = "WALL_SLIDING"
				velocity.y = -1.0
				_set_animation("jumpFall")
		else:
			horizontal = -wall_normal * wall_run_wall_pull
			velocity.y = maxf(velocity.y - wall_slide_gravity * delta, -wall_slide_speed)
			if not _wall_still_near():
				wall_regrab_lock = 0.65
				state = "FALLING"
				_set_animation("jumpFall")
	elif state == "GLIDING":
		var glide_target := wish_dir * glide_speed if wish_dir.length_squared() > 0.0 else horizontal
		horizontal = horizontal.move_toward(glide_target, glide_steering_acceleration * delta)
		velocity.y = maxf(velocity.y - glide_gravity * delta, -glide_fall_speed_limit)
	else:
		var acceleration := ground_acceleration if grounded else air_acceleration
		if wish_dir.length_squared() > 0.001:
			var reversing := horizontal.length() > 1.0 and horizontal.normalized().dot(wish_dir) < -0.2
			if reversing:
				# Brake existing momentum before accelerating into the opposite direction.
				horizontal = horizontal.move_toward(Vector3.ZERO, reverse_braking * delta)
			else:
				var current_speed := horizontal.length()
				# Keep excess move momentum for a while; normal acceleration still
				# reaches run speed quickly when starting below it.
				var speed_adjustment := run_momentum_decay if current_speed > run_speed else acceleration
				var steered_speed := move_toward(current_speed, run_speed, speed_adjustment * delta)
				if current_speed < 0.01:
					horizontal = wish_dir * steered_speed
				else:
					var steering_weight := clampf(acceleration * delta / maxf(current_speed, 0.01), 0.0, 1.0)
					var steered_direction := horizontal.normalized().slerp(wish_dir, steering_weight).normalized()
					horizontal = steered_direction * steered_speed
		elif grounded:
			horizontal = horizontal.move_toward(Vector3.ZERO, stop_braking_friction * delta)
		if not grounded:
			var g := glide_gravity if state == "GLIDING" else gravity
			velocity.y -= g * delta
			if state == "JUMPING" and not Input.is_action_pressed("jump") and velocity.y > 0.0:
				velocity.y = minf(velocity.y, jump_velocity * 0.48)

	if hurt_animation_timer > 0.0 and horizontal.length() > 0.01:
		var hurt_speed_limit := run_speed * hurt_movement_speed_multiplier
		horizontal = horizontal.move_toward(horizontal.normalized() * minf(horizontal.length(), hurt_speed_limit), reverse_braking * delta)
		horizontal = horizontal.limit_length(hurt_speed_limit)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if state not in ["WALL_RUNNING", "WALL_SLIDING", "DIVING", "DIVE_LANDING"]:
		var face_dir := wish_dir if wish_dir.length_squared() > 0.001 else horizontal.normalized()
		if face_dir.length_squared() > 0.001:
			var target_yaw := atan2(face_dir.x, face_dir.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 1.0 - exp(-turn_sharpness * delta))
	var speed_ratio := clampf(horizontal.length() / run_speed, 0.0, 1.0)
	var turn_angle := 0.0
	if wish_dir.length_squared() > 0.01 and horizontal.length() > 3.0:
		turn_angle = clampf(horizontal.normalized().cross(wish_dir).y, -1.0, 1.0) * speed_ratio
	lean = lerpf(lean, -turn_angle * turn_lean_strength, delta * 6.0)
	visual.rotation.z = lerpf(visual.rotation.z, lean, delta * 8.0)
	var target_dive_pitch := dive_body_pitch if state == "DIVING" else 0.0
	visual.rotation.x = lerpf(visual.rotation.x, target_dive_pitch, 1.0 - exp(-12.0 * delta))
	# Rotate around the torso rather than the feet so the forward lean stays above the floor.
	visual.position.y = dive_pivot_height * (1.0 - cos(visual.rotation.x))
	visual.position.z = dive_pivot_height * sin(visual.rotation.x)
	camera_pivot.rotation.z = lerpf(camera_pivot.rotation.z, float(wall_side) * 0.09 if state in ["WALL_RUNNING", "WALL_SLIDING"] else 0.0, delta * 4.0)
	var target_camera_distance := camera_base_distance + camera_speed_distance_bonus * speed_ratio
	spring_arm.spring_length = lerpf(spring_arm.spring_length, target_camera_distance, 1.0 - exp(-camera_distance_smoothing * delta))
	camera.fov = lerpf(camera.fov, 78.0 + speed_ratio * 5.0, delta * 2.0)
	_update_glide_animation()
	var impact_velocity := velocity
	move_and_slide()
	if not grounded and is_on_floor() and impact_velocity.y < -0.5:
		_trigger_landing_squash(impact_velocity.y)
	_trigger_wall_impact_squash(impact_velocity)
	if state == "DIVING":
		if not is_on_floor():
			dive_left_ground = true
		elif dive_left_ground:
			_begin_dive_landing()
	elif state == "DIVE_LANDING":
		if not is_on_floor():
			_abort_dive_landing_to_fall()
		elif anim == null or not anim.is_playing():
			_finish_dive_landing(delta)
	_update_glide_light_trails()
	_update_animation(input_2d)
	_update_run_animation_speed()
	_update_body_scale(delta)
	if status_label != null:
		status_label.text = "STATE  %s     SPEED  %.1f" % [state, Vector2(velocity.x, velocity.z).length()]

func _begin_dive(direction: Vector3) -> void:
	glide_animation_active = false
	jump_pending = false
	jump_start_timer = 0.0
	var horizontal_momentum := Vector3(velocity.x, 0.0, velocity.z)
	var was_grounded := is_on_floor()
	if direction.length_squared() < 0.01:
		direction = horizontal_momentum.normalized() if not was_grounded and horizontal_momentum.length_squared() > 0.01 else visual.global_basis.z
	direction.y = 0.0
	direction = direction.normalized()
	var target_yaw := atan2(direction.x, direction.z)
	visual.rotation.y = target_yaw
	var launch_speed := dive_speed + dive_repeat_speed_bonus
	if not was_grounded:
		launch_speed += maxf(horizontal_momentum.dot(direction), 0.0)
	dive_target_speed = launch_speed
	velocity.x = direction.x * launch_speed
	velocity.z = direction.z * launch_speed
	if was_grounded:
		velocity.y = dive_ground_launch
	else:
		velocity.y = minf(velocity.y, 1.0)
	dive_timer = dive_duration
	dive_lockout = dive_cooldown
	dive_left_ground = not was_grounded
	state = "DIVING"
	_set_capsule(true)
	_set_animation("dive")

func _end_dive() -> void:
	dive_timer = 0.0
	if is_on_floor() and dive_left_ground:
		_begin_dive_landing()
		return
	if _can_restore_capsule():
		_set_capsule(false)
		state = "FALLING" if not is_on_floor() else "RUNNING" if Vector2(velocity.x, velocity.z).length() > 0.35 else "IDLE"
		_set_animation("jumpFall" if not is_on_floor() else "Run" if state == "RUNNING" else "Idle")
	else:
		dive_timer = 0.08

func _begin_dive_landing() -> void:
	if state == "DIVE_LANDING":
		return
	state = "DIVE_LANDING"
	dive_timer = 0.0
	dive_landing_timer = 0.0
	_set_animation("diveLand")

func _finish_dive_landing(delta: float) -> void:
	dive_landing_timer += delta
	if anim != null and dive_landing_timer < 0.16:
		return
	if not _can_restore_capsule():
		return
	_set_capsule(false)
	visual.rotation.x = 0.0
	dive_left_ground = false
	if jump_buffer > 0.0:
		jump_buffer = 0.0
		dive_repeat_speed_bonus = 0.0
		_begin_dive_recovery_jump()
		return
	if Input.is_action_pressed("dive") and dive_lockout <= 0.0:
		dive_repeat_speed_bonus += dive_repeat_speed_increment
		_begin_dive(Vector3.ZERO)
		return
	state = "RUNNING" if Vector2(velocity.x, velocity.z).length() > 0.35 else "IDLE"
	_set_animation("Run" if state == "RUNNING" else "Idle")

func _begin_dive_recovery_jump() -> void:
	var direction := Vector3(velocity.x, 0.0, velocity.z).normalized()
	if direction.length_squared() < 0.01:
		direction = visual.global_basis.z
	direction.y = 0.0
	direction = direction.normalized()
	velocity.x = direction.x * dive_land_jump_horizontal_speed
	velocity.z = direction.z * dive_land_jump_horizontal_speed
	velocity.y = dive_land_jump_vertical_speed
	state = "JUMPING"
	was_airborne = false
	air_time = 0.0
	coyote_timer = 0.0
	jump_pending = false
	glide_animation_active = false
	glide_used_this_air = false
	dive_jump_animation_active = true
	_set_animation("jumpRise")

func _abort_dive_landing_to_fall() -> void:
	# The landing animation can carry the player past a platform edge. Cancel it
	# immediately so the normal fall animation and gravity take over.
	dive_left_ground = false
	dive_landing_timer = 0.0
	state = "FALLING"
	_set_animation("jumpFall")
	if _can_restore_capsule():
		_set_capsule(false)

func _capsule_is_diving() -> bool:
	var cap := collision_shape.shape as CapsuleShape3D
	return cap.height < normal_capsule_height - 0.01

func _respawn_at_start() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	hurt_animation_timer = 0.0
	hurt_contact_cooldown_timer = 0.0
	state = "IDLE"
	jump_buffer = 0.0
	jump_start_timer = 0.0
	jump_pending = false
	coyote_timer = 0.0
	dive_timer = 0.0
	dive_lockout = 0.0
	dive_landing_timer = 0.0
	dive_left_ground = false
	dive_jump_animation_active = false
	wall_timer = 0.0
	wall_regrab_lock = 0.0
	wall_jump_animation_active = false
	glide_timer = 0.0
	glide_animation_active = false
	glide_press_armed = false
	glide_used_this_air = false
	was_airborne = false
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	visual.scale = base_visual_scale
	body_scale_effect = Vector3.ZERO
	body_scale_velocity = Vector3.ZERO
	_set_capsule(false)
	_set_animation("Idle")

func play_hurt_animation() -> bool:
	if anim == null or hurt_contact_cooldown_timer > 0.0:
		return false
	var hurt_clip := _resolve_animation("hurt")
	if hurt_clip.is_empty():
		return false
	hurt_contact_cooldown_timer = hurt_contact_cooldown
	var clip := anim.get_animation(hurt_clip)
	hurt_animation_timer = clip.length / maxf(hurt_animation_speed_multiplier, 0.01)
	_play_hurt_clip()
	return true

func _play_hurt_clip() -> void:
	if anim == null:
		return
	var hurt_clip := _resolve_animation("hurt")
	if hurt_clip.is_empty():
		return
	anim.speed_scale = 1.0
	anim.play(hurt_clip, 0.10, hurt_animation_speed_multiplier)
	anim.advance(0.0)

func _resolve_animation(name: String) -> StringName:
	if anim == null:
		return &""
	if anim.has_animation(name):
		return StringName(name)
	for clip in anim.get_animation_list():
		if str(clip).ends_with("/" + name):
			return clip
	return &""

func _trigger_landing_squash(vertical_speed: float) -> void:
	var impact := clampf(absf(vertical_speed) / jump_velocity, 0.45, 1.6)
	var amount := landing_squash_strength * impact
	body_scale_effect += Vector3(amount, -amount * 1.65, amount)

func _trigger_wall_impact_squash(impact_velocity: Vector3) -> void:
	if wall_impact_cooldown > 0.0 or state in ["WALL_RUNNING", "WALL_SLIDING"]:
		return
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var normal := collision.get_normal()
		if absf(normal.y) > 0.25 or impact_velocity.dot(normal) > -2.0:
			continue
		var local_normal := visual.global_basis.orthonormalized().inverse() * normal
		var amount := wall_impact_squash_strength * clampf(absf(impact_velocity.dot(normal)) / run_speed, 0.5, 1.4)
		if absf(local_normal.x) >= absf(local_normal.z):
			body_scale_effect += Vector3(-amount, amount * 0.2, amount * 0.65)
		else:
			body_scale_effect += Vector3(amount * 0.65, amount * 0.2, -amount)
		wall_impact_cooldown = 0.22
		return

func _update_body_scale(delta: float) -> void:
	var spring_acceleration := -body_scale_effect * squash_spring_strength - body_scale_velocity * squash_damping
	body_scale_velocity += spring_acceleration * delta
	body_scale_effect += body_scale_velocity * delta
	var locomotion_effect := Vector3.ZERO
	if state == "JUMPING":
		var stretch := clampf(velocity.y / maxf(jump_velocity, 0.01), 0.0, 1.0) * 0.08
		locomotion_effect += Vector3(-stretch * 0.45, stretch, -stretch * 0.45)
	elif state == "FALLING":
		var stretch := clampf(absf(velocity.y) / 18.0, 0.0, 1.0) * 0.055
		locomotion_effect += Vector3(-stretch * 0.4, stretch, -stretch * 0.4)
	elif state == "DIVING":
		locomotion_effect += Vector3(-0.035, 0.025, 0.07)
	var multiplier := Vector3.ONE + body_scale_effect + locomotion_effect
	multiplier.x = maxf(multiplier.x, 0.55)
	multiplier.y = maxf(multiplier.y, 0.55)
	multiplier.z = maxf(multiplier.z, 0.55)
	visual.scale = base_visual_scale * multiplier

func _set_capsule(diving: bool) -> void:
	var cap := collision_shape.shape as CapsuleShape3D
	cap.height = dive_capsule_height if diving else normal_capsule_height
	collision_shape.position.y = dive_capsule_height * 0.5 if diving else normal_capsule_y

func _can_restore_capsule() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = normal_capsule_height
	query.shape = cap
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * normal_capsule_y)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _try_wall_run(wish_dir: Vector3) -> void:
	if glide_animation_active or state == "GLIDING" or wall_regrab_lock > 0.0 or Vector2(velocity.x, velocity.z).length() < 5.0: return
	for side in [-1, 1]:
		var direction := visual.global_basis.x * float(side)
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.9, global_position + Vector3.UP * 0.9 + direction * 0.72)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and absf(hit.normal.y) < 0.25 and (wish_dir.length_squared() < 0.01 or wish_dir.dot(-hit.normal) > -0.2):
			wall_side = side
			wall_normal = hit.normal
			wall_run_direction = Vector3.UP.cross(wall_normal).normalized()
			if wall_run_direction.dot(Vector3(velocity.x, 0.0, velocity.z)) < 0.0:
				wall_run_direction = -wall_run_direction
			wall_run_entry_speed = Vector2(velocity.x, velocity.z).length()
			wall_timer = wall_run_duration
			state = "WALL_RUNNING"
			glide_animation_active = false
			velocity.y = 0.0
			_set_animation("wallRunRightMirrored" if side > 0 else "wallRunRight")
			return

func _wall_still_near() -> bool:
	var direction := -wall_normal
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.9, global_position + Vector3.UP * 0.9 + direction * 0.85)
	query.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _update_glide_animation() -> void:
	if glide_animation_active and not is_on_floor() and not _is_animation_playing("glideStart") and anim != null and not _is_animation_playing("glideFloat"):
		_set_animation("glideFloat")

func _create_glide_light_trails() -> void:
	cyan_glide_material = _make_glide_trail_material(Color("31e9ff"))
	pink_glide_material = _make_glide_trail_material(Color("ff3fc8"))
	cyan_glide_mesh = _make_glide_trail_mesh("CyanGlideTrail")
	pink_glide_mesh = _make_glide_trail_mesh("PinkGlideTrail")

func _make_glide_trail_material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 3.0
	return material

func _make_glide_trail_mesh(node_name: String) -> ImmediateMesh:
	var ribbon := ImmediateMesh.new()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.top_level = true
	instance.mesh = ribbon
	add_child(instance)
	return ribbon

func _update_glide_light_trails() -> void:
	# The glide pose and enlarged boombox can continue after releasing Shift,
	# so keep the trail attached to the glider until that pose ends at landing.
	var gliding := not is_on_floor() and (glide_animation_active or _is_animation_playing("glideStart") or _is_animation_playing("glideFloat"))
	var active := state in ["RUNNING", "JUMPING", "FALLING", "DIVING", "DIVE_LANDING", "WALL_RUNNING", "GLIDING"] or gliding
	if gliding != (last_glide_trail_origin == "glider") and not last_glide_trail_origin.is_empty():
		cyan_glide_points.clear()
		pink_glide_points.clear()
	last_glide_trail_origin = "glider" if gliding else "back"
	if active:
		glide_trail_fade = 1.0
		var motion_direction := Vector3(velocity.x, 0.0, velocity.z).normalized()
		if motion_direction.length_squared() < 0.001:
			motion_direction = visual.global_basis.z.normalized()
		var trail_origins := _get_boombox_trail_origins(motion_direction)
		cyan_glide_points = _append_glide_trail_point(cyan_glide_points, trail_origins[0], motion_direction)
		pink_glide_points = _append_glide_trail_point(pink_glide_points, trail_origins[1], motion_direction)
	else:
		glide_trail_fade = maxf(0.0, glide_trail_fade - get_physics_process_delta_time() * 2.5)
	if glide_trail_fade <= 0.0:
		cyan_glide_points.clear()
		pink_glide_points.clear()
	_draw_glide_ribbon(cyan_glide_mesh, cyan_glide_points, cyan_glide_material, 0.045)
	_draw_glide_ribbon(pink_glide_mesh, pink_glide_points, pink_glide_material, 0.045)

func _get_boombox_trail_origins(motion_direction: Vector3) -> Array[Vector3]:
	var backward := -motion_direction.normalized()
	var side := motion_direction.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.001:
		side = visual.global_basis.x.normalized()
	if boombox_root != null and is_instance_valid(boombox_root):
		var bounds := AABB()
		var found_mesh := false
		for mesh_instance in boombox_root.find_children("*", "MeshInstance3D", true, false):
			var mesh := mesh_instance as MeshInstance3D
			if mesh.mesh == null:
				continue
			var world_bounds: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = world_bounds if not found_mesh else bounds.merge(world_bounds)
			found_mesh = true
		if found_mesh:
			var center := bounds.get_center()
			var extent := bounds.size * 0.5
			var surface_distance := INF
			for axis in 3:
				var direction_component := absf(backward[axis])
				if direction_component > 0.001:
					surface_distance = minf(surface_distance, extent[axis] / direction_component)
			if is_finite(surface_distance):
				# Keep the emitter just inside the boombox surface to hide any seam.
				var source := center + backward * surface_distance * 0.96
				return [source - side * 0.09, source + side * 0.09]
	# Fallback for a model variant whose imported node names differ.
	var fallback := visual.to_global(Vector3(0.0, 1.0, -0.35))
	return [fallback - side * 0.09, fallback + side * 0.09]

func _append_glide_trail_point(points: PackedVector3Array, point: Vector3, motion_direction: Vector3) -> PackedVector3Array:
	if points.is_empty():
		# Seed the ribbon at the boombox and extend it backward so it is already
		# visibly attached on the first frame it appears.
		for step in range(9):
			var progress := float(step) / 8.0
			points.append(point - motion_direction * 0.65 * (1.0 - progress))
		return points
	if points[points.size() - 1].distance_to(point) > 0.025:
		points.append(point)
	while points.size() > 48:
		points.remove_at(0)
	return points

func _draw_glide_ribbon(ribbon: ImmediateMesh, points: PackedVector3Array, material: StandardMaterial3D, width: float) -> void:
	if ribbon == null:
		return
	ribbon.clear_surfaces()
	if points.size() < 2 or glide_trail_fade <= 0.0:
		return
	ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for index in range(points.size() - 1):
		var start := points[index]
		var finish := points[index + 1]
		var direction := (finish - start).normalized()
		var view_direction := (camera.global_position - (start + finish) * 0.5).normalized()
		var side := direction.cross(view_direction).normalized()
		if side.length_squared() < 0.001:
			side = Vector3.UP.cross(direction).normalized()
		if side.length_squared() < 0.001:
			side = Vector3.RIGHT
		var segment_fade := lerpf(0.08, 0.9, float(index + 1) / float(points.size() - 1)) * glide_trail_fade
		var segment_width := lerpf(width * 0.35, width, float(index + 1) / float(points.size() - 1))
		var offset := side * segment_width
		ribbon.surface_set_color(Color(1.0, 1.0, 1.0, segment_fade))
		ribbon.surface_add_vertex(start - offset)
		ribbon.surface_add_vertex(start + offset)
		ribbon.surface_add_vertex(finish + offset)
		ribbon.surface_add_vertex(start - offset)
		ribbon.surface_add_vertex(finish + offset)
		ribbon.surface_add_vertex(finish - offset)
	ribbon.surface_end()

func _update_animation(input_2d: Vector2) -> void:
	if hurt_animation_timer > 0.0:
		if not _is_animation_playing("hurt"):
			_play_hurt_clip()
		return
	if dive_jump_animation_active:
		dive_jump_animation_active = false
		return
	if is_on_floor() and state == "LANDING":
		# Glide landing is a full recovery animation and stays in place until it ends.
		if _is_animation_playing("glideLand"):
			return
		# Give active ground movement priority over the landing clip. If the
		# player is already moving when they touch down, resume Run immediately.
		if input_2d.length() > 0.05:
			state = "RUNNING"
			_set_animation("Run")
			return
		if anim == null or not anim.is_playing():
			state = "RUNNING" if Vector2(velocity.x, velocity.z).length() > 0.35 and input_2d.length() > 0.05 else "IDLE"
			_set_animation("Run" if state == "RUNNING" else "Idle")
		return
	if jump_pending or state in ["DIVING", "DIVE_LANDING", "WALL_RUNNING", "WALL_SLIDING", "GLIDING"]: return
	if glide_animation_active and not is_on_floor(): return
	if wall_jump_animation_active:
		if anim != null and _is_animation_playing(wall_jump_animation_name):
			return
		wall_jump_animation_active = false
	if is_on_floor():
		if Vector2(velocity.x, velocity.z).length() > 0.3 and input_2d.length() > 0.05:
			state = "RUNNING"
			_set_animation("Run")
		elif Vector2(velocity.x, velocity.z).length() < 0.35:
			state = "IDLE"
			_set_animation("Idle")
	else:
		state = "FALLING" if velocity.y <= 0.0 else "JUMPING"
		if state == "FALLING": _set_animation("jumpFall")
		elif anim != null and anim.current_animation not in ["jumpStart", "jumpRise"]: _set_animation("jumpRise")

func _set_animation(name: String) -> void:
	if anim == null: return
	var resolved := StringName(name)
	if not anim.has_animation(resolved):
		for clip in anim.get_animation_list():
			if str(clip).ends_with("/" + name): resolved = clip; break
	if not anim.has_animation(resolved) or anim.current_animation == resolved: return
	var playback_speed := 1.0
	if name == "Run":
		playback_speed = run_animation_speed_multiplier
	elif name in ["wallRunRight", "wallRunRightMirrored"]:
		playback_speed = wall_run_animation_speed
	elif name == "jumpStart":
		playback_speed = jump_start_animation_speed_multiplier
	elif name == "glideStart":
		playback_speed = glide_start_animation_speed
	elif name == "diveLand":
		playback_speed = dive_land_animation_speed
	elif name in ["jumpLand", "glideLand"]:
		playback_speed = landing_animation_speed
	elif name in ["wallRunRightJump", "wallRunLeftJump"]:
		playback_speed = wall_jump_animation_speed
	anim.speed_scale = 1.0
	anim.play(resolved, 0.14, playback_speed)

func _update_run_animation_speed() -> void:
	if anim == null:
		return
	if hurt_animation_timer > 0.0:
		return
	if _is_animation_playing("Run"):
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		var speed_factor := clampf(horizontal_speed / maxf(run_speed, 0.01), 0.35, 1.65)
		anim.speed_scale = speed_factor
	else:
		anim.speed_scale = 1.0

func _create_mirrored_wall_jump_animation() -> void:
	if anim == null or not anim.has_animation("wallRunRightJump"):
		return
	if anim.has_animation("wallRunLeftJump"):
		return
	var source := anim.get_animation("wallRunRightJump")
	var mirrored := source.duplicate(true) as Animation
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
	var mirror_library := AnimationLibrary.new()
	var result := mirror_library.add_animation("wallRunLeftJump", mirrored)
	if result != OK:
		push_warning("Could not create mirrored wall jump animation: %s" % error_string(result))
		return
	result = anim.add_animation_library("WallJumpMirror", mirror_library)
	if result != OK:
		push_warning("Could not register mirrored wall jump animation: %s" % error_string(result))

func _ensure_wall_run_animation_loops() -> void:
	if anim == null or not anim.has_animation("wallRunRight"):
		return
	for clip_name in ["wallRunRight", "wallRunRightMirrored"]:
		if anim.has_animation(clip_name):
			anim.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR

func _create_mirrored_wall_run_animation() -> void:
	if anim == null or not anim.has_animation("wallRunRight") or anim.has_animation("wallRunRightMirrored"):
		return
	var mirrored := anim.get_animation("wallRunRight").duplicate(true) as Animation
	_mirror_animation_tracks(mirrored)
	var mirror_library := AnimationLibrary.new()
	var result := mirror_library.add_animation("wallRunRightMirrored", mirrored)
	if result != OK:
		push_warning("Could not create mirrored right wall-run animation: %s" % error_string(result))
		return
	result = anim.add_animation_library("WallRunMirror", mirror_library)
	if result != OK:
		push_warning("Could not register mirrored right wall-run animation: %s" % error_string(result))

func _mirror_animation_tracks(mirrored: Animation) -> void:
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

func _is_animation_playing(name: String) -> bool:
	if anim == null or not anim.is_playing():
		return false
	var current := str(anim.current_animation)
	return current == name or current.ends_with("/" + name)

func _is_near_animation_end(name: String, remaining_seconds: float) -> bool:
	if anim == null:
		return true
	var current := str(anim.current_animation)
	if current != name and not current.ends_with("/" + name):
		return false
	return anim.current_animation_position >= anim.current_animation_length - remaining_seconds

