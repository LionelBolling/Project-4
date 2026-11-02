extends "res://scripts/race_opponent.gd"
## Follow the authored parkour lanes and jump physical risers/ledges.
var route_index := 0
var parkour_jumps := 0

func _ready() -> void:
	super._ready()
	straight_run = true
	jump_chance_per_decision = 0.0
	dive_chance_per_decision = 0.0

func reset_for_race() -> void:
	super.reset_for_race()
	route_index = 0
	parkour_jumps = 0

func _pick_race_intent() -> void:
	_decision_timer = 0.1
	_target_forward_speed = run_speed
	_follow_parkour_route()

func _follow_parkour_route() -> void:
	var route: Array = get_parent().rival_route
	while route_index < route.size() and global_position.z < route[route_index].z + 0.3:
		route_index += 1
	_target_x = route[route_index].x if route_index < route.size() else 0.0

func _physics_process(dt: float) -> void:
	if race_active:
		_follow_parkour_route()
		if is_on_floor() and not _airborne and _parkour_jump_needed():
			velocity.y = jump_velocity
			_airborne = true
			parkour_jumps += 1
			_set_animation(&"jumpRise")
			_spawn_three_black_projectiles()
	super._physics_process(dt)

func _parkour_jump_needed() -> bool:
	var space := get_world_3d().direct_space_state
	var forward := Vector3(velocity.x, 0, velocity.z).normalized()
	if forward.z > -0.2: forward = Vector3.FORWARD
	var from := global_position + Vector3.UP * 0.12
	var obstacle := PhysicsRayQueryParameters3D.create(from, from + forward * 1.8, 1)
	obstacle.exclude = [get_rid()]
	if not space.intersect_ray(obstacle).is_empty(): return true
	# Jump from the last stair onto its landing, rather than dropping to the floor.
	if global_position.y > 0.8 and route_index < get_parent().rival_route.size():
		var ahead := global_position + forward * 1.0
		var floor_query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP, ahead - Vector3.UP * 2.0, 1)
		floor_query.exclude = [get_rid()]
		var floor_hit := space.intersect_ray(floor_query)
		return not floor_hit.is_empty() and floor_hit.position.y < global_position.y - 0.4
	return false
