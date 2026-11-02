extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	for scene_name in ["level_0", "level_1", "Level2", "level_3_beta", "bossfight"]:
		var level = load("res://scenes/%s.tscn" % scene_name).instantiate()
		root.add_child(level)
		await process_frame
		await process_frame
		level.set_process(false)
		var city = level.get_node("NeonWorld")
		check(city._districts.size() >= 8, "%s has a complete surrounding city" % scene_name)
		check(city.find_children("*", "MultiMeshInstance3D", true, false).size() > 30, "%s uses batched city geometry" % scene_name)
		check(city.find_children("TowerCollision*", "StaticBody3D", true, false).size() > 30, "%s has solid skyscrapers" % scene_name)
		check(city._street.global_position.y == -8.5, "%s has a safety street below the race" % scene_name)
		var traffic_z: float = city._traffic[0].position.z
		city._process(0.5)
		check(not is_equal_approx(traffic_z, city._traffic[0].position.z), "%s hover traffic animates" % scene_name)
		for world in level.find_children("*", "WorldEnvironment", true, false):
			check(world.environment.sky.sky_material is ProceduralSkyMaterial, "%s uses neon night sky" % scene_name)
		if scene_name == "bossfight":
			level.player.position.z = -2000
			city._process(0.01)
			for district in city._districts:
				check(district.global_position.z <= -1850, "City streams with endless boss chase")
			level.player.position.z = 8
		if "--visual" in OS.get_cmdline_user_args():
			if scene_name == "level_0": level.reveal_overlay.hide()
			var camera := Camera3D.new()
			level.add_child(camera)
			camera.far = 1000
			camera.position = Vector3(24, 26, 32)
			camera.look_at(Vector3(0, 3, -90))
			camera.make_current()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/neon-city-%s.png" % scene_name)
			camera.position = level.player.camera.global_position
			camera.global_basis = level.player.camera.global_basis
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/neon-gameplay-%s.png" % scene_name)
		level.queue_free()
		await process_frame
		await process_frame
	print("NEON WORLD CHECK: %d failures" % failures)
	quit(1 if failures else 0)
