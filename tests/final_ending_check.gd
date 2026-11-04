extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var boss = load("res://scenes/bossfight.tscn").instantiate()
	root.add_child(boss)
	await process_frame
	boss.set_process(false)
	assert(boss.rival.visual.visible, "The real boy keeps his original neon character model")
	boss.queue_free()
	await process_frame
	var ending = load("res://scenes/final_ending.tscn").instantiate()
	root.add_child(ending)
	current_scene = ending
	await process_frame
	ending.set_process(false)
	assert(ending.phase == "choice" and ending.choice_panel.visible)
	ending._process(5.0)
	assert(ending.phase_time == 0.0, "Wait for a choice before entering the portal")
	ending._choose_ending(false)
	for time in [0.0, 0.6, 1.5, 3.3, 5.5, 6.2, 6.7, 7.2, 8.5, 12.0, 16.5, 18.4, 18.5, 18.8, 20.0, 20.49, 20.51, 21.7, 23.5, 25.0, 26.0, 29.0, 31.0, 34.0, 37.0]:
		ending.phase_time = time - 0.016
		ending._process(0.016)
		await process_frame
		if time == 0.6:
			assert(ending.revealed_body.visible, "The escaping character is exposed as the same shadow")
			assert(ending.static_material.get_shader_parameter("strength") == 0.0, "Escape does not imply a new body swap")
		if time == 7.2:
			assert(ending.prison.visible and ending.prison_portal.scale.length() < 0.01, "Smash immediately seals the portal")
		if time == 26.0:
			assert(ending.captive_body.visible and ending.neon_shadow.visible, "The neon body gradually morphs back into the boy")
			assert(ending.ending_city.rings[0].visible)
		if time >= 16 and time < 23:
			assert(ending.bedroom_model.visible or ending.revealed_body.visible, "Actual character body remains visible in bed")
			assert(ending.camera.global_position.distance_to(ending.walker.global_position) > 3, "Third-person bed camera")
		if time == 20.49:
			assert(ending.revealed_body.visible and not ending.laugh_played, "Neon body stays for two seconds before the laugh")
		if time == 21.7:
			assert(ending.static_material.get_shader_parameter("strength") == 0.0, "Static ends after one transition")
		if time == 20.49:
			assert(ending.revealed_body.visible and not ending.laugh_played, "Neon body stays for two seconds before the laugh")
		if time == 21.7:
			assert(ending.bedroom_model.visible and not ending.revealed_body.visible, "Normal body returns before the laugh")
			assert(ending.laugh_played, "Laugh follows the reveal")
		if time == 25.0:
			assert(ending.prison_portal.scale.length() < 0.01, "Portal closes in 0.55 seconds")
	assert(ending.impact_played and ending.sigh_played)
	assert(not ending.boombox.visible)
	assert(ending.captive_body.position.z > 0)
	assert(not ending.neon_shadow.visible and ending.captive_body.visible, "The restored boy walks into the city")
	assert(ending.trapped_player.visible, "The boy remains recognizable as he walks away")
	ending.phase_time = 42.1
	ending._process(0.016)
	assert(ending.ending_card.text == "Bad Ending" and ending.ending_card.visible)
	ending._process(4.1)
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/title_screen.tscn", "Automatically returns to title")
	var good = load("res://scenes/final_ending.tscn").instantiate()
	root.add_child(good)
	await process_frame
	good.set_process(false)
	good._choose_ending(true)
	for time in [1.0, 5.0, 6.7, 7.2, 8.5, 12.0, 19.0, 21.0, 24.0, 26.0, 28.6, 34.0, 42.1]:
		good.phase_time = time - 0.016
		good._process(0.016)
		if time == 1.0:
			assert(good.revealed_body.visible and not good.bedroom_model.visible)
		if time == 7.2:
			assert(good.prison_portal.scale.length() < 0.01)
		if time == 19.0 or time == 21.0:
			assert(good.bedroom_model.visible and not good.revealed_body.visible)
			assert(not good.laugh_played)
		if time == 24.0:
			assert(good.captive_body.visible and not good.neon_shadow.visible)
		if time == 26.0:
			assert(good.captive_body.visible and good.neon_shadow.visible, "Both rigs blend during the four-second phase")
			var meshes = good.neon_shadow.find_children("*", "MeshInstance3D", true, false)
			assert(meshes[0].transparency > 0.0 and meshes[0].transparency < 1.0)
			assert(good.ending_city.rings[0].visible)
		if time == 28.6:
			assert(not good.captive_body.visible and good.neon_shadow.visible)
		if time == 34.0:
			assert(good.neon_shadow.position.z > 0)
	assert(good.ending_card.text == "Good Ending" and good.ending_card.visible)
	print("FINAL ENDING CHECK PASSED")
	quit()
