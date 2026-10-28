extends Node3D
## Rewind campaign director. Gameplay remains in the existing race/boss scenes.
const Props = preload("res://scripts/story_props.gd")
## The title-screen opening hands off to the current Neon Fever levels.
## Leave empty to play the original standalone Rewind campaign.
@export_file("*.tscn") var next_scene: String = ""
var stage: Node3D
var room: Node3D
var camera: Camera3D
var walker: CharacterBody3D
var boombox: Node3D
var cassette: Node3D
var portal: Node3D
var reflection: Node3D
var prisoner: Node3D
var clue_person: Node3D
var clue_shadow: Node3D
var title: Label
var controls: Label
var fade: ColorRect
var phase := "room_entry"
var round_number := 0
var phase_time := 0.0
var yaw := 0.0
var pitch := 0.0
var music: AudioStreamPlayer
var music_playback: AudioStreamGeneratorPlayback
var audio_phase := 0.0
var muted := false
var home_returned := false
var exit_box: Node3D
var exit_portal: Node3D
var bedroom_model: Node3D
var interaction_button: Button
var pull_origin := Vector3.ZERO
var pull_camera := Vector3.ZERO
var pull_strands: Array[MeshInstance3D] = []
var entrance_door: Node3D

func _ready() -> void:
	_build_ui()
	_build_room()
	_build_audio()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	title = Label.new()
	title.position = Vector2(340, 100)
	title.size = Vector2(600, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color("ffd384"))
	layer.add_child(title)
	controls = Label.new()
	controls.position = Vector2(24, 660)
	controls.add_theme_font_size_override("font_size", 18)
	controls.add_theme_color_override("font_color", Color("a4b8c7"))
	layer.add_child(controls)
	interaction_button = Button.new()
	interaction_button.text = "[ E ]"
	interaction_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_button.offset_left = -64
	interaction_button.offset_right = 64
	interaction_button.offset_top = -92
	interaction_button.offset_bottom = -40
	interaction_button.add_theme_font_size_override("font_size", 26)
	interaction_button.focus_mode = Control.FOCUS_NONE
	interaction_button.pressed.connect(_begin_abduction)
	interaction_button.hide()
	layer.add_child(interaction_button)
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.02, 0.01, 0.06, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

