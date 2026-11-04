extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var level = load("res://scenes/level_4.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	level._start_race()
	level.set_process(false)
	level.shadow.stop_race()
	for monster in level.monsters: monster.set_physics_process(false)
	var platforms = level.get_node("Platforms").get_children()
	var reached := 0
	var jump_platform := -1
	Input.action_press("move_forward")
	Input.action_press("jump", 0.0)
	for frame in range(4200):
		await physics_frame
		var player = level.player
		if player.global_position.y < -10:
			push_error("Player fell after platform %d at %s" % [reached, player.global_position])
			Input.action_release("move_forward")
			quit(1)
			return
		if player.is_on_floor():
			for i in range(player.get_slide_collision_count()):
				var index: int = platforms.find(player.get_slide_collision(i).get_collider())
				if index >= 0: reached = index
			if reached < platforms.size() - 1:
				var platform = platforms[reached]
				var box = platform.get_node("CollisionShape3D").shape
				if player.position.z <= platform.position.z - box.size.z / 2.0 + 3.4 and jump_platform != reached:
					Input.action_release("jump")
					Input.action_press("jump")
					player.jump_buffer = player.jump_buffer_seconds
					jump_platform = reached
		if player.position.z <= -332:
			print("PLAYER ROUTE PASSED: normal movement and jumps reach finish in %.2fs" % [frame / 60.0])
			Input.action_release("move_forward")
			Input.action_release("jump")
			quit()
			return
	push_error("Player route timed out at platform %d" % reached)
	quit(1)
