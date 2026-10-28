extends Node3D
## Campaign-only additions to the existing race controller.
const Props = preload("res://scripts/story_props.gd")
@export var first_encounter_delay := 4.0
@export var encounter_interval := -1.0
@export var segment_count := 21
@export var course_width := 9.3
var race
var round_number := 1
var prompt: Label
var monster: Node3D
var goal: Node3D
var qte_remaining := 0.0
var required_key := KEY_Q
var next_encounter := 4.0
var surfaces: Array[Dictionary] = []
var fragments: Array[Node3D] = []
var time := 0.0

func _ready() -> void:
	race = get_parent()
	round_number = int(race.get_meta("story_round", 1))
	next_encounter = first_encounter_delay
	var layer := CanvasLayer.new()
	add_child(layer)
	prompt = Label.new()
	prompt.position = Vector2(540, 240)
	prompt.size = Vector2(200, 120)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 72)
	prompt.add_theme_color_override("font_color", Color("65f5db"))
	prompt.add_theme_color_override("font_outline_color", Color("080a18"))
	prompt.add_theme_constant_override("outline_size", 8)
	layer.add_child(prompt)
	goal = Props.tape(self, Vector3(0, 2, 8 - (segment_count - 1) * 10 - 2))
	goal.scale = Vector3.ONE * 2.2
	_build_platforms()
	# Different silhouettes and palettes distinguish the three sections.
	var colors := [Color("65f5db"), Color("ad70fa"), Color("ff638d")]
	for i in range(ceili(segment_count * 1.67)):
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := Vector3(side * (course_width + i % 4 * 3), -4 + i % 7, -i * 6)
		var shard := Props.box(self, p, Vector3(2, 2 + round_number, 2), colors[round_number - 1], 0.6)
		shard.rotation = Vector3(i * 0.4, i * 0.7, 0.5)
		fragments.append(shard)
	# The starting mirror reflects a silhouette before the player is aware of it.
	Props.box(self, Vector3(-3, 1.8, 1), Vector3(1.3, 2.6, 0.15), Color("7899af"), 0.4)
	var reflection := Props.person(self, Vector3(-3, 0.6, 1.15), true)
	reflection.scale *= 0.85
	for i in range(4):
		var crack := Props.box(self, Vector3(-3 + i * 0.16, 1.6, 1.3), Vector3(0.025, 1.9, 0.02), Color("09071c"))
		crack.rotation.z = -0.6 + i * 0.35

func _build_platforms() -> void:
	# Keep the rival's original continuous floor on layer 2; the player uses
	# floating segmented platforms on layer 1. Existing projectile holes remain.
	var old_floor := race.get_node("CourseGeometry/Raceway") as StaticBody3D
	old_floor.collision_layer = 2
	old_floor.hide()
	race.rival.collision_mask = 3
	for wall_name in ["LeftWall", "RightWall"]:
		var wall: StaticBody3D = race.get_node("CourseGeometry/" + wall_name)
		# Low rails expose the floating dimension; tall wall-run sections remain
		# farther down the track for the original movement system.
		wall.position.y = 0.15
		wall.get_node("Mesh").scale.y = 0.1
		var collision := wall.get_node("CollisionShape3D") as CollisionShape3D
		collision.shape = collision.shape.duplicate()
		collision.shape.size.y = 0.45
	for i in range(maxi(round_number + 1, floori(segment_count / 7.0))):
		race._add_solid(self, "WallRun", Vector3((-1 if i % 2 else 1) * (course_width / 2 - 0.25), 1.8, -40 - i * 48), Vector3(0.3, 3.6, 18), race._material(Color("563b82"), 0.6))
	for i in range(segment_count):
		var kind := i % 4
		var color: Color = [Color("252842"), Color("65f5db"), Color("aa547e"), Color("ffd384")][kind]
		var p := Vector3(0, -0.25, 8 - i * 10)
		var gap := 0.0 if i < 2 else (0.6 + round_number * 0.5)
		race._add_solid(self, "Raceway", p, Vector3(course_width, 0.5, 10.0 - gap), race._material(color, 0.3))
		var body := get_child(get_child_count() - 1) as StaticBody3D
		surfaces.append({"body": body, "home": p, "kind": kind, "collapse": -1.0, "restore": 0.0, "corrupt": false})
		if i > 2 and i % 5 == 0:
			# Jumpable blocks create decisions beyond the gaps and speed surfaces.
			race._add_solid(self, "Obstacle", p + Vector3(-2 if i % 2 else 2, 0.65, 0), Vector3(3.2, 1.3, 0.8), race._material(Color("403354")))