func _solid(parent: Node3D, p: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = p
	Props.box(body, Vector3.ZERO, size, color)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

func _build_room() -> void:
	room = Node3D.new()
	room.name = "Bedroom"
	add_child(room)
	_solid(room, Vector3(0, -0.2, 0), Vector3(14, 0.4, 16), Color("1b293e"))
	for side in [-1, 1]:
		_solid(room, Vector3(side * 7, 2.2, 0), Vector3(0.2, 4.4, 16), Color("10213e"))
		_solid(room, Vector3(side * 4.1, 2.2, 8), Vector3(5.8, 4.4, 0.2), Color("10213e"))
		Props.box(room, Vector3(side * 6.85, 4, 0), Vector3(0.03, 0.04, 15.8), Color("4f82bd"), 0.8)
	_solid(room, Vector3(0, 2.2, -8), Vector3(14, 4.4, 0.2), Color("10213e"))
	_solid(room, Vector3(0, 3.8, 8), Vector3(2.4, 1.2, 0.2), Color("10213e"))
	# Visible doorway and short hall for the opening walk-in shot.
	_solid(room, Vector3(0, -0.2, 9.4), Vector3(2.4, 0.4, 3), Color("142138"))
	for side in [-1, 1]:
		Props.box(room, Vector3(side * 1.22, 1.6, 7.9), Vector3(0.12, 3.2, 0.2), Color("41638a"))
		Props.box(room, Vector3(side * 1.3, 1.6, 9.4), Vector3(0.12, 3.2, 3), Color("0b172a"))
	Props.box(room, Vector3(0, 3.22, 7.9), Vector3(2.56, 0.12, 0.2), Color("41638a"))
	entrance_door = Node3D.new()
	entrance_door.name = "EntranceDoor"
	room.add_child(entrance_door)
	entrance_door.position = Vector3(1.15, 0, 7.95)
	entrance_door.rotation.y = 1.35
	Props.box(entrance_door, Vector3(-1.15, 1.55, 0), Vector3(2.3, 3.1, 0.12), Color("193357"))
	Props.box(entrance_door, Vector3(-2, 1.45, -0.1), Vector3(0.2, 0.07, 0.08), Color("9aacc5"))
	for i in range(34): Props.box(room, Vector3(-6.8 + i * 0.4, 0.006, 0), Vector3(0.015, 0.01, 15.8), Color("0e1b2f"))
	_solid(room, Vector3(-2.7, 0.4, -1), Vector3(2.8, 0.8, 4.2), Color("353342"))
	Props.box(room, Vector3(-2.7, 0.92, -1), Vector3(2.8, 0.24, 4.1), Color("b5b4ac"))
	Props.box(room, Vector3(-2.7, 1.08, -0.3), Vector3(2.82, 0.12, 2.8), Color("385875"))
	Props.box(room, Vector3(-2.7, 1.1, -2.6), Vector3(2.2, 0.3, 0.7), Color("ded3ba"))
	_solid(room, Vector3(1.4, 0.5, -4.6), Vector3(4.4, 1, 1), Color("1c304b"))
	boombox = Props.boombox(room, Vector3(1.4, 1.5, -4.6))
	cassette = Props.tape(room, Vector3(1.4, 1.5, -4.28))
	cassette.scale *= 0.6
	Props.box(room, Vector3(0.3, 0.02, 1), Vector3(5.2, 0.03, 5.5), Color("122b4c"))
	Props.box(room, Vector3(3.5, 2.5, -5.85), Vector3(1.8, 1.4, 0.05), Color("b09675"))
	Props.box(room, Vector3(3.5, 2.5, -5.8), Vector3(1.6, 1.2, 0.04), Color("3d5f75"))
	# Mirror faces the room. The ending uses a staged reflected figure.
	Props.box(room, Vector3(6.84, 1.9, 2), Vector3(0.1, 3.1, 1.8), Color("6985a3"))
	Props.box(room, Vector3(6.77, 1.9, 2), Vector3(0.03, 2.9, 1.6), Color("324e71"), 0.2)
	reflection = Props.person(room, Vector3(6.65, 0.55, 2), true)
	reflection.rotation.y = -PI / 2
	reflection.hide()
	prisoner = Props.person(boombox, Vector3(0, -0.16, 0.32))
	prisoner.scale *= 0.18
	prisoner.hide()
	portal = Node3D.new()
	room.add_child(portal)
	portal.position = Vector3(1.4, 2.0, -3.8)
	for i in range(32):
		var angle := i * TAU / 32
		var shard := Props.box(portal, Vector3(cos(angle) * 1.6, sin(angle) * 1.6, 0), Vector3(0.24, 0.4, 0.18), Color("ad70fa"), 3)
		shard.rotation.z = angle
	portal.hide()
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("090b1d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7394c4")
	env.ambient_light_energy = 0.65
	world.environment = env
	room.add_child(world)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 3, 0)
	light.light_color = Color("88adf0")
	light.light_energy = 1.8
	light.omni_range = 15
	room.add_child(light)
	var entrance_light := OmniLight3D.new()
	room.add_child(entrance_light)
	entrance_light.position = Vector3(0, 3, 6.5)
	entrance_light.light_color = Color("aabfe0")
	entrance_light.light_energy = 1.5
	entrance_light.omni_range = 7
	preload("res://scripts/gaming_room.gd").build(room)
	walker = CharacterBody3D.new()
	room.add_child(walker)
	walker.position = Vector3(0, 0.05, 9.3)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	walker.add_child(collision)
	bedroom_model = preload("res://runner/runner.tscn").instantiate()
	walker.add_child(bedroom_model)
	preload("res://scripts/bedroom_outfit.gd").apply(bedroom_model)
	bedroom_model.rotation.y = PI
	bedroom_model.call("play_animation", &"Idle")
	camera = Camera3D.new()
	room.add_child(camera)
	camera.current = true
	camera.position = Vector3(4.5, 2.8, 3.2)
	camera.look_at(walker.position + Vector3.UP)
	controls.text = ""
	for i in range(3):
		var strand := Props.box(room, Vector3.ZERO, Vector3(0.035, 0.035, 1), Color("ad70fa"), 3)
		strand.hide()
		pull_strands.append(strand)

