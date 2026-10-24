extends RefCounted
## opening sequence implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

func build_bedroom() -> void:
	game.bedroom = Node3D.new()
	game.add_child(game.bedroom)
	game.bedroom.position = Vector3(1000, 0, 0)
	game.box(game.bedroom, Vector3(0, -0.2, 0), Vector3(10, 0.3, 11), game.material(Color("252331")))
	for side in [-1, 1]: game.box(game.bedroom, Vector3(side * 5, 2.5, 0), Vector3(0.2, 5, 11), game.material(Color("202334")))
	game.box(game.bedroom, Vector3(0, 2.5, -5), Vector3(10, 5, 0.2), game.material(Color("252738")))
	game.box(game.bedroom, Vector3(0, 5, 0), Vector3(10, 0.15, 11), game.material(Color("181c2a")))
	game.box(game.bedroom, Vector3(0, 0.5, 0), Vector3(2.5, 0.7, 4.4), game.material(Color("292331")))
	game.box(game.bedroom, Vector3(0, 0.95, 0), Vector3(2.5, 0.35, 4.3), game.material(Color("697581")))
	game.box(game.bedroom, Vector3(0, 1.2, -0.6), Vector3(2.45, 0.2, 2.8), game.material(Color("384759")))
	for i in range(10): game.box(game.bedroom, Vector3(-1.1 + i * 0.24, 1.32, -0.6), Vector3(0.035, 0.018, 2.7), game.material(Color("48596a")))
	game.orb(game.bedroom, Vector3(0, 1.22, 1.4), Vector3(1.6, 0.28, 0.8), game.material(Color("a0a2a4")))
	game.box(game.bedroom, Vector3(0, 1.4, 2.2), Vector3(2.7, 1.5, 0.15), game.material(Color("342e3a")))
	game.box(game.bedroom, Vector3(2.25, 0.8, 0.8), Vector3(1.1, 1.6, 1.1), game.material(Color("352d37")))
	game.box(game.bedroom, Vector3(2.25, 1.7, 0.65), Vector3(0.6, 0.22, 0.25), game.material(Color("11151f")))
	game.caption(game.bedroom, "02:17", Vector3(2.25, 1.86, 0.5), Color("ed986b"), 24)
	game.box(game.bedroom, Vector3(-2, 2.8, -4.85), Vector3(2.7, 2.3, 0.05), game.material(Color("0c1430"), 0.2))
	for x in [-3.4, -2.0, -0.6]: game.box(game.bedroom, Vector3(x, 2.8, -4.77), Vector3(0.07, 2.5, 0.07), game.material(Color("596779")))
	game.box(game.bedroom, Vector3(-2, 2.8, -4.75), Vector3(2.8, 0.07, 0.07), game.material(Color("596779")))
	game.orb(game.bedroom, Vector3(-2.7, 3.4, -4.8), Vector3(0.4, 0.4, 0.04), game.material(Color("b0cce4"), 1))
	var lamp = OmniLight3D.new()
	game.bedroom.add_child(lamp)
	lamp.position = Vector3(2, 2, 0)
	lamp.light_color = Color("eaa56d")
	lamp.light_energy = 0.45
	lamp.omni_range = 7

func begin_sleep() -> void:
	game.reset_race()
	game.state = "sleep"
	game.phase_time = 0
	game.blink_count = 0
	game.scare_played = false
	game.completed_lessons.clear()
	game.tutorial_step = 0
	game.bedroom.show()
	game.shadow.hide()
	game.tape.show()
	game.arms.show()
	game.overlay.hide()
	game.tutorial_panel.hide()
	game.tutorial_gate.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game.camera.position = Vector3(1000, 1.65, 1.45)
	game.camera.rotation = Vector3(0.14, 0, 0)
	game.banner.text = "02:17 AM / YOU CAN'T KEEP YOUR EYES OPEN."
	game.feedback_time = 10

func set_lids(amount: float) -> void:
	var size = game.get_viewport().get_visible_rect().size
	game.lids_top.position = Vector2.ZERO
	game.lids_top.size = Vector2(size.x, size.y * 0.51 * amount)
	game.lids_bottom.position = Vector2(0, size.y * (1 - 0.51 * amount))
	game.lids_bottom.size = Vector2(size.x, size.y * 0.51 * amount)

