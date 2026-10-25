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
	Input.flush_buffered_events()

func tick(count: int) -> void:
	for i in range(count):
		game._physics_process(1.0 / 60.0)
		await physics_frame

func tap(code: int) -> void:
	key(code, true)
	key(code, false)

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

func face(target: Vector3) -> void:
	game.update_camera(0.016)
	game.camera.look_at(target)
	game.yaw = game.camera.rotation.y
	game.pitch = game.camera.rotation.x
	game.opening_sequence.update_interaction()
	game.update_ui()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.muted = true
	game.ambience.stop()
	check(game.state == "room_entry", "Opening must enter the bedroom from the hallway")
	var locked = game.camera.position
	tap(KEY_E)
	key(KEY_W, true)
	await tick(30)
	key(KEY_W, false)
	check(game.state == "room_entry", "Input must not skip the entrance cutscene")
	check(game.camera.position != locked, "Entrance camera must move into the room")
	await tick(215)
	check(game.state == "bedroom", "Entrance must release control in the bedroom")
	await screenshot("fp-bedroom")
	await tick(180)
	check(game.state == "bedroom", "Going to bed must require interaction")
	tap(KEY_E)
	check(game.state == "bedroom", "E out of range must not activate the bed")
	game.player.position = Vector3(1001.25, 0.1, -2.7)
	await settle()
	face(Vector3(1001.25, 2.25, -5.02))
	check(game.opening_sequence.interaction().get("id") == "tv", "TV should be interactable when aimed at")
	tap(KEY_E)
	check(not game.opening_sequence.tv_on, "E should switch the TV off")
	tap(KEY_E)
	check(game.opening_sequence.tv_on, "E should switch the TV back on")
	# Walk toward the bed from its foot; do not teleport through furniture.
	game.player.position = Vector3(998, 0.1, 3.6)
	await settle()
	game.yaw = 0
	key(KEY_W, true)
	await tick(15)
	key(KEY_W, false)
	check(game.player.position.z < 3.2, "Bedroom movement must work with collision")
	face(Vector3(997.35, 0.9, 0.8))
	check(game.interaction_text.contains("GO TO BED"), "Bed prompt must show E to go to bed")
	await screenshot("fp-bed-objective")
	tap(KEY_E)
	check(game.state == "sleep", "E at the bed must begin the sleep cutscene")
	await tick(447)
	check(game.blink_count == 3 and game.state == "wake", "Three blinks must lead into the destroyed world")
	await tick(250)
	await screenshot("fp-destroyed-look")
	await tick(143)
	check(game.state == "explore", "Look-around must release control")
	check(not game.tape_revealed, "Tape reveal must wait for forward exploration")
	check(game.opening_sequence.floating_fragments.size() >= 32, "Destroyed world must contain floating land")
	await settle()
	game.yaw = 0
	game.pitch = 0
	key(KEY_W, true)
	await tick(40)
	check(game.state == "explore", "Small forward movement should not immediately start abduction")
	await tick(20)
	key(KEY_W, false)
	check(game.state == "tape_reveal", "Walking far enough should trigger a separate tape reveal")
	await tick(143)
	await screenshot("fp-tape-reveal")
	await tick(145)
	check(game.state == "explore" and game.tape_revealed, "Tape reveal must return control before interaction")
	game.player.position = game.tape.position + Vector3(0, 0, 1.7)
	await settle()
	face(game.tape.position)
	await tick(20)
	check(game.state == "explore", "Standing beside the tape must not trigger it automatically")
	check(game.interaction_text.contains("TAPE"), "Tape must have an E interaction prompt")
	tap(KEY_E)
	check(game.state == "tape_grab", "E must trigger tape abduction")
	await tick(64)
	check(game.scare_played and game.opening_sequence.tape_hand.visible, "A hand must emerge from the tape")
	await screenshot("fp-tape-hand")
	await tick(144)
	check(game.state == "track_wake", "Tape must pull the player into the track awakening")
	check(game.elapsed == 0, "Race timer cannot run during cutscenes")
	await tick(195)
	check(game.state == "race_flyover", "Track awakening must lead into the goal flyover")
	await tick(575)
	check(game.opening_sequence.sleeper.visible, "Portal must show the sleeping player")
	await screenshot("fp-sleeper-portal")
	await tick(420)
	check(game.state == "ghost_taunt", "Flyover must return to the ghost")
	await tick(90)
	check(game.opening_sequence.laughed, "Ghost must laugh before the chase")
	await screenshot("fp-ghost-laugh")
	await tick(130)
	check(game.state == "race", "Ghost laugh must lead straight into the race")
	check(game.elapsed > 0, "Race clock must start immediately when the chase begins")
	var start = game.player.position
	await settle()
	key(KEY_W, true)
	await tick(60)
	key(KEY_W, false)
	var moved = start.z - game.player.position.z
	check(moved > 10.0, "Chase must use full-speed movement: " + str(moved))
	var frozen_camera = game.camera.position
	var frozen_time = game.elapsed
	tap(KEY_ESCAPE)
	await tick(60)
	check(game.state == "paused" and game.camera.position == frozen_camera and game.elapsed == frozen_time, "Pause must suspend the race and camera")
	tap(KEY_ESCAPE)
	check(game.state == "race", "Resume must restore the race")
	game.qte_time = 2
	game.qte_key = KEY_E
	tap(game.qte_key)
	check(game.qte_time == 0 and game.boost > 0 and game.state == "race", "E must still work as a takeover key during the race")
	game.qte_time = 0.01
	await tick(2)
	check(game.qte_time == 0 and game.slow > 0 and game.state == "race", "Failed takeover must slow the player without entering a lesson")
	var before = game.ghost_distance
	await tick(60)
	check(game.ghost_distance - before > 13.5, "Full-speed rival must remain competitive")
	check(game.elapsed > 0, "Race clock must advance after focus ends")
	game.update_camera(0.016)
	check(game.camera.position.distance_to(game.player.position + Vector3(0, 1.66, 0)) < 0.1, "Camera must return to eye level")
	check(game.arms.visible and not game.player_visual.visible, "First person must use camera hands")
	await screenshot("fp-race")
	game.player.position.z = -game.FINISH
	await tick(1)
	check(game.state == "result" and game.won, "Reaching the portal must win")
	game.begin_sleep()
	check(game.state == "room_entry" and game.blink_count == 0, "Restart must reset the whole opening")
	check(not game.tape_revealed and not game.opening_sequence.tape_hand.visible, "Restart must reset tape reveal and hide abduction hand")
	print("FIRST PERSON CHECK: ", failures, " failures")
	quit(1 if failures else 0)
