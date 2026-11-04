extends SceneTree

const CASES := [
	["res://scenes/bedroom_intro.tscn", 0],
	["res://scenes/neon_city.tscn", 3],
	["res://scenes/level_0.tscn", 1],
	["res://scenes/level_1.tscn", 1],
	["res://scenes/Level2.tscn", 1],
	["res://scenes/level_3_beta.tscn", 1],
	["res://scenes/boss_cutscene_start.tscn", 3],
	["res://scenes/bossfight.tscn", 3],
	["res://scenes/boss_victory_portal.tscn", 3],
	["res://scenes/final_ending.tscn", 3],
]

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var director := root.get_node("MusicDirector")
	var failures := 0
	for item in CASES:
		var err := change_scene_to_file(item[0])
		await process_frame
		await process_frame
		if err != OK or director.current_track != item[1]:
			push_error("Wrong music in " + item[0])
			failures += 1
		elif item[1] != 0 and (not director.player.playing or not director.player.stream.loop):
			push_error("Music is stopped or not looping in " + item[0])
			failures += 1
		if item[0] == "res://scenes/neon_city.tscn":
			current_scene.call("_enter_exploration")
			if director.current_track != 2:
				push_error("City exploration did not switch to track 2")
				failures += 1
	change_scene_to_file("res://scenes/bedroom_intro.tscn")
	await process_frame
	await process_frame
	director.play_boombox()
	if director.current_track != 3 or not director.player.playing:
		push_error("The bedroom boombox did not start track 3")
		failures += 1
	preload("res://scripts/city_progress.gd").reset()
	change_scene_to_file("res://scenes/level_0.tscn")
	await process_frame
	await process_frame
	if director.current_track != 3:
		push_error("Level 0 reveal did not use cutscene music")
		failures += 1
	current_scene.call("_tick_world_reveal", 9.0)
	if director.current_track != 1:
		push_error("Level 0 race did not switch to track 1")
		failures += 1
	print("MUSIC ROUTING: ", failures, " failures")
	quit(1 if failures else 0)
