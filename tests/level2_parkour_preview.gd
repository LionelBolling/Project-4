extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/level2-fixed-%s.png" % label)

func run() -> void:
	var level = load("res://scenes/Level2.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	level._start_race()
	level.set_process(false)
	level.player.set_physics_process(false)
	level.get_node("MonsterEncounters").set_process(false)
	level.rival.projectile_spawn_chance = 0
	var camera := Camera3D.new()
	level.add_child(camera)
	camera.make_current()
	var jumps: Dictionary = {}
	var landings: Dictionary = {}
	for frame in range(3600):
		await physics_frame
		var rival = level.rival
		camera.position = rival.position + Vector3(4, 4, 6)
		camera.look_at(rival.position + Vector3.UP)
		var section := clampi(roundi((-rival.position.z - 24) / 70), 0, 2)
		if rival.position.y > 0.8:
			if not rival.is_on_floor() and not jumps.has(section):
				jumps[section] = true
				await capture("jump-%d" % section)
			elif rival.is_on_floor() and not landings.has(section):
				landings[section] = true
				await capture("landing-%d" % section)
		if not rival.race_active: break
	print("LEVEL2 VISUAL: %d jump shots, %d landing shots, %d recoveries" % [jumps.size(), landings.size(), level.rival_recoveries])
	level.queue_free()
	await process_frame
	quit()
