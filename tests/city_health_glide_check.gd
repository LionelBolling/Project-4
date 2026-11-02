extends SceneTree
const Progress = preload("res://scripts/city_progress.gd")
var visual := false

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	if not visual: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/revision-%s.png" % name)

func wait_travel() -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while Progress.transitioning:
		assert(Time.get_ticks_msec() < deadline, "Scene transition completes")
		await process_frame
	await process_frame

func open_scene(path: String) -> void:
	change_scene_to_file(path)
	await process_frame
	await process_frame
	await process_frame

func run() -> void:
	visual = "--visual" in OS.get_cmdline_user_args()
	Progress.reset()
	Progress.arrived = true
	await open_scene(Progress.HUB)
	var city = current_scene
	assert(city.player.movement_hud.health_root.visible)
	assert(city.cars.size() == 24)
	assert(not city.marker_ui.visible, "Far tapes must be searched for")
	assert(absf(city.piece_home.x) > 50, "Wider city distributes tapes across districts")
	await shot("city-health")
	city._set_control(false)
	city.player.position = city.piece_home - Vector3.UP * 1.1
	city._interact()
	city.time = 1.8
	city._tick_vanish()
	await wait_travel()
	var race = current_scene
	assert(race.scene_file_path == Progress.LEVELS[0])
	assert(race.player.movement_hud.health_root.visible)
	race.set_process(false)
	race._finish_race(false)
	assert(Progress.health == 75 and Progress.piece_index == 0)
	Progress.fail_race(self)
	assert(Progress.health == 75, "One failure only deducts health once")
	await wait_travel()
	city = current_scene
	assert(city.phase == "EJECTED", "Race failure kicks player out of tape")
	city.set_process(false)
	city.time = 1.3
	city._tick_ejection()
	assert(city.phase == "EXPLORE")
	await shot("ejected")
	# Short glide: no stun. Long glide: empty warning and landing recovery.
	var player = city.player
	city._set_control(false)
	player.position = Vector3(-12, 30, 10)
	player.velocity = Vector3(0, -0.1, 0)
	player.move_and_slide()
	player.state = "GLIDING"
	player.glide_animation_active = true
	player.glide_used_this_air = true
	player.was_airborne = true
	Input.action_press("glide")
	for i in range(50): player._physics_process(1.0 / 60)
	assert(player.state == "GLIDING" and not player.glide_exhausted and player.glide_timer < 2)
	Input.action_release("glide")
	player._physics_process(1.0 / 60)
	assert(player.glide_timer > 0.8 and player.state != "GLIDING", "Stopping preserves spent energy")
	for i in range(240): player._physics_process(1.0 / 60)
	assert(not player._is_animation_playing("glideLand"), "Short glide has no stun")
	player.position = Vector3(-12, 35, 10)
	player.velocity = Vector3(0, -0.1, 0)
	player.move_and_slide()
	player.state = "GLIDING"
	player.glide_animation_active = true
	player.glide_used_this_air = true
	player.was_airborne = true
	Input.action_press("glide")
	for i in range(121): player._physics_process(1.0 / 60)
	assert(player.glide_exhausted and is_equal_approx(player.glide_timer, 2.0))
	player.set_physics_process(true)
	player.movement_hud._update()
	assert(player.movement_hud.glide_root.visible)
	await shot("glide-empty")
	player.set_physics_process(false)
	Input.action_release("glide")
	player._physics_process(1.0 / 60)
	assert(player.glide_timer == 2.0 and player.glide_exhausted, "Empty energy remains spent until ground contact")
	var stunned := false
	for i in range(240):
		player._physics_process(1.0 / 60)
		if player._is_animation_playing("glideLand"):
			stunned = true
			break
	assert(stunned, "Only exhausted glide stuns on landing")
	player.movement_hud._update()
	assert(not player.movement_hud.glide_root.visible)
	# Easier Level 2 uses actual monster target encounters, not old StoryCourse.
	Progress.piece_index = 2
	await open_scene(Progress.LEVELS[2])
	race = current_scene
	race.set_process(false)
	assert(not race.has_node("StoryCourse"))
	assert(race.changing_walls.size() == 4)
	assert(race.rival.run_speed == 5.2 and not race.rival.rubberband_enabled)
	assert(race.rival.projectile_spawn_chance == 0.2)
	var encounters = race.get_node("MonsterEncounters")
	assert(encounters.active_targets.size() == 2 and encounters.encounter_seconds == 4.0)
	race._start_race()
	race.finish_label.hide()
	var monster = encounters.active_targets[0]
	race.player.position = monster.position + Vector3(0, 0, 6)
	race.player.velocity = Vector3(0, 0, -5)
	encounters._try_begin_qte()
	assert(encounters.phase == "QTE")
	var inspection := Camera3D.new()
	race.add_child(inspection)
	inspection.position = monster.global_position + Vector3(4, 3, 6)
	inspection.look_at(monster.global_position + Vector3.UP)
	inspection.make_current()
	await shot("level2-monster")
	encounters._begin_player_rush()
	encounters._finish_player_rush()
	assert(monster.defeated, "Monster QTE launches real target")
	Engine.time_scale = 1.0
	race._finish_race(false)
	await wait_travel()
	assert(Progress.health == 50 and Progress.piece_index == 2)
	assert(current_scene.phase == "EJECTED")
	# Remaining failure routes share the same ejection and health rules.
	for index in [1, 3, 4]:
		Progress.piece_index = index
		Progress.health = 100
		await open_scene(Progress.LEVELS[index])
		var failed = current_scene
		failed.set_process(false)
		if index == 1:
			failed.shadow.position = failed.finish_line.position
			failed._check_race_finish()
		elif index == 3:
			failed._finish_race(false)
		else:
			failed._recover_after_failure()
		await wait_travel()
		assert(Progress.health == 75 and Progress.piece_index == index)
		assert(current_scene.phase == "EJECTED")
	# Empty health has an explicit retry rather than silently refilling.
	Progress.health = 25
	await open_scene(Progress.LEVELS[0])
	current_scene._finish_race(false)
	await wait_travel()
	city = current_scene
	city.set_process(false)
	city.time = 1.3
	city._tick_ejection()
	assert(Progress.health == 0 and city.phase == "GAME_OVER")
	var retry := InputEventKey.new()
	retry.pressed = true
	retry.physical_keycode = KEY_ENTER
	city._unhandled_input(retry)
	assert(Progress.health == 100 and city.phase == "EXPLORE")
	Progress.reset()
	await open_scene(Progress.LEVELS[0])
	assert(not current_scene.player.movement_hud.health_root.visible, "Health only starts with city campaign")
	print("CITY HEALTH GLIDE LEVEL2 CHECK: passed")
	quit()
