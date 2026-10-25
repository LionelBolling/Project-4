extends RefCounted
## Playable bedroom, dream arrival, tape abduction and race introduction.
var game
var interactables: Array[Dictionary] = []
var floating_fragments: Array[Dictionary] = []
var tv_screen: MeshInstance3D
var tv_runner: MeshInstance3D
var bedside_light: OmniLight3D
var tv_on = true
var tv_content: Array[Node] = []
var lamp_on = true
var tape_hand: Node3D
var grab_fingers: Array[Node3D] = []
var grab_origin = Vector3.ZERO
var grab_rotation = Vector3.ZERO
var shot_origin = Vector3.ZERO
var shot_rotation = Vector3.ZERO
var portal: Node3D
var sleeper: Node3D
var portal_room: Node3D
var laughed = false

func setup(context: Node3D) -> void:
	game = context

func room_box(p: Vector3, size: Vector3, color: String, glow: float = 0.0) -> MeshInstance3D:
	return game.box(game.bedroom, p, size, game.material(Color(color), glow))

func wall_text(text: String, p: Vector3, size: int, color: Color) -> Label3D:
	var label = game.caption(game.bedroom, text, p, color, size)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	label.pixel_size = 0.006
	return label

func add_interaction(id: String, p: Vector3, text: String, radius: float = 2.5) -> void:
	interactables.append({"id": id, "position": p + game.bedroom.position, "text": text, "radius": radius})

