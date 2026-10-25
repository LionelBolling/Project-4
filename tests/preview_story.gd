extends "res://tests/first_person_check.gd"
## Render story checkpoints without replaying the full opening.
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.muted = true
	game.ambience.stop()
	game.phase_time = 4.1
	game.opening_sequence.tick(0.016)
	game.update_ui()
	await screenshot("story-bedroom")
	game.wake_up()
	game.phase_time = 3.4
	game.opening_sequence.tick(0.016)
	game.update_ui()
	await screenshot("story-destroyed")
	game.state = "explore"
	game.tape_revealed = true
	game.player.position = game.tape.position + Vector3(0, 0, 1.7)
	face(game.tape.position)
	game.trigger_tape()
	game.phase_time = 1.08
	game.opening_sequence.tick(0.016)
	game.update_ui()
	await screenshot("story-grabbing-hand")
	game.opening_sequence.begin_race_intro()
	game.veil.color.a = 0
	game.opening_sequence.change_phase("race_flyover")
	game.phase_time = 10.8
	game.opening_sequence.tick(0.016)
	game.update_ui()
	# A few frames allow the separate bedroom viewport to render before capture.
	for i in range(5): await process_frame
	await screenshot("story-portal")
	game.camera.position = Vector3(0, 1.76, -3)
	game.opening_sequence.change_phase("ghost_taunt")
	game.phase_time = 1.4
	game.opening_sequence.tick(0.016)
	game.update_ui()
	await screenshot("story-laugh")
	game.start_real_race()
	game.update_camera(0.016)
	game.update_ui()
	await screenshot("story-race")
	print("STORY PREVIEW: captured bedroom, destroyed world, hand, portal, laugh and race")
	quit()
