extends RefCounted
## Evan / player movement implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

func simulate(dt: float) -> void:
	if game.state == "race": game.elapsed += dt
	game.boost = maxf(0, game.boost - dt)
	game.slow = maxf(0, game.slow - dt)
	game.jump_buffer = maxf(0, game.jump_buffer - dt)
	game.coyote = 0.13 if game.player.is_on_floor() else maxf(0, game.coyote - dt)
	game.qte.tick(dt)
	var dive = Input.is_physical_key_pressed(KEY_SHIFT)
	var x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var z = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	var direction = Vector3(x, 0, z).normalized().rotated(Vector3.UP, game.yaw)
	var index = game.tile_at(-game.player.position.z)
	var speed = 4.0 if game.state == "bedroom" else (5.0 if game.state == "explore" else 15.5)
	if game.boost > 0: speed += 7
	if game.slow > 0: speed *= 0.55
	var on_floor = game.player.is_on_floor()
	speed = game.environment.surface_speed(speed, index, on_floor, dive)
	game.player.velocity.x = move_toward(game.player.velocity.x, direction.x * speed, 40 * dt)
	game.player.velocity.z = move_toward(game.player.velocity.z, direction.z * speed, 40 * dt)
	if game.jump_buffer > 0 and game.coyote > 0:
		game.player.velocity.y = 10
		game.jump_buffer = 0
		game.coyote = 0
		game.beep(460)
	var glide = Input.is_physical_key_pressed(KEY_SPACE) and game.player.velocity.y < 0 and not dive and not on_floor
	game.player.velocity.y -= (5 if glide else 26) * dt
	if glide: game.player.velocity.y = maxf(game.player.velocity.y, -2.6)
	if dive: game.player.velocity.y -= 45 * dt
	var impact = -game.player.velocity.y
	game.player.move_and_slide()
	var landed_index = game.tile_at(-game.player.position.z)
	game.environment.react_to_landing(landed_index, impact)
	game.environment.tick_platforms(dt)
	if game.state == "bedroom":
		game.player.position.x = clampf(game.player.position.x, 995.4, 1004.6)
		game.player.position.z = clampf(game.player.position.z, -4.9, 8.5)
	elif game.state == "explore":
		game.player.position.x = clampf(game.player.position.x, -12, 12)
		game.player.position.z = clampf(game.player.position.z, 1000.8, 1018)
		if not game.tape_revealed and game.player.position.z <= 1011.5: game.opening_sequence.reveal_tape()
	elif game.state == "race":
		game.update_ghost(dt)
		if game.player.position.y < -22: game.finish(false, "You fell between the fragments of your memories.")
		elif -game.player.position.z >= game.FINISH: game.finish(true, "Your double stays behind. This life is still yours.")
		elif game.ghost_distance >= game.FINISH: game.finish(false, "Someone else wakes up wearing your face.")
	if game.state == "explore" and game.player.position.y < -10:
		game.player.position = Vector3(0, 0.2, 1016)
		game.player.velocity = Vector3.ZERO

func update_camera(dt: float) -> void:
	var horizontal = Vector2(game.player.velocity.x, game.player.velocity.z).length()
	game.view_bob += dt * minf(horizontal, 16) * 0.8
	var bob = sin(game.view_bob * 2) * 0.025 if game.player.is_on_floor() and horizontal > 0.4 else 0.0
	game.camera.position = game.player.position + Vector3(0, 1.66 + bob, 0)
	game.camera.rotation = Vector3(game.pitch, game.yaw, 0)
	game.camera.fov = lerpf(game.camera.fov, 92 if horizontal > 20 else 85, dt * 4)
	if game.arms != null:
		game.arms.position = Vector3(sin(game.view_bob) * 0.012, absf(sin(game.view_bob)) * 0.016, 0)
		game.arms.rotation.z = sin(game.view_bob) * 0.012
		for i in range(game.arms.get_child_count()):
			var arm = game.arms.get_child(i)
			var stride = sin(game.view_bob * 2 + i * PI) * minf(horizontal / 18, 1) * 0.14
			arm.rotation.x = lerpf(arm.rotation.x, -0.9 + stride, minf(dt * 10, 1))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and game.state in ["bedroom", "explore", "race"]:
		game.yaw -= event.relative.x * 0.0022
		game.pitch = clampf(game.pitch - event.relative.y * 0.0022, -1.35, 1.35)
	if event is InputEventMouseButton and event.pressed and game.state != "paused": Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key = event.physical_keycode
	if key == KEY_M:
		game.muted = not game.muted
		AudioServer.set_bus_mute(0, game.muted)
		return
	if key == KEY_ESCAPE:
		if game.state == "paused":
			game.state = game.resume_state
			game.overlay.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif game.state != "result":
			game.resume_state = game.state
			game.state = "paused"
			game.show_overlay("MEMORY SUSPENDED", "ESC TO RESUME\nMouse look / WASD move / Space jump and glide / Shift dive")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if game.state == "result" and key == KEY_ENTER:
		game.begin_sleep()
		return
	if key == KEY_E and game.state in ["bedroom", "explore"]:
		game.opening_sequence.interact()
		return
	if game.state not in ["bedroom", "explore", "race"]: return
	if key == KEY_SPACE: game.jump_buffer = 0.16
	if game.qte_time > 0 and key in game.KEYS: game.resolve_qte(key == game.qte_key)

func create_player() -> void:
	game.player = CharacterBody3D.new()
	game.player.floor_snap_length = 0.6
	game.player.floor_max_angle = deg_to_rad(50)
	game.add_child(game.player)
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	game.player.add_child(collision)
	game.player_visual = game.make_runner(game.player, game.MINT)
