extends RefCounted
## tutorial implementation.
## game is the shared scene context; call other systems through its delegates.
const LESSONS = [
	["01 / FIND YOUR FEET", "WASD moves relative to where you look. Mouse looks around.\nWalk forward through the blue gate. Your double waits for you."],
	["02 / JUMP THE FRACTURE", "Press SPACE near the edge to jump.\nClear the gap and LAND on the next platform."],
	["03 / HOLD ON TO THE AIR", "Jump, then HOLD SPACE while falling to glide.\nStay in a glide for half a second and land across the gap."],
	["04 / DIVE THE SLOPE", "Hold SHIFT while running DOWN the sloped platform.\nBuild speed above 19 m/s before the bottom of the slope."],
	["05 / THE GROUND REMEMBERS", "Mint strips accelerate you. Rose corruption slows you.\nRun over the mint strip, then cross the violet damaged patch."],
	["06 / SOME MEMORIES BREAK", "Jump, then hold SHIFT to strike the amber platform hard.\nFracture it, then escape onto the next platform before it falls."],
	["07 / FIGHT FOR YOUR BODY", "Your double tries to take control.\nPress the displayed Q / E / R / F key within TWO seconds.\nYou must succeed. A mistake repeats this lesson."]
]

var game

func setup(context: Node3D) -> void:
	game = context

func enter_lesson(step: int) -> void:
	game.tutorial_step = step
	game.tutorial_waiting = true
	game.tutorial_progress = 0
	game.tutorial_airtime = 0
	game.tutorial_did_action = false
	game.state = "tutorial"
	game.qte_time = 0
	game.boost = 0
	game.slow = 0
	game.player.velocity = Vector3.ZERO
	var starts = [4.0, 33.0, 33.0, 44.0, 20.0, 69.0, 94.0]
	game.player.position = Vector3(0, 0.1, -starts[step])
	var index = game.tile_at(starts[step])
	if index >= 0: game.player.position.y = game.platforms[index].y + sin(game.platforms[index].slope) * (starts[step] - (game.platforms[index].start + game.platforms[index].end) / 2) + 0.15
	game.checkpoint = game.player.position
	if step == 4:
		game.platforms[2].corrupt = true
		game.platforms[2].mesh.material_override = game.material(Color("42295f"), 0.25)
	game.yaw = 0
	game.pitch = 0
	game.tutorial_gate.position = Vector3(0, 1.7, -(12 if step == 0 else 110))
	game.tutorial_gate.visible = step == 0
	game.shadow.position = Vector3(2.4, 0, game.player.position.z - 8)
	game.shadow.rotation.y = 0
	game.tutorial_panel.show()
	game.tutorial_label.text = game.LESSONS[step][0] + " / WORLD PAUSED\n" + game.LESSONS[step][1] + "\nENTER to attempt. The race has not started."

func begin_lesson_attempt() -> void:
	game.tutorial_waiting = false
	if game.tutorial_step == 6:
		game.qte_time = 2
		game.qte_key = game.KEYS[randi() % 4]

func complete_lesson() -> void:
	if game.tutorial_step not in game.completed_lessons: game.completed_lessons.append(game.tutorial_step)
	game.beep(760)
	if game.tutorial_step < game.LESSONS.size() - 1:
		game.enter_lesson(game.tutorial_step + 1)
	else:
		game.state = "countdown"
		game.phase_time = 0
		game.tutorial_panel.hide()
		game.tutorial_gate.hide()
		game.player.position = Vector3(0, 0.1, -3)
		game.player.velocity = Vector3.ZERO
		game.yaw = 0
		game.pitch = 0
		game.shadow.position = Vector3(1.8, 0, -4)
		game.banner.text = "NO MORE WAITING. NO MORE SECOND CHANCES."
		game.feedback_time = 5

func check_lesson(dt: float, glide: bool, dive: bool, index: int) -> void:
	var distance = -game.player.position.z
	match game.tutorial_step:
		0:
			if distance >= 12: game.complete_lesson()
		1:
			if game.tutorial_did_action and distance >= 44 and game.player.is_on_floor(): game.complete_lesson()
		2:
			if glide: game.tutorial_airtime += dt
			if game.tutorial_airtime >= 0.5 and distance >= 43 and game.player.is_on_floor(): game.complete_lesson()
		3:
			if dive and index == 2 and game.player.is_on_floor() and -game.player.velocity.z > 19:
				game.tutorial_progress += dt
			if game.tutorial_progress > 0.15: game.complete_lesson()
		4:
			if index == 1 and game.player.is_on_floor(): game.tutorial_did_action = true
			if game.tutorial_did_action and index == 2 and game.player.is_on_floor(): game.complete_lesson()
		5:
			if game.tutorial_progress > 0 and distance >= 90 and game.player.is_on_floor(): game.complete_lesson()
	# Restore failed practice attempts; the shadow and race timer never advance.
	if game.player.position.y < -8 or (game.tutorial_step == 3 and distance > 63 and game.tutorial_progress <= 0) or (game.tutorial_step == 5 and distance > 91 and game.tutorial_progress == 0) or (game.tutorial_step == 2 and distance > 65 and game.tutorial_airtime < 0.5) or (game.tutorial_step == 1 and distance > 45 and not game.tutorial_did_action):
		game.retry_lesson()

func retry_lesson() -> void:
	var step = game.tutorial_step
	if step == 5:
		var p = game.platforms[3]
		p.collapse = -1.0
		p.col.set_deferred("disabled", false)
		p.body.position.y = p.y - 0.6
	game.enter_lesson(step)
	game.tutorial_label.text += "\nAttempt restored. Try again."
