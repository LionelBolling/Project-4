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
	check(level.changing_walls.size() == 4, "Moving obstacles reduced from eighteen to four")
	check(level.get_node("Level2Parkour").get_child_count() == 9, "Single low parkour section")
	check(not level.has_node("StoryCourse"), "Old random QTE and collapsing surfaces removed")
	var encounters = level.get_node("MonsterEncounters")
	check(encounters.active_targets.size() == 2, "Two actual monster encounters")
	check(encounters.encounter_seconds == 4, "Four-second reaction window")
	check(level.get_node("CourseGeometry/Raceway").collision_layer == 1, "Continuous floor remains playable")
	check(is_equal_approx(level._finish_position(), -242), "Finish distance preserved")
	check(level.rival.finish_z == level._finish_position(), "Rival uses correct finish")
	check(not level.rival.rubberband_enabled and level.rival.run_speed == 5.2, "Slower shadow without catch-up pressure")
	check(level.rival.projectile_spawn_chance == 0.2, "Projectile pressure reduced eighty percent")
	level._start_race()
	level.player.position.z = -195
	level.player.velocity.z = -8
	level._process(0)
	check(level.race_state == "RACING", "Old finish no longer ends race")
	level.player.position.z = 8
	var wall = level.changing_walls[0]
	level._physics_process(wall.duration + 0.01)
	level._physics_process(1)
	check(wall.height <= 1.6, "Walls remain low")
	check(is_equal_approx(wall.body.get_node("Mesh").mesh.size.y, wall.body.get_node("CollisionShape3D").shape.size.y), "Visual and collider match")
	level._finish_race(true)
	check(level.race_state == "FINISHED", "Standalone win retains next-level flow")
	level._restart_race()
	check(level.race_state == "COUNTDOWN", "Standalone restart returns to countdown")
	check(level.get_node("MonsterEncounters").active_targets.size() == 2, "Restart restores monsters")
	level.queue_free()
	await process_frame
	await process_frame
	print("LEVEL2 CHECK: %d failures" % failures)
	quit(1 if failures else 0)
