extends SceneTree

var failures = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_physics_process(false)
	var env = game.environment
	check(is_equal_approx(env.surface_speed(15.5, 1, true, false), 21.5), "Boost surface")
	check(is_equal_approx(env.surface_speed(15.5, 2, true, false), 12.09), "Rough surface")
	check(env.surface_speed(15.5, 1, false, false) == 15.5, "No airborne boost")
	check(env.surface_speed(15.5, 999, true, false) == 15.5, "Invalid index")
	game.player.position = Vector3(0, 0.05, -25)
	for i in range(12):
		game.player.velocity = Vector3(0, -2, 0)
		game.player.move_and_slide()
		await physics_frame
	check(env.floor_platform() == 1, "Detect actual boost floor contact")
	game.player.position = Vector3(30, 0, -25)
	game.player.velocity = Vector3(0, -2, 0)
	game.player.move_and_slide()
	check(env.floor_platform() == -1, "No effect off the course")
	game.player.position = Vector3(0, -1.15, -75)
	for i in range(12):
		game.player.velocity = Vector3(0, -2, 0)
		game.player.move_and_slide()
		await physics_frame
	check(env.floor_platform() == 3, "Detect fragile floor contact")
	env.react_to_landing(3, 5)
	check(game.platforms[3].collapse < 0, "Gentle landing survives")
	env.react_to_landing(3, 15)
	check(game.platforms[3].collapse > 0, "Hard landing starts collapse")
	env.reset_platforms()
	env.corrupt_platform(1)
	check(is_equal_approx(env.surface_speed(15.5, 1, true, false), 12.09), "Corruption replaces boost")
	check(not game.platforms[0].corrupt, "Corruption is isolated")
	env.corrupt_platform(3)
	env.tick_platforms(0.4)
	var remaining = game.platforms[3].collapse
	env.corrupt_platform(3)
	check(game.platforms[3].collapse == remaining, "Repeated corruption keeps countdown")
	env.tick_platforms(0.6)
	await physics_frame
	check(game.platforms[3].col.disabled, "Collapsed collision disabled")
	check(game.platforms[3].body.position.y < game.platforms[3].home.y, "Platform falls")
	env.tick_platforms(100)
	check(is_equal_approx(game.platforms[3].body.position.y, game.platforms[3].home.y - 40), "Fall is bounded")
	game.reset_race()
	await physics_frame
	check(not game.platforms[3].col.disabled, "Restart restores collision")
	check(not game.platforms[1].corrupt and game.platforms[3].collapse < 0, "Restart restores state")
	check(game.platforms[3].body.position == game.platforms[3].home, "Restart restores transform")
	check(game.platforms[1].edge_mat.albedo_color == game.platforms[1].edge_color, "Restart restores visuals")
	print("ENVIRONMENT CHECK: ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

