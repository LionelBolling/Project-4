extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/wordless-%s.png" % name)

func run() -> void:
	var intro = load("res://scenes/bedroom_intro.tscn").instantiate()
	root.add_child(intro)
	intro.set_process(false)
	intro.phase_time = 5.6
	intro._tick_room_entry(0)
	intro.walker.position = Vector3(7.3, 0.05, 2)
	intro._interact()
	intro.phase_time = 1.0
	intro._tick_mirror()
	await capture("reflection")
	intro.boombox_on = true
	intro.phase_time = 1.0
	intro._tick_tape_glimpse()
	await capture("captive")
	intro.queue_free()
	await process_frame
	var city = load("res://scenes/neon_city.tscn").instantiate()
	root.add_child(city)
	city.set_process(false)
	city.time = 10.8
	city._process(0)
	await capture("pursued-boy")
	city.queue_free()
	await process_frame
	preload("res://scripts/city_progress.gd").piece_index = 4
	var last_city = load("res://scenes/neon_city.tscn").instantiate()
	root.add_child(last_city)
	last_city.set_process(false)
	last_city.fade.color.a = 0
	last_city.cinematic.make_current()
	last_city.cinematic.position = last_city.piece_home + Vector3(4, 3.5, 7)
	last_city.cinematic.look_at(last_city.piece_home + Vector3.UP * 1.5)
	await capture("home-window")
	last_city.queue_free()
	await process_frame
	var ending = load("res://scenes/final_ending.tscn").instantiate()
	root.add_child(ending)
	ending.set_process(false)
	for moment in [[5.4, "pickup"], [6.9, "sealed"], [8.6, "sigh"], [16.5, "bed"], [19.1, "shadow"], [21.0, "laugh"], [26.0, "prisoner"], [35.0, "retreat"]]:
		ending.phase_time = moment[0]
		ending._process(0)
		await capture(moment[1])
	ending.queue_free()
	await process_frame
	quit()
