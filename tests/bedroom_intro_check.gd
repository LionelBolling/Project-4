extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var menu = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._start_game()
	await process_frame
	await process_frame
	var intro = current_scene
	assert(intro.scene_file_path == "res://scenes/bedroom_intro.tscn", "Start opens bedroom")
	assert(intro.phase == "room_entry", "Walk-in cinematic starts")
	intro.phase_time = 5.6
	intro._tick_room_entry(0.016)
	assert(intro.phase == "bedroom", "Walk-in hands over control")
	assert(intro.bedroom_model.visible, "Exploration stays third person")
	assert(intro.controls.text.is_empty() and intro.message.text.is_empty(), "No objectives before interaction")
	intro.walker.position = Vector3(-2.8, 0.05, -1)
	intro._interact()
	assert(intro.phase == "bedroom" and not intro.boombox_on, "Bed requires music")
	assert(intro.message.text == "I cant go to sleep without some noise", "Bed responds after interaction")
	assert(intro.bedroom_model.visible, "Failed sleep stays third person")
	intro.walker.position = Vector3(1.4, 0.05, -5.3)
	intro._interact()
	assert(intro.boombox_on and intro.phase == "bedroom", "Music starts without abduction")
	intro.walker.position = Vector3(-2.8, 0.05, -1)
	intro._interact()
	assert(intro.phase == "sleep", "Bed starts sleep")
	assert(not intro.bedroom_model.visible, "Sleep switches to first person")
	for blink in range(3):
		intro.phase_time = 2.1 + blink
		intro._tick_sleep()
		assert(intro.eyelids.material.get_shader_parameter("closure") > 0.99, "Blink fully closes eyes")
	intro.phase_time = 6.0
	intro._tick_sleep()
	assert(intro.eyelids.material.get_shader_parameter("closure") == 1.0, "Eyes stay shut during sleep")
	intro.phase_time = 7.6
	intro._tick_sleep()
	assert(intro.phase == "portal", "Wake-up starts abduction")
	intro.phase_time = 1.8
	intro._tick_abduction(0.016)
	assert(not intro.bedroom_model.visible and intro.camera.current, "Abduction stays first person")
	intro.phase_time = 3.4
	intro._tick_abduction(0.016)
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/neon_city.tscn", "Abduction enters neon city")
	assert(current_scene.phase == "ARRIVAL", "City wake-up cinematic begins")
	assert(not current_scene.player.is_physics_processing(), "Control waits for shadow encounter")
	print("BEDROOM INTRO CHECK: passed")
	quit()
