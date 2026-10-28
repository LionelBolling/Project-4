extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var level = load("res://scenes/Level2.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	level._start_race()
	var rival = level.rival
	# Keep results/scene changes out of the isolated rival traversal check.
	level.set_process(false)
	level.player.set_physics_process(false)
	var course = level.get_node("StoryCourse")
	course.set_process(false)
	check(rival.story_lane_sway == 0.0, "Level 2 selects the clear middle route")
	# Reproduce being pinned beside a hurdle without forward movement.
	rival.set_physics_process(false)
	rival.position = Vector3(3.3, 0.05, -41.0)
	level.rival_progress_z = -41.0
	for frame in range(125):
		await physics_frame
	check(absf(rival.position.x) < 0.01, "Stalled rival returns to clear lane")
	check(is_equal_approx(rival.position.z, -41.0), "Recovery grants no forward progress")
	check(rival.race_active, "Recovered rival resumes racing")
	rival.position = Vector3(2.0, -4.0, -60.0)
	await physics_frame
	await physics_frame
	check(rival.position.y > 0.0 and absf(rival.position.x) < 0.01, "Fallen rival returns to floor")
	# Run the entire shortened course with actual physics and moving walls.
	for attempt in range(3):
		level._restart_race()
		level._start_race()
		var elapsed := 0.0
		var longest_stall := 0.0
		while rival.race_active and elapsed < 65.0:
			await physics_frame
			elapsed += 1.0 / Engine.physics_ticks_per_second
			longest_stall = maxf(longest_stall, level.rival_stall_time)
		check(rival.position.z <= level._finish_position(), "Rival completes full course on run %d" % attempt)
		check(longest_stall < 2.0, "Clear route avoids prolonged stalls on run %d" % attempt)
	level.queue_free()
	await process_frame
	print("LEVEL2 RIVAL CHECK: %d failures" % failures)
	quit(1 if failures else 0)
