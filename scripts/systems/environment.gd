extends RefCounted
## Samaii / environment implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

func surface_speed(speed: float, index: int, grounded: bool, diving: bool) -> float:
	if index < 0 or not grounded: return speed
	var p = game.platforms[index]
	if p.kind == 1 and not p.corrupt: speed += 6
	if p.kind == 2 or p.corrupt: speed *= 0.78
	if diving and p.slope < 0: speed += 12
	return speed

func react_to_landing(index: int, impact: float) -> void:
	if index < 0 or not game.player.is_on_floor(): return
	var p = game.platforms[index]
	if p.kind == 3 and impact > 10.5 and p.collapse < 0:
		p.collapse = 0.9
		game.banner.text = "THIS MEMORY IS BREAKING. MOVE!"
		game.feedback_time = 2

func tick_platforms(dt: float) -> void:
	for p in game.platforms:
		if p.collapse > 0:
			p.collapse = maxf(0, p.collapse - dt)
			if p.collapse == 0: p.col.set_deferred("disabled", true)
		if p.collapse == 0: p.body.position.y -= dt * 10

func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

func box(parent: Node, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	return node

func caption(parent: Node3D, text: String, pos: Vector3, color: Color, size: int = 38) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.012
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	parent.add_child(label)
	label.position = pos
	return label

func build_world() -> void:
	var stable = game.material(Color("263d51"))
	var rough = game.material(Color("573b50"))
	var weak = game.material(Color("6a5942"))
	var z = 0.0
	for i in range(24):
		var length = 20.0
		var kind = i % 4
		var slope = -0.12 if i % 6 == 2 else (0.12 if i % 6 == 3 else 0.0)
		var center_y = -1.2 if i % 6 == 2 or i % 6 == 3 else 0.0
		var body = StaticBody3D.new()
		game.add_child(body)
		body.position = Vector3(0, center_y - 0.6, -z - length / 2)
		body.rotation.x = slope
		var mesh = game.box(body, Vector3.ZERO, Vector3(11, 1.2, length), weak if kind == 3 else (rough if kind == 2 else stable))
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(11, 1.2, length)
		col.shape = shape
		body.add_child(col)
		var color = game.MINT if kind <= 1 else (Color("ee91a4") if kind == 2 else Color("ffd18b"))
		var edge_mat = game.material(color, 1.0)
		for side in [-1, 1]: game.box(body, Vector3(side * 5.42, 0.65, 0), Vector3(0.12, 0.08, length), edge_mat)
		if kind == 1:
			for n in range(6):
				var marker = game.box(body, Vector3(0, 0.65, 7 - n * 2.6), Vector3(3.5, 0.05, 0.18), edge_mat)
				marker.rotation.y = 0.18
		if kind == 3:
			for n in range(5):
				var crack = game.box(body, Vector3(-3 + n * 1.5, 0.65, 0), Vector3(0.06, 0.04, 13), edge_mat)
				crack.rotation.y = 0.3 * sin(n * 3)
		game.platforms.append({"body": body, "mesh": mesh, "col": col, "start": z, "end": z + length, "kind": kind, "corrupt": false, "collapse": -1.0, "slope": slope, "y": center_y})
		z += length + (2.5 if i > 0 else 0)
	# Broad safe landing and the door back to reality.
	var exit_body = StaticBody3D.new()
	game.add_child(exit_body)
	exit_body.position = Vector3(0, -0.6, -game.FINISH - 6)
	game.box(exit_body, Vector3.ZERO, Vector3(14, 1.2, 30), stable)
	var exit_col = CollisionShape3D.new()
	var exit_shape = BoxShape3D.new()
	exit_shape.size = Vector3(14, 1.2, 30)
	exit_col.shape = exit_shape
	exit_body.add_child(exit_col)
	game.caption(game, "WAKE UP", Vector3(0, 7.2, -game.FINISH), Color("a6d1ff"), 54)
	# Cracked mirror: a solid shadow, and a fading original.
	var mirror = Node3D.new()
	game.add_child(mirror)
	mirror.position = Vector3(-4, 0, -11)
	game.box(mirror, Vector3(0, 2, 0), Vector3(0.2, 4.4, 3), game.material(Color("829eb2")))
	game.box(mirror, Vector3(0.12, 2, 0), Vector3(0.04, 3.9, 2.6), game.material(Color("1a2947"), 0.3))
	var reflection = game.make_runner(mirror, game.VIOLET)
	reflection.position = Vector3(0.25, 0.8, 0)
	reflection.rotation.y = PI / 2
	var crack = game.box(mirror, Vector3(0.17, 2, 0), Vector3(0.06, 3.8, 0.035), game.material(Color.WHITE, 1))
	crack.rotation.x = 0.25
	game.caption(game, "IT LOOKS MORE REAL THAN YOU.", Vector3(-4, 5.3, -11), Color("ffd18b"), 30)
	game.caption(game, "HOLD SPACE TO GLIDE ACROSS GAPS", Vector3(0, 3.8, -34), game.MINT, 30)
	game.caption(game, "DIVE DOWN SLOPES TO BUILD MOMENTUM", Vector3(0, 5, -51), game.MINT, 30)
	var ruin_mat = game.material(Color("17263d"))
	for i in range(110):
		var side = -1 if i % 2 == 0 else 1
		var p = Vector3(side * randf_range(15, 55), randf_range(-22, -5), -randf_range(0, 600))
		var ruin = game.box(game, p, Vector3(randf_range(2, 9), randf_range(8, 35), randf_range(3, 12)), ruin_mat)
		ruin.rotation = Vector3(randf_range(-0.2, 0.2), randf_range(-1, 1), randf_range(-0.3, 0.3))

func solid(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body = StaticBody3D.new()
	parent.add_child(body)
	body.position = pos
	game.box(body, Vector3.ZERO, size, game.material(color))
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body

func build_arrival() -> void:
	var origin = Vector3(0, 0, 1000)
	game.solid(game, origin + Vector3(0, -0.6, 9), Vector3(26, 1.2, 20), Color("202e40"))
	for side in [-1, 1]:
		game.solid(game, origin + Vector3(side * 12.8, 1, 9), Vector3(0.5, 3, 20), Color("22283b"))
	game.solid(game, origin + Vector3(0, 1, 18.8), Vector3(26, 3, 0.5), Color("22283b"))
	for i in range(14):
		var slab = game.box(game, origin + Vector3(randf_range(-10, 10), 0.025, randf_range(1, 18)), Vector3(randf_range(0.3, 1), 0.035, randf_range(0.3, 1)), game.material(Color("495063")))
		slab.rotation.y = randf() * TAU
	game.tape = Node3D.new()
	game.add_child(game.tape)
	game.tape.position = origin + Vector3(1.5, 0.12, 6)
	game.tape.rotation.y = -0.3
	game.box(game.tape, Vector3.ZERO, Vector3(0.62, 0.14, 0.37), game.material(Color("14131b")))
	game.box(game.tape, Vector3(0, 0.076, 0), Vector3(0.4, 0.015, 0.23), game.material(Color("cfba9d")))
	for side in [-1, 1]: game.orb(game.tape, Vector3(side * 0.17, 0.088, 0), Vector3(0.12, 0.015, 0.12), game.material(Color("39333b")))
	game.box(game.tape, Vector3(0, 0.09, 0.09), Vector3(0.26, 0.015, 0.025), game.material(Color("a45250")))
	game.caption(game.tape, "VIDEO TAPE\nPLAY ME", Vector3(0, 0.65, 0), Color("dbc4a3"), 22)
	var light = OmniLight3D.new()
	game.tape.add_child(light)
	light.position.y = 0.8
	light.light_color = Color("e1b991")
	light.light_energy = 0.8
	light.omni_range = 3

func tile_at(distance: float) -> int:
	for i in range(game.platforms.size()):
		if distance >= game.platforms[i].start and distance <= game.platforms[i].end: return i
	return -1

func build_scene() -> void:
	randomize()
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("0b1223")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("94b0d9")
	env.environment.ambient_light_energy = 0.65
	env.environment.fog_enabled = true
	env.environment.fog_light_color = Color("131a30")
	env.environment.fog_density = 0.006
	game.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_color = Color("b2cfff")
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	game.add_child(sun)
	game.build_world()
