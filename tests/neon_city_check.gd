extends SceneTree
const Progress = preload("res://scripts/city_progress.gd")
var visual := false

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	if not visual: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/city-%s.png" % name)

func run() -> void:
	visual = "--visual" in OS.get_cmdline_user_args()
	Progress.reset()
	var city = load(Progress.HUB).instantiate()
	root.add_child(city)
	current_scene = city
	await process_frame
	city.set_process(false)
	assert(city.phase == "ARRIVAL")
	assert(not city.player.is_physics_processing() and not city.player.is_processing_unhandled_input())
	assert(get_nodes_in_group("city_piece").size() == 1)
	assert(not city.marker.visible)
	for t in [2.0, 5.0, 8.0, 10.8, 12.4, 12.8, 16.0, 18.8]:
		city.time = t
		city._tick_arrival()
		if t == 12.4:
			city.shadow.animation_player.advance(0.35)
			assert(city.shadow.animation_player.current_animation == "CityShove", "Shadow plays two-handed shove")
		await shot(str(t))
	city.time = 20.1
	city._tick_arrival()
	assert(city.phase == "EXPLORE" and city.player.camera.current)
	assert(city.player.is_physics_processing() and city.player.is_processing_unhandled_input())
	assert(city.player.get_script() == load("res://scripts/movement_test_player.gd"))
	assert(not city.marker.visible and city.shadow.visible and city.shadow_state == "RUNNING")
	assert(city.cars.size() == 24)
	city._process(0.0)
	await shot("explore")
	# Existing controller actually jumps in the hub, with its complete move set.
	for i in range(15): await physics_frame
	assert(city.player.is_on_floor())
	city.player.jump_buffer = 0.16
	for i in range(25): await physics_frame
	assert(city.player.position.y > 0.5, "Level jump controller works in city")
	city._set_control(false)
	city.player.position = city.piece_home - Vector3.UP * 1.1
	city._interact()
	assert(city.phase == "VANISH")
	city.time = 0.9
	city._tick_vanish()
	assert(not city.player.visual.visible, "Player vanishes before teleport")
	city.time = 1.4
	city._tick_vanish()
	assert(city.fade.color.a == 1, "Screen goes black before race")
	city.time = 1.8
	city._tick_vanish()
	await wait_travel()
	assert(current_scene.scene_file_path == Progress.LEVELS[0])
	assert(current_scene.race_state == "COUNTDOWN", "Piece opens race against shadow")
	# Exercise each race's actual winning transition, including the Level2 override.
	for index in range(5):
		if index > 0:
			change_scene_to_file(Progress.LEVELS[index])
			await process_frame
			await process_frame
		var race = current_scene
		race.set_process(false)
		if index in [0, 2]:
			race.race_state = "FINISHED"
			race.player_won_race = true
			race.restart_timer = 0
			race._process(0.01)
		elif index == 1:
			race._race_state = "FINISHED"
			race._race_winner = "PLAYER"
			race._win_transition_timer = 0
			race._process(0.01)
		elif index == 3:
			race.race_state = "FINISHED"
			race.player_won_race = true
			race.win_transition_timer = 0
			race._process(0.01)
		else:
			race.phase = "WIN"
			race.restart_timer = 0
			race._process(0.01)
		await wait_travel()
		assert(current_scene.scene_file_path == Progress.HUB, "Win returns to city")
		assert(Progress.piece_index == index + 1)
		assert(current_scene.phase == "EXPLORE", "Arrival only plays once")
		assert(get_nodes_in_group("city_piece").size() == (1 if index < 4 else 0), "Only next piece exists")
	print("NEON CITY CHECK: passed")
	quit()


func wait_travel() -> void:
	while Progress.transitioning: await process_frame
	await process_frame
