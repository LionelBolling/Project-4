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
	intro.walker.position = Vector3(1.4, 0.05, -2.5)
	intro._begin_abduction()
	assert(intro.phase == "portal", "Boombox starts abduction")
	intro.phase_time = 1.8
	intro._tick_abduction(0.016)
	assert(intro.walker.position.y > 0.4, "Abduction lifts player")
	intro.phase_time = 3.4
	intro._tick_abduction(0.016)
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/level_0.tscn", "Abduction enters latest Level 0")
	assert(not current_scene.has_meta("story_round"), "Current level progression remains active")
	print("BEDROOM INTRO CHECK: passed")
	quit()