func build_bedroom() -> void:
	game.bedroom = Node3D.new()
	game.bedroom.name = "Bedroom"
	game.add_child(game.bedroom)
	game.bedroom.position = Vector3(1000, 0, 0)
	game.solid(game.bedroom, Vector3(0, -0.22, 1.5), Vector3(10, 0.4, 15), Color("252b36"))
	for side in [-1, 1]:
		game.solid(game.bedroom, Vector3(side * 5, 2, 0), Vector3(0.2, 4, 11), Color("19283e"))
		game.solid(game.bedroom, Vector3(side * 3.2, 2, 5.5), Vector3(3.6, 4, 0.2), Color("1a293f"))
		game.solid(game.bedroom, Vector3(side * 1.5, 2, 7.3), Vector3(0.15, 4, 3.6), Color("111c30"))
		room_box(Vector3(side * 1.43, 1.7, 5.36), Vector3(0.08, 3.4, 0.12), "58758e")
	game.solid(game.bedroom, Vector3(0, 2, -5.4), Vector3(10, 4, 0.2), Color("17283e"))
	room_box(Vector3(0, 3.65, 5.5), Vector3(3, 0.7, 0.24), "20334c")
	room_box(Vector3(0, 4, 0), Vector3(10, 0.15, 11), "101b2d")
	for i in range(25): room_box(Vector3(-4.8 + i * 0.4, -0.005, 0), Vector3(0.385, 0.025, 10.8), "4b3c38" if i % 3 else "59473e")
	for side in [-1, 1]:
		room_box(Vector3(side * 4.87, 0.12, 0), Vector3(0.08, 0.24, 10.7), "607181")
		room_box(Vector3(side * 4.86, 3.65, 0), Vector3(0.045, 0.04, 10.7), "5ba9e8", 1.5)
	room_box(Vector3(0, 3.65, -5.25), Vector3(9.8, 0.04, 0.04), "5ba9e8", 1.5)
	room_box(Vector3(0.5, 0.025, 1.4), Vector3(4.7, 0.035, 4.3), "182a43")
	for side in [-1, 1]:
		room_box(Vector3(0.5 + side * 2.18, 0.05, 1.4), Vector3(0.045, 0.012, 4), "6587a4")
		room_box(Vector3(0.5, 0.05, 1.4 + side * 1.96), Vector3(4.4, 0.012, 0.045), "6587a4")
	for i in range(5):
		var stripe = room_box(Vector3(0.5, 0.051, 0.2 + i * 0.6), Vector3(1.5, 0.012, 0.035), "345674")
		stripe.rotation.y = 0.45
	game.solid(game.bedroom, Vector3(-2.65, 0.38, -0.1), Vector3(2.5, 0.7, 4.2), Color("302e37"))
	room_box(Vector3(-2.65, 0.84, -0.1), Vector3(2.45, 0.28, 4.15), "abb3b8")
	room_box(Vector3(-2.65, 1.02, 0.45), Vector3(2.48, 0.16, 2.95), "304e70")
	for i in range(8): room_box(Vector3(-3.75 + i * 0.31, 1.108, 0.45), Vector3(0.018, 0.008, 2.9), "567493")
	for i in range(5): room_box(Vector3(-2.65, 1.11, -0.8 + i * 0.6), Vector3(2.46, 0.008, 0.016), "567493")
	for x in [-3.23, -2.07]: game.orb(game.bedroom, Vector3(x, 1.06, -1.62), Vector3(1.04, 0.26, 0.64), game.material(Color("c3c9c9")))
	room_box(Vector3(-2.65, 1.12, -2.3), Vector3(2.8, 1.75, 0.14), "433c40")
	for i in range(10): room_box(Vector3(-3.87 + i * 0.27, 1.15, -2.2), Vector3(0.045, 1.5, 0.035), "73605a")
	add_interaction("bed", Vector3(-2.65, 0.9, 0.8), "GO TO BED", 2.6)
	game.solid(game.bedroom, Vector3(-4.25, 0.55, -1.35), Vector3(0.9, 1.1, 1), Color("3b3840"))
	for y in [0.3, 0.75]: room_box(Vector3(-4.25, y, -0.84), Vector3(0.22, 0.035, 0.035), "91a4b5")
	room_box(Vector3(-4.25, 1.18, -1), Vector3(0.55, 0.18, 0.12), "080f1d")
	wall_text("02:17", Vector3(-4.25, 1.2, -0.928), 23, Color("a6d1ff"))
	room_box(Vector3(-4.25, 1.4, -1.63), Vector3(0.045, 0.6, 0.045), "d8b58c")
	room_box(Vector3(-4.25, 1.77, -1.63), Vector3(0.6, 0.35, 0.5), "e6bf8d", 0.5)
	bedside_light = OmniLight3D.new()
	game.bedroom.add_child(bedside_light)
	bedside_light.position = Vector3(-3.9, 2.1, -1.4)
	bedside_light.light_color = Color("ffc88d")
	bedside_light.light_energy = 2.2
	bedside_light.omni_range = 7
	add_interaction("lamp", Vector3(-4.25, 1.6, -1.4), "TOGGLE BEDSIDE LAMP", 2.2)
	# TV screen contains a small animated platform game.
	game.solid(game.bedroom, Vector3(1.25, 0.48, -4.7), Vector3(4.1, 0.9, 0.85), Color("343744"))
	for x in [-0.1, 1.25, 2.6]: room_box(Vector3(x, 0.48, -4.24), Vector3(1.22, 0.62, 0.025), "202b3b")
	room_box(Vector3(1.25, 2.25, -5.12), Vector3(3.9, 2.15, 0.15), "080e1b")
	tv_screen = room_box(Vector3(1.25, 2.25, -5.025), Vector3(3.65, 1.92, 0.025), "122846", 0.7)
	var content_start = game.bedroom.get_child_count()
	wall_text("MIDNIGHT CIRCUIT", Vector3(1.25, 2.91, -4.99), 33, Color("a6d9ff"))
	wall_text("PLAYER 01   /   02480", Vector3(1.25, 1.5, -4.98), 18, Color("71baf1"))
	for i in range(5): room_box(Vector3(-0.05 + i * 0.65, 1.9 + (i % 2) * 0.3, -4.99), Vector3(0.5, 0.045, 0.025), "69c5e0", 0.7)
	tv_runner = room_box(Vector3(0, 2.15, -4.96), Vector3(0.1, 0.16, 0.03), "f5c77a", 1)
	for node in game.bedroom.get_children().slice(content_start): tv_content.append(node)
	room_box(Vector3(0.15, 1.02, -4.58), Vector3(0.72, 0.15, 0.44), "101a2c")
	room_box(Vector3(0.15, 1.106, -4.5), Vector3(0.5, 0.012, 0.025), "76baff", 1.5)
	game.orb(game.bedroom, Vector3(1.45, 1.02, -4.45), Vector3(0.48, 0.12, 0.28), game.material(Color("8498b1")))
	for side in [-1, 1]: room_box(Vector3(1.45 + side * 0.12, 1.09, -4.43), Vector3(0.06, 0.025, 0.06), "10192a")
	for i in range(5): room_box(Vector3(2.28 + i * 0.12, 1.14, -4.6), Vector3(0.075, 0.38, 0.28), ["50688e", "8c5f6b", "71908c"][i % 3])
	add_interaction("tv", Vector3(1.25, 2, -4.9), "SWITCH TV ON / OFF", 3.2)
	add_interaction("game", Vector3(0.15, 1, -4.3), "PLAY MIDNIGHT CIRCUIT", 2.1)
	# Gaming desk, keyboard, PC tower, chair and bookshelves.
	game.solid(game.bedroom, Vector3(3.65, 0.88, -1.35), Vector3(2.1, 0.15, 1.25), Color("69564c"))
	for x in [2.8, 4.5]: room_box(Vector3(x, 0.42, -1.35), Vector3(0.08, 0.85, 0.9), "151e2d")
	room_box(Vector3(3.7, 1.5, -1.77), Vector3(1.45, 0.82, 0.12), "111927")
	room_box(Vector3(3.7, 1.5, -1.69), Vector3(1.3, 0.67, 0.025), "29476c", 0.5)
	wall_text("SAVE YOUR PROGRESS_", Vector3(3.7, 1.52, -1.66), 18, Color("8fd6ff"))
	room_box(Vector3(3.7, 0.99, -1.1), Vector3(1.05, 0.055, 0.31), "172439")
	for i in range(12): room_box(Vector3(3.23 + i * 0.084, 1.022, -1.1), Vector3(0.035, 0.008, 0.23), "75a7d4", 0.5)
	room_box(Vector3(4.4, 1.25, -1.3), Vector3(0.3, 0.65, 0.65), "0b172a")
	for y in [1.1, 1.4]: game.orb(game.bedroom, Vector3(4.4, y, -0.96), Vector3(0.19, 0.19, 0.025), game.material(Color("5f9bd6"), 1))
	room_box(Vector3(3.7, 0.52, 0), Vector3(0.8, 0.12, 0.75), "1c2a41")
	room_box(Vector3(3.7, 1.02, 0.33), Vector3(0.8, 1.05, 0.12), "243b56")
	room_box(Vector3(3.7, 0.25, 0), Vector3(0.08, 0.5, 0.08), "79899a")
	add_interaction("desk", Vector3(3.7, 1.4, -1.2), "CHECK YOUR GAME", 2.2)
	for shelf_y in [2.5, 3.2]:
		room_box(Vector3(4.68, shelf_y, -0.8), Vector3(0.45, 0.08, 2.6), "69564c")
		for i in range(6): room_box(Vector3(4.67, shelf_y + 0.23, -1.8 + i * 0.19), Vector3(0.3, 0.4 + (i % 2) * 0.08, 0.12), ["597e9d", "ab8e70", "7f6385"][i % 3])
	# Acoustic wall designs, framed art and a moonlit window with blinds.
	for i in range(7):
		var panel = room_box(Vector3(-3.7 + i * 0.42, 2.95, -5.24), Vector3(0.24, 1.25, 0.08), "3b5874" if i % 2 else "29425f")
		panel.rotation.z = 0.2
	for i in range(3):
		room_box(Vector3(-4.84, 2.3, 1.1 + i * 1.15), Vector3(0.08, 1.25, 0.9), "ba9e7a")
		room_box(Vector3(-4.78, 2.3, 1.1 + i * 1.15), Vector3(0.025, 1.1, 0.76), ["244769", "513951", "33575d"][i])
		game.orb(game.bedroom, Vector3(-4.75, 2.5, 1.1 + i * 1.15), Vector3(0.025, 0.32, 0.32), game.material(Color("b9b0a0")))
	room_box(Vector3(4.86, 2.3, 2.8), Vector3(0.08, 2.05, 2.2), "7290a8")
	room_box(Vector3(4.8, 2.3, 2.8), Vector3(0.025, 1.85, 2), "0a1530", 0.3)
	for i in range(7): room_box(Vector3(4.74, 1.5 + i * 0.26, 2.8), Vector3(0.08, 0.06, 2.08), "516e8b")
	game.orb(game.bedroom, Vector3(4.72, 2.8, 3.3), Vector3(0.025, 0.4, 0.4), game.material(Color("c2dfff"), 1))
	room_box(Vector3(3.9, 0.34, 4.5), Vector3(0.6, 0.65, 0.6), "8e715e")
	for i in range(7):
		var leaf = game.orb(game.bedroom, Vector3(3.9 + sin(i * 2.4) * 0.32, 0.9 + i * 0.09, 4.5 + cos(i * 2.4) * 0.24), Vector3(0.22, 0.7, 0.18), game.material(Color("42665c")))
		leaf.rotation.z = sin(i * 2.4) * 0.7
	room_box(Vector3(-4, 0.35, 4.3), Vector3(0.8, 0.7, 0.8), "716b6c")
	room_box(Vector3(0.4, 3.9, 0.5), Vector3(0.045, 0.8, 0.045), "101a28")
	room_box(Vector3(0.4, 3.5, 0.5), Vector3(1.3, 0.12, 0.8), "d8b58c", 0.7)
	var fill = OmniLight3D.new()
	game.bedroom.add_child(fill)
	fill.position = Vector3(1, 2.8, 1.5)
	fill.light_color = Color("87b6f0")
	fill.light_energy = 1.8
	fill.omni_range = 9

