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
	check(level.name == "Level2", "Standalone Level2 scene")
	check(level.changing_walls.size() == 18, "Eighteen changing walls")
	check(level.get_node("Level2Parkour").get_child_count() == 48, "Shortened stairs, landing platforms and hurdles")
	var course = level.get_node("StoryCourse")
	check(course.surfaces.size() == 26, "Floating platforms cover shortened course")
	check(is_equal_approx(course.surfaces[0].body.get_node("CollisionShape3D").shape.size.x, 14.88), "Course is wider")
	check(is_equal_approx(level._finish_position(), -242), "Finish is two hundred fifty meters from start")
	check(level.rival.finish_z == level._finish_position(), "Rival uses expanded finish")
	check(course.first_encounter_delay == 6.0 and course.encounter_interval == 8.0, "QTEs allow a six-second opening and eight-second breaks")
	level._start_race()
	level.player.position.z = -195
	level.player.velocity.z = -8
	level._process(0)
	check(level.race_state == "RACING", "Old finish no longer ends the race")
	level.player.position.z = 8
	var wall = level.changing_walls[0]
	var height: float = wall.height
	level._physics_process(wall.duration + 0.01)
	level._physics_process(1)
	check(not is_equal_approx(height, wall.height), "Wall changes height")
	wall.elapsed = wall.duration - 0.01
	level._physics_process(0.005)
	var previous_target: float = wall.target
	level._physics_process(0.02)
	check((previous_target > 3 and wall.target < 3) or (previous_target < 3 and wall.target > 3), "Wall alternates rising and falling")
	check(is_equal_approx(wall.body.get_node("Mesh").mesh.size.y, wall.body.get_node("CollisionShape3D").shape.size.y), "Visual and collider match")
	course.next_encounter = 0
	course._process(0.01)
	check(course.qte_remaining > 0, "Shadow QTE starts")
	course.resolve(true)
	check(course.next_encounter == 8 and level.player.story_boost_time == 5, "QTE reward and slower recurrence")
	level._finish_race(true)
	check(level.race_state == "FINISHED", "Standalone win has restart flow")
	level._restart_race()
	check(level.race_state == "COUNTDOWN", "Restart returns to countdown")
	check(is_equal_approx(wall.height, wall.home), "Restart restores walls")
	if "--visual" in OS.get_cmdline_user_args():
		level.player.camera.global_position = Vector3(3, 6, 1)
		level.player.camera.look_at(Vector3(0, 1, -40))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/level2-preview.png")
		level.player.camera.global_position = Vector3(26, 35, -75)
		level.player.camera.look_at(Vector3(0, 0, -200))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/level2-expanded.png")
	level.queue_free()
	await process_frame
	await process_frame
	print("LEVEL2 CHECK: %d failures" % failures)
	quit(1 if failures else 0)