func _set_phase(value: String) -> void:
	phase = value
	phase_time = 0
	controls.text = ""
	title.text = ""
	interaction_button.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and phase in ["race", "boss"]: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.physical_keycode if event.physical_keycode else event.keycode
	if key == KEY_M:
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
	if key == KEY_ESCAPE and phase not in ["race", "boss"] and not has_node("PauseMenu"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if key == KEY_E and phase == "bedroom" and _can_touch_boombox():
		_begin_abduction()
	if key == KEY_ENTER and phase == "complete": get_tree().reload_current_scene()

func _can_touch_boombox() -> bool:
	return walker.global_position.distance_to(boombox.global_position) < 2.8

func _begin_abduction() -> void:
	if phase != "bedroom" or not _can_touch_boombox(): return
	pull_origin = walker.position
	pull_camera = camera.position
	walker.velocity = Vector3.ZERO
	_set_phase("portal")
	portal.show()
	bedroom_model.call("play_animation", &"hurt", 0.05)
	for strand in pull_strands: strand.show()

func _physics_process(dt: float) -> void:
	if phase != "bedroom": return
	var x := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	var z := float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	var direction := Vector3(x, 0, z).normalized()
	walker.velocity = direction * 4 + Vector3(0, -2, 0)
	walker.move_and_slide()
	if direction.length_squared() > 0.01:
		bedroom_model.rotation.y = lerp_angle(bedroom_model.rotation.y, atan2(direction.x, direction.z), minf(dt * 12, 1))
	bedroom_model.call("play_animation", &"Run" if direction.length_squared() > 0.01 else &"Idle", 0.15)
	var target := walker.position + Vector3(0, 3.1, 4.3)
	target.z = minf(target.z, 7.5)
	target.x = clampf(target.x, -6.4, 6.4)
	camera.position = camera.position.lerp(target, 1 - exp(-8 * dt))
	camera.look_at(walker.position + Vector3(0, 1, -0.5))
	interaction_button.visible = _can_touch_boombox()

func _process(dt: float) -> void:
	phase_time += dt
	_fill_audio()
	match phase:
		"room_entry": _tick_room_entry(dt)
		"portal":
			_tick_abduction(dt)
		"race", "boss":
			fade.color.a = maxf(0, 1 - phase_time)
			title.text = ("FINAL ROUND" if phase == "boss" else "ROUND %d" % round_number) if phase_time < 2.8 else ""
			if phase == "boss":
				stage._hud_action.visible = stage.phase == "QTE"
				stage._hud_action.text = stage.qte_key
		"between": _tick_between(dt)
		"ending": _tick_ending(dt)

func _tick_room_entry(dt: float) -> void:
	var t := phase_time
	var progress := clampf(t / 3.4, 0, 1)
	walker.position = Vector3(0, 0.05, lerpf(9.3, 4.4, smoothstep(0, 1, progress)))
	bedroom_model.rotation.y = PI
	bedroom_model.call("play_animation", &"Run" if t < 3.4 else &"Idle", 0.2)
	# Slow the existing locomotion clip into a relaxed walk.
	bedroom_model.animation_player.speed_scale = 0.55 if t < 3.4 else 1.0
	entrance_door.rotation.y = lerpf(1.35, 0, smoothstep(2.4, 4.1, t))
	if t < 3.4:
		camera.position = Vector3(4.5, 2.8, 3.2).lerp(Vector3(3, 2.8, 1.5), progress)
		camera.look_at(walker.position + Vector3.UP)
	else:
		var blend := smoothstep(3.4, 5.5, t)
		camera.position = Vector3(3, 2.8, 1.5).lerp(Vector3(0, 3.15, 7.5), blend)
		camera.look_at(walker.position + Vector3(0, 1, -0.5))
	if t >= 5.5:
		_set_phase("bedroom")
		bedroom_model.animation_player.speed_scale = 1
		_solid(room, Vector3(0, 1.5, 8), Vector3(2.4, 3, 0.15), Color("193357"))
		room.get_child(room.get_child_count() - 1).get_child(0).hide()

func _tick_abduction(dt: float) -> void:
	var t := phase_time
	portal.rotation.z += dt * (3 + t * 4)
	portal.scale = Vector3.ONE * (0.75 + minf(t, 1) * 0.35 + sin(t * 28) * 0.05)
	boombox.position.x = 1.4 + sin(t * 55) * 0.035
	var destination := Vector3(1.4, 1.15, -3.95)
	if t < 0.65:
		# A violent recoil before the pull catches the body.
		walker.position = pull_origin + Vector3(sin(t * 35) * 0.05, 0, sin(t / 0.65 * PI) * 0.32)
		bedroom_model.rotation.x = -sin(t / 0.65 * PI) * 0.35
	else:
		var amount := clampf((t - 0.65) / 2.2, 0, 1)
		walker.position = pull_origin.lerp(destination, amount * amount)
		walker.position.y += sin(amount * PI) * 0.65
		bedroom_model.rotation.y = lerp_angle(bedroom_model.rotation.y, 0, dt * 8)
		bedroom_model.rotation.x = -0.65 * minf(amount * 3, 1)
		bedroom_model.rotation.z = sin(t * 22) * 0.13
		bedroom_model.scale = Vector3.ONE * (1 - smoothstep(0.65, 1, amount) * 0.95)
	var focus := walker.position + Vector3.UP
	var shot := pull_camera.lerp(Vector3(3.5, 2.8, 0), clampf(t / 1.8, 0, 1))
	camera.position = shot + Vector3(sin(t * 63), cos(t * 49), 0) * minf(t * 0.035, 0.1)
	camera.look_at(focus.lerp(portal.position, 0.35))
	camera.fov = 75 + sin(t * 21) * 2 + minf(t * 5, 14)
	for i in range(pull_strands.size()):
		var end := walker.position + Vector3((i - 1) * 0.23, 1.1, 0)
		var start := boombox.position + Vector3((i - 1) * 0.2, 0.1, 0.3)
		var strand := pull_strands[i]
		strand.position = (start + end) * 0.5
		strand.scale.z = maxf(start.distance_to(end), 0.01)
		if start.distance_to(end) > 0.01: strand.look_at(end)
	fade.color.a = smoothstep(2.65, 3.15, t)
	if t > 3.3:
		if not next_scene.is_empty():
			set_process(false)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_tree().change_scene_to_file(next_scene)
			return
		for strand in pull_strands: strand.hide()
		bedroom_model.hide()
		boombox.position.x = 1.4
		start_round(1)

func start_round(number: int) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	round_number = number
	room.hide()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	camera.current = false
	if is_instance_valid(stage):
		remove_child(stage)
		stage.queue_free()
	var path := "res://scenes/bossfight.tscn" if number == 4 else "res://scenes/runner_race.tscn"
	stage = load(path).instantiate()
	stage.set_meta("story_round", number)
	stage.story_finished.connect(_round_finished)
	add_child(stage)
	if number < 4:
		var course := preload("res://scripts/story_course.gd").new()
		course.name = "StoryCourse"
		stage.add_child(course)
		stage.rival.run_speed = 7.4 + number * 0.3
		stage.rival.jump_chance_per_decision = 0.25
		stage.rival.dive_chance_per_decision = 0.08
		stage.player.status_label = null
	else:
		stage.player.status_label = null
	_set_phase("boss" if number == 4 else "race")
	_strip_gameplay_text(stage)
	controls.text = "WASD run  ·  Space jump / hold glide  ·  Shift dive  ·  Q E R F counter"
	fade.color.a = 1

func _strip_gameplay_text(node: Node) -> void:
	# Story is visual. Keep only the required QTE input in the boss HUD.
	for child in node.get_children():
		if child is Label or child is Label3D:
			child.hide()
		_strip_gameplay_text(child)

func _round_finished() -> void:
	# Defer removal until the emitting gameplay callback has returned.
	call_deferred("_begin_transition")

func _begin_transition() -> void:
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	if round_number == 4:
		_set_phase("ending")
		home_returned = false
		stage.rival.visual.call("play_animation", &"hurt", 0.1)
		cassette.reparent(stage)
		cassette.position = stage.rival.position + Vector3(0, 0.8, 0)
		cassette.scale = Vector3.ONE
		cassette.show()
		exit_box = Props.boombox(stage, stage.rival.position + Vector3(0, 0.8, -3))
		exit_portal = Node3D.new()
		stage.add_child(exit_portal)
		exit_portal.position = exit_box.position + Vector3(0, 1, -1)
		for i in range(28):
			var angle := i * TAU / 28
			Props.box(exit_portal, Vector3(cos(angle) * 1.7, sin(angle) * 1.7, 0), Vector3(0.22, 0.3, 0.16), Color("65f5db"), 2)
		exit_portal.hide()
		stage._camera.current = true
		stage._camera.position = stage.rival.position + Vector3(3, 2, 4)
		stage._camera.look_at(stage.rival.position + Vector3.UP)
	else:
		_set_phase("between")
		stage.player.camera.current = true
		clue_person = Props.person(stage, Vector3(0, 0, -196))
		clue_shadow = Props.person(stage, Vector3(0.2, 0, -195.8), true)
		for i in range(round_number + 2):
			var damaged := Props.tape(stage, Vector3(-2 + i, 0.5, -194))
			damaged.rotation.z = i * 0.5
			Props.box(damaged, Vector3(0, -0.4, 0), Vector3(0.025, 0.7, 0.025), Color("392238"))

func _tick_between(dt: float) -> void:
	var cam: Camera3D = stage.player.camera
	cam.global_position = cam.global_position.lerp(Vector3(0, 2.8, -189), minf(dt * 2, 1))
	cam.look_at(Vector3(0, 1, -196))
	clue_shadow.position.x = minf(phase_time * 0.3, 1.7)
	clue_person.position.x = -minf(phase_time * 0.2, 1.1)
	clue_person.rotation.z = sin(phase_time * 3) * 0.08
	# The tape retreats beyond reach after every victory.
	stage.get_node("StoryCourse").goal.position.z -= dt * 4
	fade.color.a = clampf((phase_time - 5.5) / 1.5, 0, 1)
	if phase_time > 7: start_round(round_number + 1)

func _tick_ending(dt: float) -> void:
	if phase_time < 3:
		stage.rival.visual.scale = Vector3.ONE * maxf(0.01, 1 - phase_time / 3)
	elif phase_time < 6:
		if is_instance_valid(exit_box):
			cassette.position = cassette.position.lerp(exit_box.position + Vector3(0, 0, 0.3), minf(dt * 3, 1))
			stage._camera.position = stage._camera.position.lerp(exit_box.position + Vector3(0, 1.7, 4), minf(dt * 2, 1))
			stage._camera.look_at(exit_box.position + Vector3.UP * 0.4)
			exit_portal.visible = phase_time > 4
			exit_portal.rotation.z += dt
		fade.color.a = clampf((phase_time - 4.5) / 1.3, 0, 1)
	elif not home_returned:
		home_returned = true
		stage.hide()
		room.show()
		room.process_mode = Node.PROCESS_MODE_INHERIT
		bedroom_model.show()
		bedroom_model.scale = Vector3.ONE
		bedroom_model.rotation = Vector3(0, PI, 0)
		bedroom_model.call("play_animation", &"Idle", 0.1)
		walker.position = Vector3(2.5, 0.05, 2.8)
		cassette.reparent(boombox)
		cassette.position = Vector3(0, 0, 0.32)
		cassette.scale = Vector3.ONE * 0.6
		portal.hide()
		camera.current = true
		camera.position = Vector3(0, 1.7, 3)
	elif phase_time < 11:
		fade.color.a = maxf(0, 1 - (phase_time - 6))
		camera.position = camera.position.lerp(Vector3(2.6, 1.7, 1.2), dt * 0.6)
		camera.look_at(Vector3(6.7, 1.6, 2))
		reflection.visible = phase_time > 8.5 and (sin(phase_time * 35) > -0.3)
	elif phase_time < 16:
		reflection.show()
		prisoner.show()
		cassette.hide()
		camera.position = camera.position.lerp(Vector3(1.4, 1.7, -2.7), dt * 1.4)
		camera.look_at(boombox.global_position)
		prisoner.rotation.z = sin(phase_time * 4) * 0.12
	else:
		_set_phase("complete")
		title.text = "YOU WIN"
		controls.text = "Enter  ·  Replay"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_audio() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.15
	music.stream = stream
	music.volume_db = -22
	music.play()
	music_playback = music.get_stream_playback()

func _fill_audio() -> void:
	if music_playback == null: return
	var notes := [110.0, 130.81, 164.81, 146.83]
	for i in range(music_playback.get_frames_available()):
		audio_phase += 1.0 / 22050
		var beat := fmod(audio_phase * 2, 1.0)
		var frequency: float = notes[int(audio_phase / 2) % 4]
		if phase in ["portal", "ending"]: frequency *= 1 + sin(audio_phase * 7) * 0.09
		var sample := sin(audio_phase * frequency * TAU) * 0.2 + sin(beat * 90) * exp(-beat * 14) * 0.4
		music_playback.push_frame(Vector2.ONE * sample)