func begin_sleep() -> void:
	game.reset_race()
	game.state = "room_entry"
	game.phase_time = 0
	game.blink_count = 0
	game.scare_played = false
	game.tape_revealed = false
	game.bedroom.show()
	game.shadow.hide()
	game.tape.show()
	game.arms.hide()
	game.overlay.hide()
	game.prompt.hide()
	game.veil.color.a = 0
	game.set_lids(0)
	if is_instance_valid(tape_hand): tape_hand.hide()
	if is_instance_valid(portal_room): portal_room.hide()
	game.player.position = Vector3(1000, 0.1, 3.7)
	game.player.velocity = Vector3.ZERO
	game.yaw = 0
	game.pitch = -0.03
	game.objective = "GET SOME REST / GO TO YOUR ROOM"
	game.interaction_text = ""
	game.banner.text = "02:17 AM / ONE MORE NIGHT."
	game.feedback_time = 5
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game.camera.far = 750
	game.camera.position = Vector3(1000, 1.7, 8.5)
	game.camera.rotation = Vector3.ZERO

func set_lids(amount: float) -> void:
	var size = game.get_viewport().get_visible_rect().size
	game.lids_top.position = Vector2.ZERO
	game.lids_top.size = Vector2(size.x, size.y * 0.51 * amount)
	game.lids_bottom.position = Vector2(0, size.y * (1 - 0.51 * amount))
	game.lids_bottom.size = Vector2(size.x, size.y * 0.51 * amount)

