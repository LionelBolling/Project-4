extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var original = load("res://scenes/level_3_beta.tscn").instantiate()
	root.add_child(original)
	await physics_frame
	check(original.monsters.size() == 9, "Existing Level 3 retains its targets")
	original.queue_free()
	await process_frame
	for trial in range(3):
		seed(440 + trial)
		var level = load("res://scenes/level_4.tscn").instantiate()
		root.add_child(level)
		await physics_frame
		check(not level.has_node("Corridor"), "No continuous runway")
		check(level.monsters.size() == 6, "Only six monsters, all before finish")
		for monster in level.monsters:
			check(monster.position.z > level.RACE_FINISH_Z, "No enemies after finish")
		var platforms = level.get_node("Platforms").get_children()
		for index in range(platforms.size()):
			var platform = platforms[index]
			var box = platform.get_node("CollisionShape3D").shape
			check(box.size == platform.get_node("Mesh").mesh.size, "Visual and collider match")
			if index > 0:
				var previous = platforms[index - 1]
				var previous_box = previous.get_node("CollisionShape3D").shape
				var gap: float = previous.position.z - previous_box.size.z / 2.0 - (platform.position.z + box.size.z / 2.0)
				check(gap >= 1.9 and gap <= 3.1, "Gaps stay within normal jump range")
				check(absf(platform.position.y - previous.position.y) <= 1.21, "Rises stay within normal jump height")
		level._start_race()
		level.set_process(false)
		level.player.set_physics_process(false)
		var rival = level.shadow
		# Exercise live projectile impacts as well as physical route traversal.
		var visited := {}
		var frames := 0
		while frames < 3300 and rival.position.z > -332:
			await physics_frame
			frames += 1
			visited[rival._platform_index] = true
		check(rival.position.z <= -332, "Rival completes the entire course")
		check(rival.recovery_count == 0, "Rival traverses without falls or recovery teleports")
		check(visited.size() == 17, "Rival lands on every authored platform")
		print("LEVEL 4 trial %d: %.2fs, %d platforms, %d recoveries" % [trial + 1, frames / 60.0, visited.size(), rival.recovery_count])
		level.queue_free()
		await process_frame
		await process_frame
	print("LEVEL 4 CHECK: %d failures" % failures)
	quit(1 if failures else 0)
