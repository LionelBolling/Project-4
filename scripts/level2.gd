@tool
extends "res://scripts/runner_race_scene.gd"
## Campaign parkour race, also playable directly with F6.
const Course = preload("res://scripts/story_course.gd")
const LENGTH_MULTIPLIER := 5.0
const WIDTH_MULTIPLIER := 1.6
const PARKOUR_SECTIONS := 24
const CHANGING_WALL_COUNT := 72
var changing_walls: Array[Dictionary] = []
var wall_rng := RandomNumberGenerator.new()
var wall_clock := 0.0

func _init() -> void:
	set_meta("story_round", 2)
	wall_rng.seed = 22026

func _build_track() -> void:
	super._build_track()
	if has_node("Level2Parkour"): return
	# Extend actual geometry and colliders instead of scaling physics bodies.
	for node in get_node("CourseGeometry").get_children():
		if node is Node3D:
			node.position.x *= WIDTH_MULTIPLIER
			node.position.z = START_Z + (node.position.z - START_Z) * LENGTH_MULTIPLIER
		if node is StaticBody3D:
			var visual := node.get_node("Mesh") as MeshInstance3D
			var collision := node.get_node("CollisionShape3D") as CollisionShape3D
			(visual.mesh as BoxMesh).size *= Vector3(WIDTH_MULTIPLIER, 1, LENGTH_MULTIPLIER)
			(collision.shape as BoxShape3D).size *= Vector3(WIDTH_MULTIPLIER, 1, LENGTH_MULTIPLIER)
		elif node is MeshInstance3D and node.mesh is BoxMesh:
			node.mesh.size.x *= WIDTH_MULTIPLIER
			# Long stripes extend with the course, gate posts retain their depth.
			if "Stripe" in str(node.name): node.mesh.size.z *= LENGTH_MULTIPLIER
	var obstacles := Node3D.new()
	obstacles.name = "Level2Parkour"
	add_child(obstacles)
	_assign_owner(obstacles)
	var blue := _material(Color("3469a3"), 0.4)
	var gold := _material(Color("efb86b"), 0.5)
	# Alternating stair routes: jump up, cross the gap, then glide back down.
	for section in range(PARKOUR_SECTIONS):
		var side := -1.0 if section % 2 == 0 else 1.0
		var z := -24.0 - section * 40
		for step in range(3):
			var height := 0.55 + step * 0.55
			_add_solid(obstacles, "Step_%d_%d" % [section, step], Vector3(side * 3.8, height / 2, z - step * 2.8), Vector3(3.4, height, 2.4), blue)
		_add_solid(obstacles, "Landing_%d" % section, Vector3(side * 3.8, 0.85, z - 12), Vector3(3.4, 1.7, 3), gold)
		# Low staggered hurdles leave an alternate lane for speed runners.
		_add_solid(obstacles, "Hurdle_%d" % section, Vector3(-side * 3.3, 0.55, z - 17), Vector3(4.0, 1.1, 0.7), gold)
	# Side walls rise and shrink independently, with identical visual/collision
	# dimensions. A clear middle lane always remains available.
	for i in range(CHANGING_WALL_COUNT):
		var height := wall_rng.randf_range(1.1, 4.8)
		var x := -6.8 if i % 2 == 0 else 6.8
		_add_solid(obstacles, "ChangingWall_%02d" % i, Vector3(x, height / 2, -12 - i * 13.5), Vector3(0.45, height, 10), _material(Color("8756bc"), 0.7))
		var body := obstacles.get_child(obstacles.get_child_count() - 1) as StaticBody3D
		var target := wall_rng.randf_range(5.5, 8.0) if height < 3.0 else wall_rng.randf_range(0.5, 1.2)
		changing_walls.append({"body": body, "height": height, "start": height, "target": target, "elapsed": 0.0, "duration": wall_rng.randf_range(1.5, 2.8), "home": height})

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint(): return
	var course := Course.new()
	course.name = "StoryCourse"
	course.first_encounter_delay = 1.5
	course.encounter_interval = 2.0
	course.segment_count = 101
	course.course_width = 9.3 * WIDTH_MULTIPLIER
	add_child(course)
	rival.run_speed = 7.8
	rival.finish_z = _finish_position()
	player.camera.far = 1600
	player_status_label.text = "Space jump / hold glide   Shift dive   Q E R F counter"
	player.status_label = null
	# Correct the inherited HUD instructions for this scene's campaign controls.
	for label in find_children("*", "Label", true, false):
		if str(label.text).begins_with("WASD run"):
			label.text = "WASD move   Mouse camera   Space jump / hold glide   Shift dive"
		if label.text == "NEON RACE": label.text = "LEVEL 2 / PARKOUR"

func _finish_position() -> float:
	return START_Z + (FINISH_Z - START_Z) * LENGTH_MULTIPLIER

func _build_lighting() -> void:
	super._build_lighting()
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.background_mode = Environment.BG_COLOR
			child.environment.background_color = Color("080c21")
			child.environment.glow_intensity = 0.45
			child.environment.glow_strength = 0.6
			child.environment.glow_bloom = 0.02
			child.environment.glow_hdr_threshold = 1.6

func _physics_process(dt: float) -> void:
	if Engine.is_editor_hint() or race_state not in ["COUNTDOWN", "RACING"]: return
	wall_clock += dt
	for wall in changing_walls:
		wall.elapsed += dt
		if wall.elapsed >= wall.duration:
			wall.start = wall.height
			# Alternate tall and short targets so each wall clearly rises AND
			# falls, instead of occasionally picking almost the same height.
			wall.target = wall_rng.randf_range(0.5, 1.2) if wall.height > 3.0 else wall_rng.randf_range(5.5, 8.0)
			wall.duration = wall_rng.randf_range(1.5, 2.8)
			wall.elapsed = 0.0
		wall.height = lerpf(wall.start, wall.target, smoothstep(0, 1, wall.elapsed / wall.duration))
		_set_wall_height(wall, wall.height)

func _set_wall_height(wall: Dictionary, height: float) -> void:
	var body: StaticBody3D = wall.body
	body.position.y = height / 2
	var mesh := body.get_node("Mesh") as MeshInstance3D
	(mesh.mesh as BoxMesh).size.y = height
	var collision := body.get_node("CollisionShape3D") as CollisionShape3D
	(collision.shape as BoxShape3D).size.y = height

func _finish_race(player_won: bool) -> void:
	super._finish_race(player_won)
	# Use the results delay before advancing on a win or retrying on a loss.
	race_state = "FINISHED"
	finish_label.text = "YOU WIN" if player_won else "TRY AGAIN"

func _next_scene_path() -> String:
	return "res://scenes/level_3_beta.tscn"

func _restart_race() -> void:
	super._restart_race()
	wall_clock = 0
	wall_rng.seed = 22026
	for wall in changing_walls:
		wall.height = wall.home
		wall.start = wall.home
		wall.target = wall_rng.randf_range(5.5, 8.0) if wall.home < 3.0 else wall_rng.randf_range(0.5, 1.2)
		wall.elapsed = 0.0
		_set_wall_height(wall, wall.home)