func change_phase(next: String) -> void:
	game.state = next
	game.phase_time = 0
	shot_origin = game.camera.position
	shot_rotation = game.camera.rotation
	game.player.velocity = Vector3.ZERO
	game.interaction_text = ""
	game.prompt.hide()

func interaction() -> Dictionary:
	if game.state == "bedroom":
		var best: Dictionary = {}
		var best_score = -100.0
		for item in interactables:
			var offset: Vector3 = item.position - game.camera.position
			var distance = game.player.position.distance_to(item.position)
			var facing = (-game.camera.global_basis.z).dot(offset.normalized())
			if distance < item.radius and facing > 0.55:
				var score = facing * 3 - distance * 0.2
				if score > best_score:
					best_score = score
					best = item
		return best
	if game.state == "explore" and game.tape_revealed:
		var offset = game.tape.position - game.camera.position
		if game.player.position.distance_to(game.tape.position) < 2.3 and (-game.camera.global_basis.z).dot(offset.normalized()) > 0.55:
			return {"id": "tape", "text": "PICK UP THE TAPE"}
	return {}

func update_interaction() -> void:
	var item = interaction()
	game.interaction_text = "[ E ]  " + item.text if not item.is_empty() else ""

func interact() -> void:
	var item = interaction()
	if item.is_empty(): return
	match item.id:
		"bed":
			change_phase("sleep")
			game.arms.hide()
			game.objective = ""
			game.banner.text = "JUST CLOSE YOUR EYES."
			game.feedback_time = 6
		"tv":
			tv_on = not tv_on
			tv_screen.material_override = game.material(Color("122846") if tv_on else Color("050914"), 0.7 if tv_on else 0)
			tv_runner.visible = tv_on
			for node in tv_content: node.visible = tv_on
			game.beep(420 if tv_on else 180)
		"lamp":
			lamp_on = not lamp_on
			bedside_light.visible = lamp_on
			game.beep(300)
		"game", "desk":
			game.banner.text = "SAVE COMPLETE / YOUR LAST RUN CAN WAIT UNTIL MORNING."
			game.feedback_time = 4
			game.beep(620)
		"tape": game.trigger_tape()

