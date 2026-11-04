extends SceneTree
const Progress = preload("res://scripts/city_progress.gd")
func _initialize() -> void:
	call_deferred("run")
func wait_travel() -> void:
	for frame in range(360):
		await process_frame
		if not Progress.transitioning:
			await process_frame
			return
	assert(false, "Campaign scene transition completes")
func open_scene(path: String) -> void:
	change_scene_to_file(path)
	await process_frame
	await process_frame
	await physics_frame
func enter_tape(city: Node) -> void:
	city.set_process(false)
	city._set_control(false)
	city.phase = "EXPLORE"
	city.player.position = city.piece_home - Vector3.UP * 1.1
	city._interact()
	assert(city.phase == "VANISH")
	city.time = 1.8
	city._tick_vanish()
	await wait_travel()
func run() -> void:
	Progress.reset()
	Progress.active = true
	Progress.arrived = true
	Progress.piece_index = 3
	assert(Progress.LEVELS[4] == "res://scenes/level_4.tscn")
	assert(Progress.LEVELS[5] == "res://scenes/boss_cutscene_start.tscn")
	await open_scene(Progress.LEVELS[3])
	var level = current_scene
	level.set_process(false)
	level._finish_race(true)
	level._process(3.1)
	await wait_travel()
	var city = current_scene
	assert(city.scene_file_path == Progress.HUB)
	assert(Progress.piece_index == 4 and Progress.health == 100)
	assert(city.PIECES.size() == Progress.LEVELS.size())
	assert(city.has_node("ActivePiece") and not city.has_node("HomeWindow"))
	await enter_tape(city)
	level = current_scene
	assert(level.scene_file_path == "res://scenes/level_4.tscn")
	level.set_process(false)
	level._finish_race(false)
	assert(Progress.health == 75 and Progress.piece_index == 4)
	Progress.fail_race(self)
	assert(Progress.health == 75, "One loss deducts health once")
	await wait_travel()
	city = current_scene
	assert(city.phase == "EJECTED")
	city.set_process(false)
	city.time = 1.3
	city._tick_ejection()
	assert(city.phase == "EXPLORE")
	await enter_tape(city)
	level = current_scene
	assert(level.scene_file_path == "res://scenes/level_4.tscn")
	assert(Progress.health == 75 and Progress.piece_index == 4)
	level.set_process(false)
	level._finish_race(true)
	level._process(3.1)
	await wait_travel()
	city = current_scene
	assert(Progress.piece_index == 5 and Progress.health == 75)
	assert(city.has_node("ActivePiece") and city.has_node("HomeWindow"))
	await enter_tape(city)
	assert(current_scene.scene_file_path == "res://scenes/boss_cutscene_start.tscn")
	print("LEVEL 4 CAMPAIGN CHECK: Level 3 win -> Level 4 -> loss/ejection/75 health -> retry -> win -> boss")
	Progress.reset()
	quit()
