extends SceneTree

const Progress = preload("res://scripts/city_progress.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	Progress.reset()
	Progress.active = true
	change_scene_to_file("res://scenes/level_0.tscn")
	await process_frame
	await process_frame
	var indicator: Control = current_scene.get_node("Player/SessionHUD/TapeAssembly")
	indicator.call("_process", 0.016)
	assert(indicator.visible and indicator.get("shown_count") == 0)
	assert(indicator.anchor_left == 1.0 and indicator.anchor_right == 1.0 and indicator.offset_right == -20.0, "Tape UI stays at the top right")
	Progress.piece_index = 1
	indicator.call("_process", 0.016)
	assert(indicator.get("shown_count") == 1 and indicator.get("joining_piece") == -1)
	change_scene_to_file("res://scenes/neon_city.tscn")
	await process_frame
	await process_frame
	indicator = current_scene.get_node("Player/SessionHUD/TapeAssembly")
	indicator.call("_process", 0.016)
	assert(indicator.visible and indicator.get("shown_count") == 1)
	assert(indicator.get("joining_piece") == 0, "First fragment assembles in the city")
	indicator.call("_process", 1.2)
	assert(indicator.get("joining_piece") == -1)
	Progress.piece_index = 4
	indicator.call("_process", 0.016)
	assert(indicator.get("shown_count") == 4 and indicator.get("title_label").text == "TAPE RESTORED")
	indicator.call("_process", 1.2)
	Progress.piece_index = 5
	indicator.call("_process", 0.016)
	assert(indicator.get("shown_count") == 4, "Level 4 keeps the four-piece tape complete")
	print("TAPE ASSEMBLY UI: passed")
	Progress.reset()
	quit()
