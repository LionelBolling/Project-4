extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var story = load("res://scenes/rewind.tscn").instantiate()
	root.add_child(story)
	await create_timer(1.5).timeout
	await capture("res://tests/rewind-entry.png")
	await create_timer(4.2).timeout
	await capture("res://tests/rewind-bedroom.png")
	story.walker.position = Vector3(1.4, 0.05, -2.5)
	await create_timer(0.5).timeout
	await capture("res://tests/rewind-interaction.png")
	story._begin_abduction()
	await create_timer(1.7).timeout
	await capture("res://tests/rewind-abduction.png")
	story.start_round(2)
	await create_timer(0.5).timeout
	story.stage._start_race()
	var course = story.stage.get_node("StoryCourse")
	course.next_encounter = 0
	await create_timer(0.1).timeout
	await capture("res://tests/rewind-race.png")
	story._set_phase("ending")
	story.home_returned = false
	story.phase_time = 6.5
	await process_frame
	story.phase_time = 13
	await create_timer(2).timeout
	await capture("res://tests/rewind-ending.png")
	quit()
