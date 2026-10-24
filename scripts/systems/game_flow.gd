extends RefCounted
## game flow implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

func _ready() -> void:
	game.initialize_game()
	game.player_visual.hide()
	game.shadow.get_child(1).hide()
	game.camera.near = 0.045
	game.camera.fov = 85
	game.arms = game.make_view_arms()
	game.build_bedroom()
	game.build_arrival()
	game.build_story_ui()
	game.scream_player = AudioStreamPlayer.new()
	game.add_child(game.scream_player)
	game.ambience = AudioStreamPlayer.new()
	game.add_child(game.ambience)
	game.make_ambience()
	game.begin_sleep()
	game.update_ui()

func initialize_game() -> void:
	game.environment.build_scene()
	game.player_movement.create_player()
	game.ghost_runner.create_shadow()
	game.camera = Camera3D.new()
	game.camera.fov = 78
	game.camera.far = 260
	game.add_child(game.camera)
	game.camera.current = true
	game.audio = AudioStreamPlayer.new()
	game.add_child(game.audio)
	game.build_ui()
	game.reset_race()

func reset_race() -> void:
	game.player.position = Vector3(0, 1, -3)
	game.player.velocity = Vector3.ZERO
	game.ghost_distance = 0
	game.shadow.position = Vector3(1.8, 0, 0)
	game.elapsed = 0
	game.boost = 0
	game.slow = 0
	game.qte_time = 0
	game.next_qte = 7
	game.coyote = 0
	game.jump_buffer = 0
	game.won = false
	for p in game.platforms:
		p.corrupt = false
		p.collapse = -1.0
		p.body.position.y = p.y - 0.6
		p.col.set_deferred("disabled", false)
		p.mesh.material_override = game.material(Color("6a5942") if p.kind == 3 else (Color("573b50") if p.kind == 2 else Color("263d51")))
	game.yaw = 0
	game.pitch = 0
	game.camera.position = game.player.position + Vector3(0, 1.66, 0)
	game.camera.rotation = Vector3.ZERO
	game.banner.text = "THE MIRROR REMEMBERS. SO DOES YOUR SHADOW."
	game.feedback_time = 5

func start_real_race() -> void:
	game.reset_race()
	game.player.position = Vector3(0, 0.1, -3)
	game.player.velocity = Vector3.ZERO
	game.shadow.show()
	game.ghost_distance = 2
	game.state = "race"
	game.yaw = 0
	game.pitch = 0
	game.next_qte = 5
	game.banner.text = "IT KNOWS EVERYTHING YOU JUST LEARNED. RUN."
	game.feedback_time = 4

func _physics_process(dt: float) -> void:
	if game.state == "paused": return
	game.clock += dt
	game.phase_time += dt
	if game.state in ["sleep", "wake", "encounter", "forced_turn"]:
		game.opening_sequence.tick(dt)
	elif game.state == "countdown":
		game.update_camera(dt)
		game.prompt.visible = true
		game.prompt.text = "THE REAL RACE\n%d" % maxi(1, 3 - int(game.phase_time))
		if game.phase_time >= 3: game.start_real_race()
	elif game.state == "explore" or game.state == "race" or game.state == "tutorial":
		if not (game.state == "tutorial" and game.tutorial_waiting): game.simulate(dt)
		game.update_camera(dt)
	game.update_ui()