func reset() -> void:
	qte_remaining = 0
	next_encounter = first_encounter_delay
	prompt.text = ""
	if is_instance_valid(monster): monster.queue_free()
	race.player.story_boost_time = 0
	race.player.story_surface_multiplier = 1
	for surface in surfaces:
		surface.collapse = -1.0
		surface.restore = 0.0
		surface.corrupt = false
		surface.body.position = surface.home
		surface.body.show()
		var color: Color = [Color("252842"), Color("65f5db"), Color("aa547e"), Color("ffd384")][surface.kind]
		surface.body.get_node("Mesh").material_override = race._material(color, 0.3)
		surface.body.get_node("CollisionShape3D").set_deferred("disabled", false)

func _process(dt: float) -> void:
	time += dt
	goal.rotation.y += dt
	for shard in fragments: shard.rotation.y += dt * 0.15
	if race.race_state != "RACING":
		prompt.text = ""
		return
	if qte_remaining > 0:
		qte_remaining -= dt
		monster.position = race.player.position + Vector3(0, 0, -3)
		monster.rotation.z = sin(time * 17) * 0.12
		prompt.modulate.a = 0.85 + 0.15 * sin(time * 15)
		if qte_remaining <= 0: resolve(false)
	else:
		next_encounter -= dt
		if next_encounter <= 0:
			required_key = [KEY_Q, KEY_E, KEY_R, KEY_F].pick_random()
			qte_remaining = 2.0
			prompt.show()
			prompt.text = OS.get_keycode_string(required_key)
			monster = Props.person(self, race.player.position + Vector3(0, 0, -3), true)
			monster.scale *= 1.4
	_update_surfaces(dt)

func _input(event: InputEvent) -> void:
	if qte_remaining <= 0 or race.race_state != "RACING": return
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key in [KEY_Q, KEY_E, KEY_R, KEY_F]:
			resolve(key == required_key)
			get_viewport().set_input_as_handled()

func resolve(success: bool) -> void:
	race.player.apply_story_qte(success)
	qte_remaining = 0
	next_encounter = encounter_interval if encounter_interval > 0 else 7.0 - round_number
	prompt.text = ""
	if is_instance_valid(monster):
		var tween := create_tween()
		tween.tween_property(monster, "scale", Vector3.ZERO, 0.2)
		tween.tween_callback(monster.queue_free)

func _update_surfaces(dt: float) -> void:
	race.player.story_surface_multiplier = 1.0
	for surface in surfaces:
		var body: StaticBody3D = surface.body
		if not surface.corrupt and race.rival.position.z < surface.home.z - 4:
			surface.corrupt = true
			body.get_node("Mesh").material_override = race._material(Color("50346b"), 0.5)
			if surface.kind == 3: surface.collapse = 0.9
		if surface.collapse > 0:
			surface.collapse -= dt
			body.position.x = sin(time * 45) * 0.06
			if surface.collapse <= 0:
				surface.restore = 4.0
				body.get_node("CollisionShape3D").set_deferred("disabled", true)
		elif surface.restore > 0:
			surface.restore -= dt
			body.position.y = maxf(body.position.y - dt * 9, -18)
			if surface.restore <= 0:
				body.position = surface.home
				body.get_node("CollisionShape3D").set_deferred("disabled", false)
		if not race.player.is_on_floor(): continue
		for i in range(race.player.get_slide_collision_count()):
			var contact = race.player.get_slide_collision(i)
			if contact.get_collider() != body or contact.get_normal().y < 0.7: continue
			if surface.kind == 1 and not surface.corrupt: race.player.story_surface_multiplier = 1.3
			if surface.kind == 2 or surface.corrupt: race.player.story_surface_multiplier = 0.78
			if surface.kind == 3 and race.player.state in ["DIVING", "DIVE_LANDING"] and surface.collapse < 0:
				surface.collapse = 0.9
