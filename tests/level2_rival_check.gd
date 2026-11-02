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
	var course = level.get_node("MonsterEncounters")
	course.set_process(false)
	check(level.rival_route.size() == 15, "Level 2 provides a route across every staircase")
	rival.projectile_spawn_chance = 0.0
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
	# Run the full course with actual physics, recording real jumps and landings.
	for attempt in range(3):
		level._restart_race()
		level._start_race()
		var elapsed := 0.0
		var longest_stall := 0.0
		var elevated_sections: Dictionary = {}
		while rival.race_active and elapsed < 65.0:
			await physics_frame
			elapsed += 1.0 / Engine.physics_ticks_per_second
			longest_stall = maxf(longest_stall, level.rival_stall_time)
			if rival.is_on_floor() and rival.position.y > 0.3:
				var section := clampi(roundi((-rival.position.z - 24) / 70), 0, 2)
				elevated_sections[section] = true
		check(rival.position.z <= level._finish_position(), "Rival completes full course on run %d" % attempt)
		check(longest_stall < 2.0, "Clear route avoids prolonged stalls on run %d" % attempt)
		check(rival.parkour_jumps >= 6, "Rival performs physical parkour jumps on run %d" % attempt)
		check(elevated_sections.size() == 3, "Rival lands on all three parkour sections on run %d" % attempt)
		check(level.rival_recoveries == 0, "Rival completes the authored route without recovery teleports")
		print("Run %d: %.1fs, %d jumps, %d elevated sections, final %s" % [attempt, elapsed, rival.parkour_jumps, elevated_sections.size(), rival.position])
	level.queue_free()
	await process_frame
	print("LEVEL2 RIVAL CHECK: %d failures" % failures)
	quit(1 if failures else 0)
