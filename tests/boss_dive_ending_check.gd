extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	preload("res://scripts/city_progress.gd").reset()
	change_scene_to_file("res://scenes/bossfight.tscn")
	await process_frame
	await process_frame
	var boss := current_scene
	var player := boss.player as MovementTestPlayer
	assert(boss.rival.entrail_lifetime_seconds == 1.0)
	boss.rival._update_entrail_trails()
	assert(boss.rival._entrail_paths[0].size() > 0)
	boss._process(1.1)
	assert(boss.rival._entrail_paths[0].is_empty(), "Boss entrails expire even when the shadow stops moving")
	assert(boss._hud_health.max_value == 2.0, "Boss health shows two hits")
	boss._begin_chase_cycle()
	boss._begin_wait_for_approach()
	player.global_position = boss.rival.global_position + Vector3(0.0, 0.0, 7.0)
	player._begin_dive(Vector3.FORWARD)
	boss._process(0.016)
	assert(boss.phase == "QTE" and not player.is_physics_processing())
	assert(player.state not in ["DIVING", "DIVE_LANDING"], "QTE clears the active dive")
	boss._begin_player_ram()
	boss._begin_enemy_launch()
	boss._finish_enemy_launch()
	assert(boss.phase == "CHASE" and player.is_physics_processing())
	assert(player.state not in ["DIVING", "DIVE_LANDING"], "Player can move after winning a dive QTE")
	boss._begin_qte()
	boss._begin_shadow_ram()
	boss._recover_after_failure()
	assert(boss.phase == "CHASE" and player.is_physics_processing())
	boss._begin_qte()
	boss._begin_player_ram()
	boss._begin_enemy_launch()
	boss._finish_enemy_launch()
	assert(boss.phase == "WIN" and boss.successful_hits == 2)
	boss._process(boss.RESULTS_PAUSE + 0.1)
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/boss_victory_portal.tscn", "Boss win opens the tape and portal cutscene")
	current_scene.set_process(false)
	current_scene._process(8.4)
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/final_ending.tscn", "Portal cutscene opens the ending")
	assert(current_scene.phase == "choice", "Ending choice is available")
	var music := root.get_node("MusicDirector")
	assert(music.current_track == 3)
	current_scene._choose_ending(true)
	current_scene.phase_time = 6.684
	current_scene._process(0.016)
	assert(music.current_track == 0, "Boombox smash cuts the music")
	current_scene.phase_time = 28.984
	current_scene._process(0.016)
	assert(music.current_track == 3, "Good ending restores the music in the world")
	print("BOSS DIVE AND ENDING: passed")
	quit()
