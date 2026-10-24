extends SceneTree

var game: Node3D
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func key(code: int, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	if pressed: game._unhandled_key_input(event)

func tick(count: int) -> void:
	for i in range(count):
		game._physics_process(1.0 / 60.0)
		await physics_frame

func settle() -> void:
	for i in range(8):
		game.player.velocity.y = -1
		game.player.move_and_slide()
		await physics_frame

func screenshot(name: String) -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/" + name + ".png")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.muted = true
	game.ambience.stop()
	check(game.state == "sleep", "Game must open in bed, without skipping the intro")
	await screenshot("fp-bedroom")
	await tick(470)
	check(game.blink_count == 3 and game.state == "wake", "Exactly three blinks precede the other world")
	await tick(181)
	check(game.state == "explore", "Waking must enable exploration")
	await settle()
	game.update_camera(0.016)
	await screenshot("fp-arrival")
	var start = game.player.position
	key(KEY_W, true)
	await tick(30)
	key(KEY_W, false)
	check(game.player.position.z < start.z - 1, "First-person forward movement must work")
	game.player.position = game.tape.position + Vector3(0, 0, 0.4)
	await tick(1)
	check(game.state == "encounter" and game.shadow.visible, "Touching the tape must release the double")
	await tick(105)
	check(game.scare_played, "Encounter must trigger the scream")
	await screenshot("fp-scare")
	await tick(98)
	check(game.state == "forced_turn", "Scream must lead to a forced turn")
	check(absf(game.yaw) > 1, "Encounter must turn the view away from the track before forcing it back")
	await tick(166)
	check(game.state == "tutorial" and game.tutorial_waiting, "Forced run must stop at the first lesson")
	check(game.elapsed == 0, "Race timer cannot run during intro")
	await screenshot("fp-tutorial")
	var frozen = game.player.position
	await tick(30)
	check(game.player.position == frozen and game.tutorial_step == 0, "Instruction screen freezes movement and cannot auto-complete")
	key(KEY_ENTER, true)
	key(KEY_W, true)
	await tick(100)
	key(KEY_W, false)
	check(0 in game.completed_lessons, "Walking lesson must complete through physical movement")
	# A failed gap restores the practice checkpoint instead of starting the race.
	game.enter_lesson(1)
	game.begin_lesson_attempt()
	game.player.position.y = -10
	await tick(1)
	check(game.tutorial_waiting and game.tutorial_step == 1 and game.state == "tutorial", "A fall must retry the same lesson")
	game.enter_lesson(6)
	game.begin_lesson_attempt()
	game.resolve_qte(false)
	check(game.state == "tutorial" and game.tutorial_waiting, "Wrong QTE cannot pass the final lesson")
	game.begin_lesson_attempt()
	await tick(125)
	check(game.state == "tutorial" and game.tutorial_waiting, "Timed-out tutorial QTE must retry")
	# Check success dispatch independently of input timing.
	game.completed_lessons.assign([0, 1, 2, 3, 4, 5])
	game.begin_lesson_attempt()
	key(game.qte_key, true)
	check(game.state == "countdown" and game.completed_lessons.size() == 7, "Successful final lesson unlocks the countdown")
	await tick(183)
	check(game.state == "race", "Countdown must begin the real race")
	var before = game.ghost_distance
	await tick(60)
	check(game.ghost_distance - before > 13.5, "Rival must become competitive after training")
	check(game.elapsed > 0, "Race clock must start only in live race")
	game.update_camera(0.016)
	check(game.camera.position.distance_to(game.player.position + Vector3(0, 1.66, 0)) < 0.1, "Camera must stay at first-person eye level")
	check(game.arms.visible and not game.player_visual.visible, "Visible arms must replace the third-person body")
	await screenshot("fp-race")
	game.player.position.z = -game.FINISH
	await tick(1)
	check(game.state == "result" and game.won, "Exit must win the race")
	game.begin_sleep()
	check(game.state == "sleep" and game.blink_count == 0 and game.completed_lessons.is_empty(), "Restart must reset the whole story")
	print("FIRST PERSON CHECK: ", failures, " failures")
	quit(1 if failures else 0)