func wake_up() -> void:
	change_phase("wake")
	game.bedroom.hide()
	game.player.position = Vector3(0, 0.1, 1016)
	game.yaw = 0
	game.pitch = 0
	game.set_lids(0)
	game.veil.color.a = 1
	game.arms.hide()
	game.objective = ""
	game.banner.text = "THIS WAS YOUR WORLD. WHAT HAPPENED TO IT?"
	game.feedback_time = 8

func reveal_tape() -> void:
	game.tape_revealed = true
	change_phase("tape_reveal")
	game.arms.hide()
	game.banner.text = "SOMETHING HERE DOESN'T BELONG."
	game.feedback_time = 5

func trigger_tape() -> void:
	if game.state != "explore" or not game.tape_revealed: return
	change_phase("tape_grab")
	grab_origin = game.camera.position
	grab_rotation = game.camera.rotation
	game.arms.hide()
	game.objective = ""
	game.banner.text = "IT WAS WAITING FOR YOU."
	game.feedback_time = 4
	if not is_instance_valid(tape_hand): build_tape_hand()
	tape_hand.show()
	tape_hand.position = game.tape.position
	game.play_scream()
	game.scare_played = true

func build_tape_hand() -> void:
	tape_hand = Node3D.new()
	tape_hand.name = "TapeGrabbingHand"
	game.add_child(tape_hand)
	var skin = game.material(Color("262d47"))
	game.orb(tape_hand, Vector3.ZERO, Vector3(0.38, 0.53, 0.19), skin)
	game.capsule(tape_hand, Vector3(0, -0.17, 0), Vector3(0, -0.95, 0.06), 0.115, skin)
	for i in range(5):
		var finger = Node3D.new()
		tape_hand.add_child(finger)
		finger.position = Vector3(-0.105 + (i - 1) * 0.07, 0.18, 0)
		if i == 0:
			finger.position = Vector3(-0.15, -0.02, 0)
			finger.rotation.z = 0.65
		var length = 0.22 if i == 0 else (0.3 if i in [1, 4] else 0.36)
		game.character_models.finger_segment(finger, Vector3.ZERO, Vector3(0, length * 0.55, 0), 0.045, skin)
		game.character_models.finger_segment(finger, Vector3(0, length * 0.55, 0), Vector3(0, length, -0.04), 0.033, skin)
		grab_fingers.append(finger)

func camera_shot(from: Vector3, to: Vector3, target: Vector3, amount: float) -> void:
	game.camera.position = from.lerp(to, smoothstep(0, 1, clampf(amount, 0, 1)))
	if game.camera.position.distance_to(target) > 0.05: game.camera.look_at(target, Vector3.UP)

func finish_look_control() -> void:
	game.yaw = game.camera.rotation.y
	game.pitch = clampf(game.camera.rotation.x, -1.35, 1.35)
	game.arms.show()

func begin_race_intro() -> void:
	change_phase("track_wake")
	game.player.position = Vector3(0, 0.1, -3)
	game.shadow.show()
	game.shadow.position = Vector3(1.8, 0.05, -7)
	game.shadow.rotation.y = PI
	game.shadow_visual.get_node("Mouth").scale.y = 0.035
	game.camera.position = Vector3(0, 0.6, -2)
	game.veil.color.a = 1
	game.tape.hide()
	tape_hand.hide()
	if is_instance_valid(portal_room): portal_room.show()
	game.banner.text = "YOU ARE NOT ALONE."
	game.feedback_time = 6
	game.yaw = 0
	game.pitch = 0

