extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var intro = load("res://scenes/bedroom_intro.tscn").instantiate()
	root.add_child(intro)
	intro.set_process(false)
	intro.set_physics_process(false)
	intro.phase_time = 1.6
	intro._tick_room_entry(0.0)
	await shot("res://tests/boombox-walk-in.png")
	intro.phase_time = 5.6
	intro._tick_room_entry(0.0)
	await shot("res://tests/boombox-room.png")
	intro.walker.position = Vector3(-2.8, 0.05, -1)
	intro._physics_process(1.0)
	intro._interact()
	assert(intro.message.text == "I cant go to sleep without some noise")
	await shot("res://tests/boombox-bed-message.png")
	intro.walker.position = Vector3(1.4, 0.05, -5.3)
	intro._interact()
	assert(intro.boombox_on)
	intro._physics_process(1.0)
	await shot("res://tests/boombox-playing.png")
	intro.walker.position = Vector3(-2.8, 0.05, -1)
	intro._interact()
	intro.phase_time = 2.0
	intro._tick_sleep()
	await shot("res://tests/boombox-blink.png")
	intro.phase_time = 7.6
	intro._tick_sleep()
	intro.phase_time = 1.7
	intro._tick_abduction(0.016)
	await shot("res://tests/boombox-drag.png")
	quit()
