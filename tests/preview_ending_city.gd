extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var ending = load("res://scenes/final_ending.tscn").instantiate()
	root.add_child(ending)
	await process_frame
	ending.set_process(false)
	ending._choose_ending(not OS.get_cmdline_user_args().has("--bad"))
	for time in [1.0, 5.0, 6.7, 8.5, 19.0, 24.0, 26.5, 29.0, 34.0, 39.0]:
		ending.phase_time = time - 0.016
		ending._process(0.016)
		for i in range(5):
			await process_frame
		if time == 26.5 or time == 39.0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/ending-city-%s.png" % str(time))
	quit()
