@tool
extends "res://scripts/runner_race_scene.gd"
## Campaign parkour race, also playable directly with F6.
const MonsterEncounters = preload("res://scripts/level_1_enemy_manager.gd")
const LENGTH_MULTIPLIER := 1.25
const WIDTH_MULTIPLIER := 1.6
const PARKOUR_SECTIONS := 3
const CHANGING_WALL_COUNT := 4
var changing_walls: Array[Dictionary] = []
var wall_rng := RandomNumberGenerator.new()
var wall_clock := 0.0
var rival_stall_time := 0.0
var rival_progress_z := START_Z
var rival_route: Array[Vector3] = []
var rival_recoveries := 0

func _init() -> void:
	# Use the standard level controls shared with Levels 1 and 3.
	wall_rng.seed = 22026

func _build_track() -> void:
	super._build_track()
	_build_rival_route()
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
	# Keep the top at Y=0 with a substantial, permanent foundation underneath.
	var runway := get_node("CourseGeometry/Raceway") as StaticBody3D
	runway.position.y = -0.6
	(runway.get_node("Mesh").mesh as BoxMesh).size.y = 1.2
	(runway.get_node("CollisionShape3D").shape as BoxShape3D).size.y = 1.2
	var obstacles := Node3D.new()
	obstacles.name = "Level2Parkour"
	add_child(obstacles)
	_assign_owner(obstacles)
	var blue := _material(Color("3469a3"), 0.4)
	var gold := _material(Color("efb86b"), 0.5)
	# Alternating stair routes give both runners real parkour across the course.
	for section in range(PARKOUR_SECTIONS):
		var side := -1.0 if section % 2 == 0 else 1.0
		var z := -24.0 - section * 70
		for step in range(3):
			var height := 0.55 + step * 0.4
			_add_solid(obstacles, "Step_%d_%d" % [section, step], Vector3(side * 3.8, height / 2, z - step * 2.8), Vector3(3.4, height, 2.4), blue)
		_add_solid(obstacles, "Landing_%d" % section, Vector3(side * 3.8, 0.675, z - 12), Vector3(5.0, 1.35, 4), gold)
		# Low staggered hurdles leave an alternate lane for speed runners.
		_add_solid(obstacles, "Hurdle_%d" % section, Vector3(-side * 3.3, 0.11, z - 17), Vector3(3.0, 0.22, 0.7), gold)
	# Side walls rise and shrink independently, with identical visual/collision
	# dimensions. A clear middle lane always remains available.
	for i in range(CHANGING_WALL_COUNT):
		var height := wall_rng.randf_range(0.5, 1.2)
		var x := -6.8 if i % 2 == 0 else 6.8
		_add_solid(obstacles, "ChangingWall_%02d" % i, Vector3(x, height / 2, -12 - i * 13.5), Vector3(0.45, height, 10), _material(Color("8756bc"), 0.7))
		var body := obstacles.get_child(obstacles.get_child_count() - 1) as StaticBody3D
		var target := wall_rng.randf_range(1.1, 1.6) if height < 0.9 else wall_rng.randf_range(0.5, 1.2)
		changing_walls.append({"body": body, "height": height, "start": height, "target": target, "elapsed": 0.0, "duration": wall_rng.randf_range(5.0, 8.0), "home": height})

func _build_rival_route() -> void:
	# Rebuild data even when the editor has already generated the geometry.
	rival_route.clear()
	for section in range(PARKOUR_SECTIONS):
		var side := -1.0 if section % 2 == 0 else 1.0
		var z := -24.0 - section * 70
		rival_route.append(Vector3(side * 3.8, 0, z + 7))
		for step in range(3):
			rival_route.append(Vector3(side * 3.8, 0.55 + step * 0.4, z - step * 2.8))
		rival_route.append(Vector3(side * 3.8, 1.35, z - 13.5))

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint(): return
	_build_monster_encounters()
	rival.run_speed = 2.6
	rival.rubberband_enabled = false
	rival.projectile_spawn_chance = 0.2
	# The Level 2 opponent follows the authored stairs instead of bypassing them.
	rival.story_lane_sway = 0.0
	rival.finish_z = _finish_position()
	player.camera.far = 1600
	player_status_label.text = ""
	player.status_label = null
	# Correct the inherited HUD instructions for this scene's campaign controls.
	for label in find_children("*", "Label", true, false):
		if str(label.text).begins_with("WASD run"):
			label.text = "WASD move   Mouse camera   Space jump   Shift glide   Ctrl dive"
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
	_update_rival_progress(dt)
	wall_clock += dt
	for wall in changing_walls:
		wall.elapsed += dt
		if wall.elapsed >= wall.duration:
			wall.start = wall.height
			# Alternate tall and short targets so each wall clearly rises AND
			# falls, instead of occasionally picking almost the same height.
			wall.target = wall_rng.randf_range(0.5, 1.2) if wall.height > 0.9 else wall_rng.randf_range(1.1, 1.6)
			wall.duration = wall_rng.randf_range(1.5, 2.8)
			wall.elapsed = 0.0
		wall.height = lerpf(wall.start, wall.target, smoothstep(0, 1, wall.elapsed / wall.duration))
		_set_wall_height(wall, wall.height)

