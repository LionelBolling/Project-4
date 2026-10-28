extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var story = load("res://scenes/rewind.tscn").instantiate()
	root.add_child(story)
	await process_frame
	check(story.phase == "room_entry", "Starts with room entry cutscene")
	story.phase_time = 5.6
	story._tick_room_entry(0.016)
	check(story.phase == "bedroom", "Entry cutscene hands over movement")
	check(story.boombox != null and story.cassette != null, "Bedroom story props exist")
	check(story.bedroom_model.visible, "Third person bedroom model visible")
	check(story.camera.position.distance_to(story.walker.position) > 3, "Bedroom camera stays outside character")
	check(story.controls.text.is_empty(), "Opening has no control list")
	story.walker.position = Vector3(1.4, 0.05, -2.5)
	check(story._can_touch_boombox(), "Interaction uses character proximity")
	story._begin_abduction()
	check(story.phase == "portal", "Interaction starts forced abduction")
	story.phase_time = 1.8
	story._tick_abduction(0.016)
	check(story.walker.position.y > 0.4, "Abduction lifts the character off the floor")
	check(story.pull_strands[0].visible, "Abduction force visibly connects object and character")
	story.start_round(1)
	await physics_frame
	var race = story.stage
	check(race.has_node("StoryCourse"), "Campaign course attached")
	check(race.get_node("StoryCourse").surfaces.size() == 21, "Segmented floating course reaches finish")
	race._start_race()
	Input.action_press("move_forward")
	for frame in range(180):
		if frame % 40 == 0: race.player.jump_buffer = 0.16
		await physics_frame
	Input.action_release("move_forward")
	check(race.player.position.z < 5, "Existing movement traverses the campaign course")
	race.player.velocity = Vector3(0, 0, -10)
	race.player.apply_story_qte(false)
	check(is_equal_approx(race.player.velocity.z, -8.5), "Failed QTE reduces momentum by fifteen percent")
	race.player.apply_story_qte(true)
	check(is_equal_approx(race.player.story_boost_time, 5), "Successful QTE lasts five seconds")
	race._finish_race(false)
	check(story.round_number == 1, "Loss keeps current round")
	race._restart_race()
	check(race.player.story_boost_time == 0, "Retry clears boost")
	for number in range(1, 4):
		check(story.round_number == number, "Correct round sequence")
		story.stage._finish_race(true)
		await process_frame
		await process_frame
		check(story.phase == "between", "Victory starts visual tape clue")
		story.phase_time = 7.1
		story._process(0.01)
		await process_frame
	check(story.phase == "boss", "Three races lead to final round")
	story.stage.successful_hits = 4
	story.stage._finish_enemy_launch()
	await process_frame
	await process_frame
	check(story.phase == "ending", "Boss victory leads to ending")
	# Exercise each cinematic shot without requiring a manual playthrough.
	for t in [2.0, 4.0, 5.99, 6.0, 7.0, 9.0, 12.0, 15.0, 17.0]:
		story.phase_time = t
		story._process(0.02)
	check(story.phase == "complete", "Ending completes")
	check(story.prisoner.visible and story.reflection.visible, "Identity reveal shown")
	check(story.cassette.get_parent() == story.boombox, "Tape returned to boombox")
	print("REWIND CHECK: %d failures" % failures)
	story.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