func wake_up() -> void:
	game.state = "wake"
	game.phase_time = 0
	game.bedroom.hide()
	game.player.position = Vector3(0, 0.1, 13)
	game.player.velocity = Vector3.ZERO
	game.yaw = 0
	game.pitch = -0.15
	game.set_lids(0)
	game.veil.color.a = 1
	game.banner.text = "THIS ISN'T YOUR ROOM."
	game.feedback_time = 5

func trigger_tape() -> void:
	if game.state != "explore": return
	game.state = "encounter"
	game.phase_time = 0
	game.encounter_origin = game.player.position
	game.encounter_yaw = game.yaw
	game.player.velocity = Vector3.ZERO
	game.tape.hide()
	game.shadow.show()
	game.shadow.position = game.tape.position - Vector3(0, 1.6, 0)
	game.shadow.rotation.y = PI
	game.banner.text = "THAT'S YOUR FACE."
	game.feedback_time = 5


func tick(dt: float) -> void:
	if game.state == "sleep":
		var close = 0.0
		for i in range(3):
			var local = game.phase_time - (1.4 + i * 2.1)
			if local >= 0 and local <= 1.6:
				close = sin(clampf(local / 1.6, 0, 1) * PI)
				if i == 2 and local > 0.8: close = 1
			if game.phase_time >= 2.2 + i * 2.1: game.blink_count = maxi(game.blink_count, i + 1)
		game.set_lids(close)
		if game.phase_time >= 6.4: game.set_lids(1)
		game.camera.rotation.z = sin(game.clock * 0.5) * 0.015
		if game.phase_time >= 7.7: game.wake_up()
	elif game.state == "wake":
		game.veil.color.a = maxf(0, 1 - game.phase_time / 2.5)
		game.pitch = lerpf(-0.7, -0.12, clampf(game.phase_time / 3, 0, 1))
		game.update_camera(dt)
		if game.phase_time >= 3:
			game.state = "explore"
			game.banner.text = "WASD TO WALK / MOUSE TO LOOK. SOMETHING IS LYING ON THE FLOOR."
			game.feedback_time = 8
	elif game.state == "encounter":
		var rise = clampf(game.phase_time / 1.3, 0, 1)
		game.shadow.position = game.tape.position + Vector3(0, -1.7 + rise * 1.7, 0)
		if game.phase_time > 1.3:
			# The double lunges from the left, so the forced turn back to the track
			# remains visible even if the player approached the tape facing forward.
			var direction = Vector3.RIGHT
			game.shadow.position = game.player.position - direction * lerpf(2.3, 0.57, clampf((game.phase_time - 1.3) / 0.35, 0, 1))
			game.shadow_visual.get_node("Mouth").scale.y = 0.29
			if not game.scare_played:
				game.scare_played = true
				game.play_scream()
		var face_target = Vector3(game.shadow.position.x, game.player.position.y, game.shadow.position.z)
		var offset = face_target - game.player.position
		game.yaw = lerp_angle(game.yaw, atan2(-offset.x, -offset.z), minf(dt * (18 if game.phase_time > 1.3 else 5), 1))
		game.pitch = lerpf(game.pitch, 0, dt * 5)
		game.shadow.rotation.y = atan2(-offset.x, -offset.z) + PI
		game.update_camera(dt)
		if game.phase_time > 1.4:
			game.camera.rotation.z = sin(game.clock * 63) * 0.025
			game.camera.position += Vector3(randf_range(-0.025, 0.025), randf_range(-0.025, 0.025), 0)
		if game.phase_time >= 3.3:
			game.state = "forced_turn"
			game.phase_time = 0
			game.encounter_yaw = game.yaw
			game.banner.text = "RUN. THAT'S WHAT IT WANTS YOU TO DO."
	elif game.state == "forced_turn":
		game.yaw = lerp_angle(game.encounter_yaw, 0, smoothstep(0, 1, game.phase_time / 1.3))
		game.pitch = lerpf(game.pitch, 0, dt * 4)
		if game.phase_time > 1.3:
			game.player.velocity = Vector3(0, 0, -6)
			game.player.move_and_slide()
		game.update_camera(dt)
		if game.phase_time > 2.7:
			game.shadow_visual.get_node("Mouth").scale.y = 0.035
			game.enter_lesson(0)
