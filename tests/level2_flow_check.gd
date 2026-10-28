extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var level1 = load("res://scenes/level_1.tscn").instantiate()
	root.add_child(level1)
	current_scene = level1
	await process_frame
	level1._race_state = "FINISHED"
	level1._race_winner = "PLAYER"
	level1._win_transition_timer = 0.0
	level1._process(0.016)
	await process_frame
	await process_frame
	var level2 = current_scene
	assert(level2.scene_file_path == "res://scenes/Level2.tscn", "Level 1 advances to Level 2")
	assert(level2.changing_walls.size() == 18, "Shortened Level 2 moving walls loaded")
	assert(level2.has_node("PauseMenu"), "Level 2 has pause menu")
	level2._finish_race(false)
	level2.restart_timer = 0.0
	level2._process(0.016)
	assert(level2.race_state == "COUNTDOWN", "Loss retries Level 2")
	level2._finish_race(true)
	level2.restart_timer = 0.0
	level2._process(0.016)
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/level_3_beta.tscn", "Level 2 win advances to Level 3")
	print("LEVEL2 FLOW CHECK: passed")
	quit()
