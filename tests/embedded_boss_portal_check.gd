extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var story: Variant = load("res://scenes/rewind.tscn").instantiate()
	root.add_child(story)
	await process_frame
	story.start_round(4)
	story.stage.successful_hits = 2
	story.stage._finish_enemy_launch()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == "res://scenes/boss_victory_portal.tscn", "Embedded boss opens portal cutscene")
	print("EMBEDDED BOSS PORTAL: passed")
	quit()