func _add_csg_hole(surface: Object, hit_position: Vector3, hole_radius: float) -> void:
	var source := _resolve_race_surface(surface)
	# Wall impacts remain destructible; the structural runway cannot disappear.
	if source != null and source.name == "Raceway": return
	super._add_csg_hole(surface, hit_position, hole_radius)

func _update_rival_progress(dt: float) -> void:
	if race_state != "RACING" or not rival.race_active:
		rival_stall_time = 0.0
		rival_progress_z = rival.position.z
		return
	if rival.position.z < rival_progress_z - 0.5:
		rival_progress_z = rival.position.z
		rival_stall_time = 0.0
	else:
		rival_stall_time += dt
	if rival_stall_time < 2.0 and rival.position.y > -3.0:
		return
	# Recover on the continuous rival floor without advancing down the course.
	var recovery_z := clampf(rival.position.z, _finish_position() + 0.5, START_Z)
	rival_recoveries += 1
	rival.reset_for_race()
	rival.position = Vector3(0.0, 0.05, recovery_z)
	rival.start_race()
	rival_progress_z = recovery_z
	rival_stall_time = 0.0

func _set_wall_height(wall: Dictionary, height: float) -> void:
	var body: StaticBody3D = wall.body
	body.position.y = height / 2
	var mesh := body.get_node("Mesh") as MeshInstance3D
	(mesh.mesh as BoxMesh).size.y = height
	var collision := body.get_node("CollisionShape3D") as CollisionShape3D
	(collision.shape as BoxShape3D).size.y = height

func _finish_race(player_won: bool) -> void:
	super._finish_race(player_won)
	if preload("res://scripts/city_progress.gd").transitioning: return
	if has_node("MonsterEncounters"): get_node("MonsterEncounters").set_process(false)
	Engine.time_scale = 1.0
	# Use the results delay before advancing on a win or retrying on a loss.
	race_state = "FINISHED"
	finish_label.text = "YOU WIN" if player_won else "TRY AGAIN"

func _next_scene_path() -> String:
	return "res://scenes/level_3_beta.tscn"

func _restart_race() -> void:
	super._restart_race()
	if has_node("MonsterEncounters"):
		var previous := get_node("MonsterEncounters")
		remove_child(previous)
		previous.queue_free()
		_build_monster_encounters()
	rival_stall_time = 0.0
	rival_progress_z = rival.position.z
	rival_recoveries = 0
	wall_clock = 0
	wall_rng.seed = 22026
	for wall in changing_walls:
		wall.height = wall.home
		wall.start = wall.home
		wall.target = wall_rng.randf_range(1.1, 1.6) if wall.home < 0.9 else wall_rng.randf_range(0.5, 1.2)
		wall.elapsed = 0.0
		_set_wall_height(wall, wall.home)

func _build_monster_encounters() -> void:
	var encounters := MonsterEncounters.new()
	encounters.name = "MonsterEncounters"
	encounters.encounters_only = true
	encounters.encounter_seconds = 4.0
	encounters.player_path = NodePath("../Player")
	encounters.shadow_path = NodePath("../Rival")
	encounters.goal_path = NodePath("../CourseGeometry/FinishLine")
	var visuals := [preload("res://monsters/disco_ball/disco_ball.tscn"), preload("res://monsters/speaker/speaker.tscn")]
	for i in range(2):
		var monster := MonsterQteTarget.new()
		monster.name = "DiscoBall" if i == 0 else "Speaker"
		monster.position = Vector3(-3.5 if i == 0 else 3.5, 0.05, -65 - i * 100)
		monster.required_key = "Q" if i == 0 else "E"
		var visual: Node3D = visuals[i].instantiate()
		visual.name = "Visual"
		monster.add_child(visual)
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.7
		capsule.height = 2.4
		col.shape = capsule
		col.position.y = 1.2
		monster.add_child(col)
		encounters.add_child(monster)
	add_child(encounters)
