extends CharacterBody3D
class_name MovementTestPlayer

## Free directional platforming controller used by scenes/movement_test.tscn.
@export var run_speed := 8.5
@export var ground_acceleration := 34.0
@export var air_acceleration := 13.0
@export var ground_friction := 26.0
@export var stop_braking_friction := 52.0
@export var reverse_braking := 42.0
@export var jump_velocity := 10.2
@export_range(0.0, 0.4, 0.01) var jump_takeoff_animation_delay := 0.14
@export var gravity := 24.0
@export var jump_buffer_seconds := 0.16
@export var coyote_seconds := 0.13
@export var turn_sharpness := 13.0
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
@export var wall_run_speed := 8.0
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
@export var mouse_sensitivity := 0.0025
@export var fall_reset_height := -18.0
@export_range(0.0, 0.4, 0.01) var landing_squash_strength := 0.18
@export_range(0.0, 0.4, 0.01) var wall_impact_squash_strength := 0.14
@export var squash_spring_strength := 120.0
@export var squash_damping := 20.0

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
var dive_lockout := 0.0
var dive_repeat_speed_bonus := 0.0
var dive_landing_timer := 0.0
var dive_left_ground := false
var dive_jump_animation_active := false
var wall_timer := 0.0
var wall_side := 0
var wall_normal := Vector3.ZERO
var wall_run_direction := Vector3.ZERO
var wall_regrab_lock := 0.0
var wall_jump_animation_active := false
var wall_jump_animation_name := "wallRunRightJump"
var glide_timer := 0.0
var glide_animation_active := false
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

func _ready() -> void:
	spawn_position = global_position
	base_visual_scale = visual.scale
	_register_inputs()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		anim = players[0] as AnimationPlayer
		_create_mirrored_wall_jump_animation()
		_ensure_wall_run_animation_loops()
	_set_animation("Idle")

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
		glide_used_this_air = false
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
	if jump_pending:
		jump_start_timer = maxf(0.0, jump_start_timer - delta)
		if jump_start_timer <= 0.0:
			jump_pending = false
			velocity.y = jump_velocity
			state = "JUMPING"
			_set_animation("jumpRise")

	if Input.is_action_just_pressed("dive") and dive_lockout <= 0.0 and state not in ["DIVING", "DIVE_LANDING", "GLIDING", "WALL_RUNNING", "WALL_SLIDING"]:
		_begin_dive(wish_dir)
	if jump_buffer > 0.0 and coyote_timer > 0.0 and state not in ["DIVING", "DIVE_LANDING", "WALL_RUNNING", "WALL_SLIDING"] and not jump_pending:
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
		elif glide_held and air_time >= glide_delay and glide_timer < glide_max_duration and not glide_used_this_air and not wall_jump_animation_active:
			var was_diving := state == "DIVING"
			state = "GLIDING"
			glide_timer = 0.0
			glide_used_this_air = true
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
	if state == "DIVING":
		if dive_timer > 0.0:
			dive_timer = maxf(0.0, dive_timer - delta)
			var dive_dir := Vector3(velocity.x, 0, velocity.z).normalized()
			if dive_dir.length_squared() < 0.01:
				dive_dir = visual.global_basis.z
			horizontal = horizontal.move_toward(dive_dir * (dive_speed + dive_repeat_speed_bonus), 22.0 * delta)
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
			horizontal = wall_run_direction * wall_run_speed - wall_normal * wall_run_wall_pull
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
			var target := wish_dir * run_speed
			var reversing := horizontal.length() > 1.0 and horizontal.normalized().dot(wish_dir) < -0.2
			horizontal = horizontal.move_toward(target, (reverse_braking if reversing else acceleration) * delta)
		elif grounded:
			horizontal = horizontal.move_toward(Vector3.ZERO, stop_braking_friction * delta)
		if not grounded:
			var g := glide_gravity if state == "GLIDING" else gravity
			velocity.y -= g * delta
			if state == "JUMPING" and not Input.is_action_pressed("jump") and velocity.y > 0.0:
				velocity.y = minf(velocity.y, jump_velocity * 0.48)

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
	lean = lerpf(lean, -turn_angle * 0.12, delta * 5.0)
	visual.rotation.z = lerpf(visual.rotation.z, lean, delta * 7.0)
	var target_dive_pitch := dive_body_pitch if state == "DIVING" else 0.0
	visual.rotation.x = lerpf(visual.rotation.x, target_dive_pitch, 1.0 - exp(-12.0 * delta))
	# Rotate around the torso rather than the feet so the forward lean stays above the floor.
	visual.position.y = dive_pivot_height * (1.0 - cos(visual.rotation.x))
	visual.position.z = dive_pivot_height * sin(visual.rotation.x)
	camera_pivot.rotation.z = lerpf(camera_pivot.rotation.z, float(wall_side) * 0.09 if state in ["WALL_RUNNING", "WALL_SLIDING"] else 0.0, delta * 4.0)
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
	_update_animation(input_2d)
	_update_body_scale(delta)
	if status_label != null:
		status_label.text = "STATE  %s     SPEED  %.1f" % [state, Vector2(velocity.x, velocity.z).length()]

func _begin_dive(direction: Vector3) -> void:
	glide_animation_active = false
	jump_pending = false
	jump_start_timer = 0.0
	if direction.length_squared() < 0.01:
		direction = visual.global_basis.z
	direction.y = 0.0
	direction = direction.normalized()
	var was_grounded := is_on_floor()
	var target_yaw := atan2(direction.x, direction.z)
	visual.rotation.y = target_yaw
	var launch_speed := dive_speed + dive_repeat_speed_bonus
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
	glide_used_this_air = false
	was_airborne = false
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	visual.scale = base_visual_scale
	body_scale_effect = Vector3.ZERO
	body_scale_velocity = Vector3.ZERO
	_set_capsule(false)
	_set_animation("Idle")

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
			wall_timer = wall_run_duration
			state = "WALL_RUNNING"
			glide_animation_active = false
			velocity.y = 0.0
			_set_animation("wallRunRight")
			return

func _wall_still_near() -> bool:
	var direction := -wall_normal
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.9, global_position + Vector3.UP * 0.9 + direction * 0.85)
	query.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _update_glide_animation() -> void:
	if glide_animation_active and not is_on_floor() and not _is_animation_playing("glideStart") and anim != null and not _is_animation_playing("glideFloat"):
		_set_animation("glideFloat")

func _update_animation(input_2d: Vector2) -> void:
	if dive_jump_animation_active:
		dive_jump_animation_active = false
		return
	if is_on_floor() and state == "LANDING":
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
	elif name == "wallRunRight":
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
	anim.play(resolved, 0.14, playback_speed)

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
	var wall_run_clip := anim.get_animation("wallRunRight")
	wall_run_clip.loop_mode = Animation.LOOP_LINEAR

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