func animate_world(dt: float) -> void:
	for item in floating_fragments:
		item.node.position.y = item.y + sin(game.clock * 0.35 + item.phase) * item.bob
		item.node.rotation.y += dt * item.spin
	if tv_on and is_instance_valid(tv_runner):
		tv_runner.position.x = 1.25 + sin(game.clock * 0.8) * 1.25
		tv_runner.position.y = 2.15 + absf(sin(game.clock * 2)) * 0.25

func tick(dt: float) -> void:
	var t: float = game.phase_time
	match game.state:
		"room_entry":
			camera_shot(Vector3(1000, 1.7, 8.5), Vector3(1000, 1.7, 3.7), Vector3(999.4, 1.5, -2), t / 4)
			game.camera.position.y += sin(t * 6) * 0.018
			if t >= 4:
				change_phase("bedroom")
				finish_look_control()
				game.objective = "GO TO BED / EXPLORE YOUR ROOM / E TO INTERACT"
				game.banner.text = "YOUR SAVE CAN WAIT. GET SOME SLEEP."
				game.feedback_time = 5
		"sleep":
			camera_shot(shot_origin, Vector3(997.35, 1.38, -1.55), Vector3(997.35, 3.3, 1.4), t / 2.2)
			var close = 0.0
			for i in range(3):
				var local = t - (2.3 + i * 1.65)
				if local >= 0 and local <= 1.3: close = sin(clampf(local / 1.3, 0, 1) * PI)
				if t >= 2.95 + i * 1.65: game.blink_count = maxi(game.blink_count, i + 1)
			if t >= 6.25: close = 1
			game.set_lids(close)
			if t >= 7.4: game.wake_up()
		"wake":
			game.veil.color.a = maxf(0, 1 - t / 1.8)
			game.camera.position = Vector3(0, lerpf(0.6, 1.76, smoothstep(0, 1, minf(t / 2, 1))), 1016)
			var yaw = 0.0
			if t < 2: yaw = lerpf(0.0, -0.85, smoothstep(0, 1, t / 2))
			elif t < 4.5: yaw = lerpf(-0.85, 0.9, smoothstep(0, 1, (t - 2) / 2.5))
			else: yaw = lerpf(0.9, 0, smoothstep(0, 1, (t - 4.5) / 2))
			game.camera.rotation = Vector3(0.18 + sin(t * 0.7) * 0.13, yaw, sin(t) * 0.015)
			if t >= 6.5:
				change_phase("explore")
				game.camera.rotation = Vector3.ZERO
				finish_look_control()
				game.objective = "FIND A WAY THROUGH / WALK FORWARD"
		"tape_reveal":
			var closeup: Vector3 = game.tape.position + Vector3(-0.15, 0.85, 1.15)
			camera_shot(shot_origin, closeup, game.tape.position + Vector3(0, 0.06, 0), minf(t / 2.3, 1))
			if t > 3.4: camera_shot(closeup, game.player.position + Vector3(0, 1.66, 0), game.tape.position, (t - 3.4) / 1.3)
			if t >= 4.7:
				change_phase("explore")
				finish_look_control()
				game.objective = "INSPECT THE TAPE / APPROACH IT AND PRESS E"
		"tape_grab":
			var tape_p: Vector3 = game.tape.position
			var reach: Vector3 = grab_origin - game.camera.global_basis.z * 0.8 + Vector3(0, -0.25, 0)
			tape_hand.position = (tape_p + Vector3(0, -0.5, 0)).lerp(reach, smoothstep(0, 1, minf(t / 1.1, 1)))
			tape_hand.scale = Vector3.ONE * lerpf(0.3, 0.85, clampf(t / 1.1, 0, 1))
			tape_hand.look_at(grab_origin + Vector3(0, 0.12, 0), Vector3.UP)
			for i in range(grab_fingers.size()): grab_fingers[i].rotation.x = lerpf(0.15, -1.25, smoothstep(0, 1, (t - 0.9) / 0.5))
			if t < 1.2:
				game.camera.position = grab_origin
				game.camera.rotation = grab_rotation
			else:
				var pull = smoothstep(0, 1, (t - 1.2) / 1.8)
				game.camera.position = grab_origin.lerp(tape_p + Vector3(0, 0.11, 0.08), pull)
				game.camera.look_at(tape_p - Vector3(0, 0.15, 0.08))
				game.camera.rotation.z = sin(t * 27) * 0.05 + pull * 0.7
				tape_hand.position = game.camera.position - game.camera.global_basis.z * 0.72 - game.camera.global_basis.y * 0.22
				game.camera.fov = lerpf(85, 112, pull)
			game.veil.color.a = smoothstep(0, 1, (t - 2.5) / 0.55)
			if t >= 3.4: begin_race_intro()
		"track_wake":
			game.veil.color.a = maxf(0, 1 - t / 1.5)
			camera_shot(Vector3(0, 0.6, -2), Vector3(0, 1.76, -3), game.shadow.position + Vector3(0, 1.5, 0), t / 2.3)
			game.camera.fov = lerpf(game.camera.fov, 78, dt * 2)
			if t >= 3.2:
				change_phase("race_flyover")
				game.banner.text = "THE ONLY WAY BACK IS AT THE END."
				game.feedback_time = 12
		"race_flyover":
			game.shadow.rotation.y = lerp_angle(PI, 0, smoothstep(0, 1, t / 1.3))
			var near_goal = Vector3(0, 3.5, -game.FINISH + 10)
			if t < 1.8: camera_shot(shot_origin, Vector3(0, 7, -16), Vector3(0, 3, -42), t / 1.8)
			elif t < 8:
				var progress = smoothstep(0, 1, (t - 1.8) / 6.2)
				var p = Vector3(sin(progress * PI) * 2, lerpf(7, 3.5, progress), lerpf(-16, near_goal.z, progress))
				game.camera.position = p
				game.camera.look_at(Vector3(0, 2.4, maxf(-game.FINISH - 2, p.z - 22)))
			elif t < 11.5:
				camera_shot(near_goal, Vector3(0, 2.8, -game.FINISH + 5), Vector3(0, 2.1, -game.FINISH - 4), (t - 8) / 3.5)
				game.banner.text = "THAT'S YOU. STILL ASLEEP."
			else:
				var progress = smoothstep(0, 1, (t - 11.5) / 5)
				var p = Vector3(sin(progress * PI) * -2, lerpf(2.8, 1.76, progress) + sin(progress * PI) * 6, lerpf(-game.FINISH + 5, -3, progress))
				game.camera.position = p
				game.camera.look_at(p + Vector3(0, -0.08, -6))
			if t >= 16.5:
				change_phase("ghost_taunt")
				laughed = false
				game.banner.text = "ONLY ONE OF YOU GETS TO WAKE UP."
				game.feedback_time = 6
		"ghost_taunt":
			camera_shot(shot_origin, game.player.position + Vector3(0, 1.66, 0), game.shadow.position + Vector3(0, 1.65, 0), minf(t / 0.6, 1))
			game.shadow.rotation.y = lerp_angle(0, PI, smoothstep(0, 1, t / 0.7))
			if t > 0.7 and t < 2.8:
				game.shadow_visual.rotation.z = sin(t * 19) * 0.035
				game.shadow_visual.get_node("Mouth").scale.y = 0.065 + absf(sin(t * 12)) * 0.11
				if not laughed:
					laughed = true
					game.game_audio.play_laugh()
			if t > 2.8:
				game.shadow.rotation.y = lerp_angle(PI, 0, smoothstep(0, 1, (t - 2.8) / 0.5))
				game.shadow.position.z -= dt * 4
				game.shadow_visual.get_node("LegL").rotation.x = sin(t * 14) * 0.65
				game.shadow_visual.get_node("LegR").rotation.x = -sin(t * 14) * 0.65
			if t >= 3.6:
				game.shadow_visual.rotation = Vector3.ZERO
				game.shadow_visual.get_node("Mouth").scale.y = 0.035
				game.camera.fov = 85
				game.arms.show()
				game.start_real_race(-game.shadow.position.z)
