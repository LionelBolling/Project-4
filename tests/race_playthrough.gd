extends "res://tests/first_person_check.gd"

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.muted = true
	game.ambience.stop()
	game.bedroom.hide()
	game.start_real_race()
	key(KEY_W, true)
	var jumping_from = -1
	for i in range(3600):
		if game.state == "result": break
		if game.qte_time > 0: key(game.qte_key, true)
		var distance = -game.player.position.z
		var index = game.tile_at(distance)
		if game.player.is_on_floor():
			key(KEY_SPACE, false)
			jumping_from = -1
			if index >= 1 and distance > game.platforms[index].end - 5:
				jumping_from = index
				key(KEY_SPACE, true)
		elif jumping_from >= 0 and distance > game.platforms[jumping_from].end + 4:
			key(KEY_SPACE, false)
		key(KEY_SHIFT, index >= 0 and game.platforms[index].slope < 0 and game.player.is_on_floor())
		await tick(1)
	key(KEY_W, false)
	key(KEY_SPACE, false)
	key(KEY_SHIFT, false)
	check(game.state == "result" and game.won, "Full race must be winnable with actual movement: " + str(game.player.position))
	print("RACE PLAYTHROUGH: ", failures, " failures / time ", game.elapsed, " / rival ", game.ghost_distance)
	quit(1 if failures else 0)
