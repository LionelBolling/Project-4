extends RefCounted
## Faceted floating land and a live view of the sleeper inside the finish portal.
var game

func setup(context: Node3D) -> void:
	game = context

func build() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 41721
	var rock = game.material(Color("263751"))
	var rim = game.material(Color("6b9ec7"), 0.6)
	for i in range(44):
		var island = Node3D.new()
		game.add_child(island)
		var side = -1 if i % 2 == 0 else 1
		island.position = Vector3(side * rng.randf_range(17, 48), rng.randf_range(2, 25), rng.randf_range(-160, 26))
		if i < 32: island.position.z += 1000
		var radius = rng.randf_range(2, 6)
		var mesh = SurfaceTool.new()
		mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		var points: Array[Vector3] = []
		for n in range(7):
			var angle = TAU * n / 7
			points.append(Vector3(cos(angle) * radius * rng.randf_range(0.7, 1.2), rng.randf_range(-0.2, 0.2), sin(angle) * radius))
		for n in range(7):
			var a = points[n]
			var b = points[(n + 1) % 7]
			for vertex in [Vector3.ZERO, b, a, a, b, Vector3(radius * 0.15, -radius * 1.35, 0)]: mesh.add_vertex(vertex)
		mesh.generate_normals()
		var shard = MeshInstance3D.new()
		shard.mesh = mesh.commit()
		shard.material_override = rock
		island.add_child(shard)
		for n in range(3):
			var seam = game.box(island, Vector3(-radius * 0.4 + n * radius * 0.4, 0.22, 0), Vector3(0.04, 0.035, radius * 1.5), rim)
			seam.rotation.y = n * 0.6
		if i % 3 == 0:
			game.box(island, Vector3(radius * 0.25, 1.9, 0), Vector3(0.6, 3.8, 0.7), game.material(Color("53657b")))
			var wall = game.box(island, Vector3(0, 2.5, -1), Vector3(radius, 5, 0.35), game.material(Color("25314b")))
			wall.rotation.z = 0.12 * side
		game.opening_sequence.floating_fragments.append({"node": island, "y": island.position.y, "phase": i * 1.7, "bob": rng.randf_range(0.15, 0.6), "spin": rng.randf_range(-0.015, 0.015)})
	# Familiar room fragments suspended above the arrival plaza.
	for side in [-1, 1]:
		var broken = game.box(game, Vector3(side * 10, 4.2, 1006), Vector3(0.6, 8, 2), game.material(Color("394765")))
		broken.rotation.z = side * 0.3
		game.box(game, Vector3(side * 10, 9, 1003), Vector3(3.5, 0.5, 4), rock).rotation.z = side * -0.3
	# No text hovering over the tape: the reveal shot and interaction prompt lead to it.
	for node in game.tape.get_children():
		if node is Label3D: node.hide()
	build_portal()

func build_portal() -> void:
	var portal = Node3D.new()
	portal.name = "SleeperPortal"
	game.add_child(portal)
	portal.position = Vector3(0, 0, -game.FINISH)
	game.opening_sequence.portal = portal
	var metal = game.material(Color("152842"))
	var blue = game.material(Color("74bfff"), 2)
	for side in [-1, 1]:
		game.box(portal, Vector3(side * 3.05, 3, 0), Vector3(0.5, 6.5, 0.65), metal)
		game.box(portal, Vector3(side * 2.78, 3, 0.38), Vector3(0.07, 5.8, 0.04), blue)
	game.box(portal, Vector3(0, 6, 0), Vector3(6.3, 0.4, 0.65), metal)
	game.box(portal, Vector3(0, 5.79, 0.38), Vector3(5.6, 0.07, 0.04), blue)
	var viewport = SubViewport.new()
	viewport.name = "SleepingBedroomView"
	viewport.size = Vector2i(768, 768)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	portal.add_child(viewport)
	var room = game.bedroom.duplicate() as Node3D
	room.name = "BedroomReflection"
	room.position = Vector3.ZERO
	viewport.add_child(room)
	game.opening_sequence.portal_room = room
	var sleeper = game.make_runner(room, game.MINT)
	sleeper.name = "SleepingPlayer"
	sleeper.position = Vector3(-2.65, 1.43, 0.2)
	sleeper.rotation = Vector3(PI / 2, PI, 0)
	game.opening_sequence.sleeper = sleeper
	game.orb(room, Vector3(-2.65, 1.43, -0.35), Vector3(1.7, 0.29, 1.8), game.material(Color("304e70")))
	var world = WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("101b2d")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("92a7c9")
	world.environment.ambient_light_energy = 0.5
	viewport.add_child(world)
	var camera = Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(-0.3, 3.4, 1.8)
	camera.look_at(Vector3(-2.65, 1.2, -0.65))
	camera.fov = 53
	camera.current = true
	var screen = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(5.45, 5.45)
	screen.mesh = quad
	portal.add_child(screen)
	screen.position = Vector3(0, 3, 0.1)
	var shader = Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, cull_disabled; uniform sampler2D bedroom_view : source_color; void fragment() { vec2 p = UV - vec2(0.5); float edge = smoothstep(0.50, 0.40, max(abs(p.x), abs(p.y))); vec2 uv = UV + vec2(sin(UV.y * 30.0 + TIME * 1.5) * 0.002, 0.0); vec3 room = texture(bedroom_view, uv).rgb; ALBEDO = mix(vec3(0.10, 0.32, 0.65), room, edge) + vec3(0.03, 0.08, 0.14); }"
	var surface = ShaderMaterial.new()
	surface.shader = shader
	surface.set_shader_parameter("bedroom_view", viewport.get_texture())
	screen.material_override = surface
	var light = OmniLight3D.new()
	portal.add_child(light)
	light.position = Vector3(0, 3, 2)
	light.light_color = Color("6bb5ff")
	light.light_energy = 2
	light.omni_range = 12
