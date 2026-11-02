extends SceneTree
const Progress = preload("res://scripts/city_progress.gd")
var visual := false

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	if not visual: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/routing-%s.png" % name)

func run() -> void:
	visual = "--visual" in OS.get_cmdline_user_args()
	Progress.reset()
	Progress.arrived = true
	var city = load(Progress.HUB).instantiate()
	root.add_child(city)
	current_scene = city
	await process_frame
	await physics_frame
	city.set_process(false)
	city._set_control(false)
	assert(city.shadow_state == "RUNNING" and city.shadow.visible)
	var previous: Vector3 = city.shadow.position
	city._tick_shadow(1.0)
	assert(city.shadow.position.distance_to(previous) > 3)
	assert(city.shadow.visible and city.shadow.scale == Vector3.ONE)
	city.world_time = 3.6
	city._update_direction_arrow()
	assert(city.direction_arrow.visible)
	await shot("city-arrow")
	city.world_time = 5.0
	city._update_direction_arrow()
	assert(not city.direction_arrow.visible)
	city.world_time = 7.2
	city._update_direction_arrow()
	assert(city.direction_arrow.visible)
	assert(city.find_children("CityBoundary*", "StaticBody3D", false, false).size() == 54)
	var space: PhysicsDirectSpaceState3D = city.get_world_3d().direct_space_state
	for destination in [Vector3(140, 1, -10), Vector3(-140, 1, -10), Vector3(0, 1, 50), Vector3(0, 1, -320)]:
		var start := Vector3(0, 1, -10)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(start, destination, 1))
		assert(not hit.is_empty(), "Every city edge has a visible solid boundary")
	# The street portions of the shadow's authored route avoid building walls.
	for i in range(3):
		var start: Vector3 = city.shadow_route[i] + Vector3.UP
		var end: Vector3 = city.shadow_route[i + 1] + Vector3.UP
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(start, end, 1))
		assert(hit.is_empty(), "Shadow runs through open streets")
	for i in range(1000):
		city._tick_shadow(0.1)
		if city.shadow_state == "ENTERING": break
		assert(city.shadow.visible, "Shadow stays visible until tape arrival")
	assert(city.shadow_state == "ENTERING")
	assert(city.shadow.position.distance_to(city.piece_home) < 1.3)
	await shot("shadow-at-tape")
	city._tick_shadow(1.0)
	assert(city.shadow_state == "INSIDE" and not city.shadow.visible)
	assert(is_instance_valid(city.piece) and Progress.health == 100)
	# Every later tape also has an unobstructed street approach and complete route.
	for tape_index in range(1, city.PIECES.size()):
		city.piece_home = city.PIECES[tape_index]
		city._start_shadow_run()
		for segment in range(3):
			var begin: Vector3 = city.shadow_route[segment] + Vector3.UP
			var finish: Vector3 = city.shadow_route[segment + 1] + Vector3.UP
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(begin, finish, 1))
			assert(hit.is_empty(), "Every tape has an open approach for the shadow")
		for tick in range(2000):
			city._tick_shadow(0.1)
			if city.shadow_state == "ENTERING": break
		assert(city.shadow_state == "ENTERING" and city.shadow.position.distance_to(city.piece_home) < 1.3)
		city._tick_shadow(1.0)
		assert(city.shadow_state == "INSIDE")
	city.piece_home = city.PIECES[0]
	var aim_camera := Camera3D.new()
	city.add_child(aim_camera)
	aim_camera.position = city.player.position + Vector3.UP * 2
	aim_camera.look_at(city.piece_home)
	aim_camera.make_current()
	city._update_direction_arrow()
	assert(absf(wrapf(city.direction_arrow.rotation, -PI, PI)) < 0.05, "Arrow points ahead when facing tape")
	aim_camera.rotation.y += PI
	city._update_direction_arrow()
	assert(absf(absf(wrapf(city.direction_arrow.rotation, -PI, PI)) - PI) < 0.05, "Arrow turns behind when facing away")
	aim_camera.queue_free()
	city.player.camera.make_current()
	# Airborne release and monster bounce cannot refill the two-second budget.
	var player = city.player
	player.position = Vector3(-12, 30, 10)
	player.velocity = Vector3(0, -0.1, 0)
	player.move_and_slide()
	player.state = "GLIDING"
	player.was_airborne = true
	Input.action_press("glide")
	for i in range(45): player._physics_process(1.0 / 60)
	var spent: float = player.glide_timer
	Input.action_release("glide")
	player._physics_process(1.0 / 60)
	assert(is_equal_approx(player.glide_timer, spent))
	player.glide_press_armed = true
	Input.action_press("glide")
	for i in range(20): player._physics_process(1.0 / 60)
	assert(player.state == "GLIDING" and player.glide_timer > spent)
	spent = player.glide_timer
	player.launch_from_monster_bounce(Vector3.FORWARD, 5, 5)
	assert(is_equal_approx(player.glide_timer, spent))
	Input.action_release("glide")
	for i in range(300):
		player._physics_process(1.0 / 60)
		if player.is_on_floor():
			player._physics_process(1.0 / 60)
			break
	assert(player.is_on_floor() and player.glide_timer == 0)
	city.queue_free()
	await process_frame
	change_scene_to_file(Progress.LEVELS[1])
	await process_frame
	await process_frame
	var level = current_scene
	level.set_process(false)
	assert(is_equal_approx(level.player.global_position.z, level.shadow.global_position.z))
	assert(is_equal_approx(level.shadow.start_position.z, level.player.spawn_position.z))
	assert(not level.player.is_physics_processing() and not level.shadow.is_physics_processing())
	await shot("level1-lineup")
	# A missed jump lands on the lower city street and returns to a safe ledge.
	var world = level.get_node("NeonWorld")
	level.player.position = Vector3(30, 2, 8)
	level.player.velocity = Vector3(0, -4, 0)
	level.player.set_physics_process(true)
	var recovered := false
	for i in range(180):
		await physics_frame
		if level.player.position.y > -2 and absf(level.player.position.x) < 4:
			recovered = true
			break
	assert(recovered and Progress.health == 100, "Street catches a missed jump without falling out of map")
	print("CITY ROUTING AND TWO SECOND GLIDE CHECK: passed")
	quit()
