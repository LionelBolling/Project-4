extends "res://scripts/race_opponent.gd"
## Level 4 follows the authored platforms and commits to physical gap jumps.
var _route: Array[StaticBody3D] = []
var _platform_index := 0
var recovery_count := 0

func _ready() -> void:
	super._ready()
	for platform in get_parent().get_parent().get_node("Platforms").get_children():
		_route.append(platform)

func _physics_process(delta: float) -> void:
	if not race_active or _route.is_empty():
		return
	if global_position.y < -10.0:
		_recover_on_platform()
	var grounded := is_on_floor()
	if grounded:
		for index in range(get_slide_collision_count()):
			var hit := get_slide_collision(index)
			if hit.get_normal().y > 0.7:
				var route_index := _route.find(hit.get_collider())
				if route_index >= 0:
					_platform_index = route_index
		if _airborne:
			_airborne = false
			_set_animation(&"Run")
		var platform := _route[_platform_index]
		var box := platform.get_node("CollisionShape3D").shape as BoxShape3D
		var target_x := platform.global_position.x
		if _platform_index + 1 < _route.size():
			var next := _route[_platform_index + 1]
			var next_box := next.get_node("CollisionShape3D").shape as BoxShape3D
			target_x = clampf(next.global_position.x, platform.global_position.x - box.size.x / 2.0 + 1.5, platform.global_position.x + box.size.x / 2.0 - 1.5)
			if global_position.z <= platform.global_position.z - box.size.z / 2.0 + 1.8:
				var landing := next.global_position + Vector3(0.0, next_box.size.y / 2.0 + 0.03, next_box.size.z / 2.0 - 3.5)
				landing.x = clampf(global_position.x, next.global_position.x - next_box.size.x / 2.0 + 2.0, next.global_position.x + next_box.size.x / 2.0 - 2.0)
				var rise := landing.y - global_position.y
				var flight_seconds := (jump_velocity + sqrt(maxf(0.0, jump_velocity * jump_velocity - 2.0 * gravity * rise))) / gravity
				velocity = Vector3((landing.x - global_position.x) / flight_seconds, jump_velocity, (landing.z - global_position.z) / flight_seconds)
				_airborne = true
				_set_animation(&"jumpRise")
				_spawn_three_black_projectiles()
		if not _airborne:
			var speed := _get_rubberband_speed(delta)
			velocity.x = move_toward(velocity.x, clampf((target_x - global_position.x) * 2.5, -4.5, 4.5), ground_acceleration * delta)
			velocity.z = move_toward(velocity.z, -speed, ground_acceleration * delta)
			velocity.y = -0.5
	else:
		velocity.y -= gravity * delta
		if velocity.y < 0.0:
			_set_animation(&"jumpFall")
	move_and_slide()
	_update_facing(delta)
	_update_entrail_trails()

func _recover_on_platform() -> void:
	# Retry the last reached platform without skipping ahead in the race.
	var platform := _route[_platform_index]
	var box := platform.get_node("CollisionShape3D").shape as BoxShape3D
	global_position = platform.global_position + Vector3(0.0, box.size.y / 2.0 + 0.05, 0.0)
	velocity = Vector3.ZERO
	_airborne = false
	recovery_count += 1

