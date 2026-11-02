extends Node3D
## Playable city hub; the level controller owns all parkour movement.
const Props = preload("res://scripts/story_props.gd")
const Progress = preload("res://scripts/city_progress.gd")
const PIECES := [Vector3(54, 4.4, -44), Vector3(-68, 6.4, -92), Vector3(82, 8.4, -148), Vector3(-80, 10.4, -204), Vector3(64, 12.4, -260)]
@onready var player: MovementTestPlayer = $Player
@onready var shadow: Node3D = $Shadow
var phase := "ARRIVAL"
var time := 0.0
var world_time := 0.0
var cinematic: Camera3D
var fade: ColorRect
var prompt: Label
var marker: Label3D
var marker_ui: Label
var piece: Node3D
var piece_home := Vector3.ZERO
var cars: Array[Node3D] = []
var shadow_clip := ""
var player_clip := ""
var launch_origin := Vector3.ZERO
var launch_scale := Vector3.ONE
var sound: AudioStreamPlayer
var audio_clock := 0.0
var direction_arrow: Polygon2D
var shadow_state := "WAITING"
var shadow_route: Array[Vector3] = []
var shadow_route_index := 0
var shadow_enter_time := 0.0

func _ready() -> void:
	set_meta("city_hub", true)
	Progress.active = true
	_build_city()
	_build_ui()
	_build_audio()
	_build_shove()
	_spawn_piece()
	cinematic = Camera3D.new()
	cinematic.fov = 76
	cinematic.far = 1000
	add_child(cinematic)
	_set_control(false)
	if Progress.ejected:
		_begin_ejection()
	elif Progress.arrived:
		_enter_exploration()
	else:
		cinematic.make_current()
		_tick_arrival()

func _set_control(enabled: bool) -> void:
	player.set_physics_process(enabled)
	player.set_process_unhandled_input(enabled)
	player.velocity = Vector3.ZERO
	player.jump_buffer = 0
	player.status_label = null

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)
	prompt = Label.new()
	layer.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -300
	prompt.offset_right = 300
	prompt.offset_top = -90
	prompt.offset_bottom = -35
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 26)
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 6)
	marker_ui = Label.new()
	marker_ui.add_theme_font_size_override("font_size", 22)
	marker_ui.add_theme_color_override("font_color", Color("8ff8f1"))
	marker_ui.add_theme_color_override("font_outline_color", Color("070d20"))
	marker_ui.add_theme_constant_override("outline_size", 7)
	marker_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_ui.hide()
	layer.add_child(marker_ui)
	direction_arrow = Polygon2D.new()
	direction_arrow.name = "PieceDirectionArrow"
	direction_arrow.polygon = PackedVector2Array([Vector2(0, -36), Vector2(29, -4), Vector2(11, -4), Vector2(11, 25), Vector2(-11, 25), Vector2(-11, -4), Vector2(-29, -4)])
	direction_arrow.color = Color("7bf5ef")
	direction_arrow.hide()
	layer.add_child(direction_arrow)
	fade = ColorRect.new()
	layer.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _solid(p: Vector3, size: Vector3, color: Color = Color("18243c")) -> Node3D:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = p
	Props.box(body, Vector3.ZERO, size, color)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body

func _build_city() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	add_child(sun)
	# Skyline is offset beyond the wider playable blocks.
	var city := preload("res://scenes/neon_world.tscn").instantiate()
	city.position.y = 44
	city.district_length = 360
	city.building_offset = 100
	add_child(city)
	_solid(Vector3(0, -0.45, -135), Vector3(240, 0.9, 330), Color("111426"))
	_build_outer_blocks()
	_build_city_boundaries()
	# Boulevard with separate pedestrian areas and moving neon traffic.
	Props.box(self, Vector3(0, 0.012, -135), Vector3(15, 0.02, 330), Color("090c19"))
	for side in [-1, 1]:
		Props.box(self, Vector3(side * 7.6, 0.04, -135), Vector3(0.12, 0.05, 330), Color("20cee3") if side < 0 else Color("e444ae"), 0.8)
		for z in range(-290, 26, 20):
			Props.box(self, Vector3(side * 9, 2.8, z), Vector3(0.12, 5.6, 0.12), Color("243452"))
			Props.box(self, Vector3(side * 9, 5.6, z), Vector3(1.8, 0.1, 0.2), Color("65e8f5"), 1)
			var light := OmniLight3D.new()
			light.position = Vector3(side * 9, 4.8, z)
			light.light_color = Color("63a5e3")
			light.light_energy = 0.7
			light.omni_range = 14
			add_child(light)
	for z in range(-295, 30, 7):
		Props.box(self, Vector3(0, 0.04, z), Vector3(0.12, 0.03, 2.5), Color("ffd27d"), 0.6)
	for i in range(24):
		_build_car(i)
	# Roof terraces connected by steps, vault blocks and wall-run corridors.
	for i in range(PIECES.size()):
		var target: Vector3 = PIECES[i]
		var roof_height: float = target.y - 1.2
		var side := signf(target.x)
		_solid(Vector3(target.x, roof_height * 0.5, target.z), Vector3(10, roof_height, 12))
		Props.box(self, Vector3(target.x, roof_height + 0.025, target.z), Vector3(10.1, 0.05, 12.1), Color("244466"))
		for edge in [-1, 1]:
			Props.box(self, Vector3(target.x + edge * 4.9, roof_height + 0.08, target.z), Vector3(0.08, 0.08, 12), Color("42dce7"), 0.8)
		var steps := ceili(roof_height / 0.8)
		for j in range(steps):
			var h := (j + 1) * roof_height / steps
			_solid(Vector3(target.x - side * 1.5, h * 0.5, target.z + 6 + (steps - j) * 1.8), Vector3(3, h, 1.9), Color("233654"))
		# Parallel walls support the existing wall-run and wall-jump mechanics.
		for offset in [-1.0, 1.0]:
			var wall := _solid(Vector3(target.x + side * 8 + offset * 1.6, 3.5, target.z + 3), Vector3(0.5, 7, 16), Color("17253d"))
			Props.box(wall, Vector3(0, 3.4, 0), Vector3(0.55, 0.08, 16), Color("ea49bd"), 1)
		for j in range(3):
			_solid(Vector3(side * (12 + j * 2.5), 0.4 + j * 0.25, target.z + 16), Vector3(1.4, 0.8 + j * 0.5, 2.5))
	# Low rails and rooftop bridges give multiple routes through the hub.
	for i in range(4):
		var a: Vector3 = PIECES[i]
		var b: Vector3 = PIECES[i + 1]
		var z := (a.z + b.z) * 0.5
		_solid(Vector3(0, 5.5 + i, z), Vector3(32, 0.45, 3), Color("203451"))
		Props.box(self, Vector3(0, 5.8 + i, z - 1.5), Vector3(32, 0.08, 0.08), Color("ca49d4"), 0.9)

func _build_car(index: int) -> void:
	var car := Node3D.new()
	car.name = "NeonCar%02d" % index
	var side := -1 if index % 2 == 0 else 1
	car.position = Vector3(side * 3.5, 0.6, -index * 13)
	if side > 0: car.rotation.y = PI
	add_child(car)
	var color := Color("32d4ec") if side < 0 else Color("f04cb9")
	Props.box(car, Vector3.ZERO, Vector3(1.9, 0.55, 4.2), Color("161d39"))
	Props.box(car, Vector3(0, 0.45, 0.1), Vector3(1.55, 0.65, 1.9), Color("244766"))
	Props.box(car, Vector3(0, -0.22, 0), Vector3(2.0, 0.07, 4.3), color, 1.2)
	for edge in [-1, 1]:
		Props.box(car, Vector3(edge * 0.72, 0.03, -2.12), Vector3(0.45, 0.14, 0.03), Color("b5f5ff"), 1)
		Props.box(car, Vector3(edge * 0.72, 0.03, 2.12), Vector3(0.45, 0.14, 0.03), Color("ff3868"), 1)
		for z in [-1.35, 1.35]:
			Props.box(car, Vector3(edge, -0.25, z), Vector3(0.2, 0.5, 0.65), Color("080b16"))
	cars.append(car)

func _spawn_piece() -> void:
	if Progress.piece_index >= PIECES.size():
		return
	piece_home = PIECES[Progress.piece_index]
	piece = Props.tape(self, piece_home)
	piece.name = "ActivePiece"
	piece.add_to_group("city_piece")
	var light := OmniLight3D.new()
	light.light_color = Color("8b6aff")
	light.light_energy = 2
	light.omni_range = 8
	piece.add_child(light)
	marker = Label3D.new()
	marker.text = "●".repeat(Progress.piece_index + 1)
	marker.font_size = 64
	marker.pixel_size = 0.014
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = false
	marker.modulate = Color("7cf4ec")
	marker.position = piece_home + Vector3.UP * 3
	marker.hide()
	add_child(marker)
	Props.box(self, piece_home - Vector3.UP * 0.8, Vector3(1.5, 0.12, 1.5), Color("784be6"), 1)
	if Progress.piece_index == Progress.LEVELS.size() - 1:
		_build_home_window()

func _build_home_window() -> void:
	# The final tape shows the bedroom itself: the captive is running for home.
	var view := SubViewport.new()
	view.name = "HomeWindow"
	view.size = Vector2i(512, 288)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	view.add_child(preload("res://scripts/title_bedroom.gd").new())
	var window := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(3.6, 2.1)
	window.mesh = quad
	window.position = piece_home + Vector3(0, 2, 0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = view.get_texture()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	window.material_override = material
	add_child(window)
	for side in [-1, 1]:
		Props.box(self, window.position + Vector3(side * 1.9, 0, 0), Vector3(0.08, 2.3, 0.08), Color("ad70fa"), 2)
		Props.box(self, window.position + Vector3(0, side * 1.1, 0), Vector3(3.9, 0.08, 0.08), Color("ad70fa"), 2)

func _clip(model: Node3D, name: String, is_shadow: bool = false) -> void:
	if (shadow_clip if is_shadow else player_clip) == name: return
	model.call("play_animation", StringName(name), 0.12)
	if is_shadow: shadow_clip = name
	else: player_clip = name

func _shot(position: Vector3, focus: Vector3, roll: float = 0) -> void:
	cinematic.position = position
	cinematic.look_at(focus)
	cinematic.rotation.z = roll

func _tick_arrival() -> void:
	var t := time
	fade.color.a = 1 - smoothstep(0, 1.4, t)
	cinematic.fov = 60 if t >= 4 and t < 7 else 76
	var home := Vector3(-12, 0.05, 10)
	player.position = home
	if t < 14:
		shadow.position = home + Vector3(0, 0, 2.6)
		shadow.rotation.y = PI
		shadow.visible = t >= 10.0
	player.visual.visible = t >= 4 and t < 7 or t >= 18
	if t < 4:
		# Wake on the pavement, then sit up and scan the skyline in first person.
		_clip(player.visual, "Idle")
		var eye := home + Vector3(0, lerpf(0.35, 1.65, smoothstep(0, 2.6, t)), 0)
		_shot(eye, eye + Vector3(sin(t * 0.9) * 16, 5, -25), sin(t * 0.8) * 0.03)
	elif t < 7:
		# Reverse close-up shows the existing character's shocked face.
		player.visual.rotation.y = sin((t - 4) * 2) * 0.55
		player.visual.call("set_expression", "surprised")
		_shot(home + Vector3(0, 1.65, 1.65), home + Vector3(0, 1.45, 0))
	elif t < 10:
		var eye := home + Vector3(0, 1.65, 0)
		var angle := lerpf(-1.0, 1.0, smoothstep(7, 9, t))
		if t > 9: angle = lerpf(1.0, PI, smoothstep(9, 10, t))
		_shot(eye, eye + Vector3(sin(angle) * 20, 2, -cos(angle) * 20))
	elif t < 12:
		_clip(shadow, "Idle", true)
		shadow.call("set_expression", "surprised")
		shadow.rotation.z = sin(t * 10) * 0.02
		_shot(home + Vector3(0, 1.65, 0), shadow.position + Vector3(0, 1.5, 0))
	elif t < 14:
		# The captive pushes his pursuer away, then flees deeper into the tape.
		_clip(shadow, "CityShove", true)
		shadow.call("set_expression", "surprised")
		var push := smoothstep(12, 12.6, t)
		shadow.position.z -= push * 1.6
		shadow.rotation.x = -sin(push * PI) * 0.45
		var fall := smoothstep(12.45, 13.2, t)
		_shot(home + Vector3(0, lerpf(1.65, 0.25, fall), -fall * 1.2), shadow.position + Vector3(0, 1.4, 0), fall * 0.95)
		if t > 12.45 and t < 12.7: fade.color.a = 0.2
	elif t < 18:
		if shadow_state == "WAITING": _start_shadow_run()
		_shot(home + Vector3(0, 0.32, -1.2), shadow.position + Vector3.UP, 0.95 * (1 - smoothstep(15, 17, t)))
	else:
		if shadow_state == "WAITING": _start_shadow_run()
		player.visual.rotation = Vector3(0, PI, 0)
		_clip(player.visual, "Idle")
		player.visual.call("set_expression", "surprised")
		var blend := smoothstep(18, 20, t)
		_shot((home + Vector3(0, 0.4, -1.2)).lerp(home + Vector3(0, 3.1, 5.8), blend), home + Vector3(0, 1.2, -2))
	if t >= 20: _enter_exploration()

func _enter_exploration() -> void:
	Progress.arrived = true
	phase = "EXPLORE"
	time = 0
	fade.color.a = 0
	if shadow_state == "WAITING": _start_shadow_run()
	player.visual.show()
	player.visual.rotation = Vector3(0, PI, 0)
	player.visual.call("restore_neutral")
	player.camera.make_current()
	_set_control(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(marker): marker.visible = player.position.distance_to(piece_home) < 24
	elif Progress.piece_index >= Progress.LEVELS.size(): prompt.text = ""

func _can_interact() -> bool:
	return phase == "EXPLORE" and is_instance_valid(piece) and player.global_position.distance_to(piece.global_position) < 2.5

func _interact() -> void:
	if not _can_interact(): return
	phase = "VANISH"
	time = 0
	launch_origin = player.visual.position
	launch_scale = player.visual.scale
	_set_control(false)
	marker.hide()
	marker_ui.hide()
	prompt.text = ""

func _tick_vanish() -> void:
	var amount := smoothstep(0, 0.85, time)
	player.visual.scale = launch_scale * maxf(0.001, 1 - amount)
	player.visual.position = launch_origin + Vector3.UP * amount * 0.8
	if time >= 0.85: player.visual.hide()
	fade.color.a = smoothstep(0.0, 1.3, time)
	if time >= 1.7:
		phase = "LOADING"
		Progress.travel(get_tree(), Progress.LEVELS[Progress.piece_index], true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ENTER and phase == "GAME_OVER":
		Progress.health = Progress.MAX_HEALTH
		_enter_exploration()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		_interact()

func _process(dt: float) -> void:
	time += dt
	world_time += dt
	_fill_audio()
	_update_direction_arrow()
	if phase in ["ARRIVAL", "EXPLORE"]: _tick_shadow(dt)
	for i in range(cars.size()):
		var direction := 1.0 if i % 2 else -1.0
		cars[i].position.z = fposmod(i * 13 + world_time * (9 + i % 3) * direction + 295, 320) - 295
	if is_instance_valid(piece):
		piece.position = piece_home + Vector3.UP * sin(world_time * 2) * 0.16
		piece.rotation.y = world_time * 0.7
	if phase == "ARRIVAL": _tick_arrival()
	elif phase == "VANISH": _tick_vanish()
	elif phase == "EJECTED": _tick_ejection()
	elif phase == "EXPLORE" and is_instance_valid(piece):
		prompt.text = "[ E ]" if _can_interact() else ""
		_update_marker()
		marker.text = "●".repeat(Progress.piece_index + 1)

func _build_audio() -> void:
	sound = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.15
	sound.stream = stream
	sound.volume_db = -25
	add_child(sound)
	sound.play()

func _fill_audio() -> void:
	var playback := sound.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null: return
	for i in range(playback.get_frames_available()):
		audio_clock += 1.0 / 22050
		var pulse := fmod(audio_clock * 1.8, 1.0)
		var sample := sin(audio_clock * TAU * 55) * 0.08 + sin(pulse * 70) * exp(-pulse * 12) * 0.12
		if phase == "ARRIVAL" and time >= 12.45 and time < 12.75:
			sample += sin(audio_clock * TAU * 43) * (1 - (time - 12.45) / 0.3) * 0.7
		playback.push_frame(Vector2.ONE * sample)

func _update_marker() -> void:
	marker_ui.visible = phase == "EXPLORE" and player.position.distance_to(piece_home) < 24
	marker.visible = marker_ui.visible
	if not marker_ui.visible: return
	var cam := get_viewport().get_camera_3d()
	var viewport_size := get_viewport().get_visible_rect().size
	var point := cam.unproject_position(piece_home + Vector3.UP * 2)
	if cam.is_position_behind(piece_home):
		point = Vector2(viewport_size.x - 230 if point.x < viewport_size.x * 0.5 else 20, viewport_size.y * 0.5)
	marker_ui.position = Vector2(clampf(point.x - 90, 20, viewport_size.x - 230), clampf(point.y, 30, viewport_size.y - 120))
	marker_ui.text = "●".repeat(Progress.piece_index + 1) + "  /  %d" % roundi(player.position.distance_to(piece_home))

func _build_shove() -> void:
	# Add an instance-only two-handed shove to the existing shadow skeleton.
	var animator: AnimationPlayer = shadow.get("animation_player")
	var skeleton := shadow.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var clip := Animation.new()
	clip.length = 0.8
	var reference: Animation = animator.get_animation("Idle")
	for side in ["L", "R"]:
		var desired: Dictionary = {}
		for segment in ["UpperArm", "Forearm"]:
			var bone: String = segment + "." + side
			var path := NodePath(str(animator.get_node(animator.root_node).get_path_to(skeleton)) + ":" + bone)
			var track := clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(track, path)
			var neutral := Quaternion.IDENTITY
			for source_track in range(reference.get_track_count()):
				if reference.track_get_path(source_track) == path and reference.track_get_type(source_track) == Animation.TYPE_ROTATION_3D:
					neutral = reference.rotation_track_interpolate(source_track, 0)
			var bone_index := skeleton.find_bone(bone)
			var child_name: String = ("Forearm." if segment == "UpperArm" else "Hand.") + side
			var child_index := skeleton.find_bone(child_name)
			var rest := skeleton.get_bone_global_rest(bone_index)
			var rest_direction := (skeleton.get_bone_global_rest(child_index).origin - rest.origin).normalized()
			var forward := (skeleton.to_local(shadow.global_position + shadow.global_basis.z) - skeleton.to_local(shadow.global_position)).normalized()
			var global_aim := Quaternion(rest_direction, forward) * rest.basis.get_rotation_quaternion()
			var parent_index := skeleton.get_bone_parent(bone_index)
			var parent_aim: Quaternion = desired.get(parent_index, skeleton.get_bone_global_rest(parent_index).basis.get_rotation_quaternion())
			var reach := skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion().inverse() * parent_aim.inverse() * global_aim
			desired[bone_index] = global_aim
			clip.rotation_track_insert_key(track, 0, neutral)
			clip.rotation_track_insert_key(track, 0.23, reach)
			clip.rotation_track_insert_key(track, 0.5, reach)
			clip.rotation_track_insert_key(track, 0.8, neutral)
	var library := animator.get_animation_library("").duplicate() as AnimationLibrary
	animator.remove_animation_library("")
	animator.add_animation_library("", library)
	library.add_animation("CityShove", clip)


func _build_outer_blocks() -> void:
	# Two street grids and alleys spread the search across walkable districts.
	for side in [-1, 1]:
		for row in range(5):
			var z := -22.0 - row * 58
			Props.box(self, Vector3(side * 64, 0.015, z + 15), Vector3(112, 0.025, 9), Color("0b1125"))
			for column in range(3):
				var x: float = side * (27 + column * 34)
				var p := Vector3(x, 0, z)
				var reserved := false
				for tape in PIECES:
					if absf(tape.x - x) < 28 and z > tape.z - 25 and z < tape.z + 48: reserved = true
				if reserved: continue
				var height := 8.0 + (row + column) % 4 * 3.5
				var block := _solid(p + Vector3.UP * height * 0.5, Vector3(18, height, 22))
				for level in range(2, int(height), 3):
					Props.box(block, Vector3(0, level - height * 0.5, 11.02), Vector3(15, 0.35, 0.04), Color("39b6d7") if side < 0 else Color("c646b2"), 0.6)
				Props.box(block, Vector3(0, height * 0.5 + 0.04, 0), Vector3(18.1, 0.08, 22.1), Color("315473"))

func _begin_ejection() -> void:
	Progress.ejected = false
	phase = "EJECTED"
	time = 0
	fade.color.a = 0
	shadow.hide()
	player.position = piece_home + Vector3.UP
	player.visual.show()
	player.visual.call("play_animation", &"hurt", 0.0)
	cinematic.make_current()

func _tick_ejection() -> void:
	var amount := clampf(time / 1.25, 0, 1)
	player.position = piece_home + Vector3(0, lerpf(1.0, -1.15, amount) + sin(amount * PI) * 1.2, amount * 3.0)
	_shot(piece_home + Vector3(5, 3.5, 8), player.position + Vector3.UP)
	if amount >= 1:
		if Progress.health <= 0:
			phase = "GAME_OVER"
			prompt.text = "↻  [ ENTER ]"
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			_enter_exploration()



func _update_direction_arrow() -> void:
	var pulse := fmod(world_time, 3.5)
	direction_arrow.visible = phase == "EXPLORE" and is_instance_valid(piece) and pulse < 0.9
	if not direction_arrow.visible: return
	var cam := get_viewport().get_camera_3d()
	var forward := -cam.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := cam.global_basis.x
	right.y = 0
	right = right.normalized()
	var toward := (piece_home - player.global_position).normalized()
	var screen_direction := Vector2(toward.dot(right), -toward.dot(forward))
	direction_arrow.rotation = screen_direction.angle() + PI / 2
	var viewport_size := get_viewport().get_visible_rect().size
	direction_arrow.position = viewport_size * Vector2(0.5, 0.38)
	direction_arrow.modulate.a = 0.55 + 0.45 * absf(sin(pulse * PI * 3))

func _start_shadow_run() -> void:
	if not is_instance_valid(piece):
		shadow.hide()
		shadow_state = "INSIDE"
		return
	shadow.show()
	shadow.scale = Vector3.ONE
	shadow.rotation = Vector3.ZERO
	shadow.position = Vector3(-12, 0.05, 11)
	shadow_state = "RUNNING"
	shadow_route.clear()
	shadow_route_index = 0
	var height := piece_home.y - 1.2
	var steps := ceili(height / 0.8)
	var side := signf(piece_home.x)
	var approach_z := piece_home.z + 12 + steps * 1.8
	var stair_x := piece_home.x - side * 1.5
	shadow_route.append(Vector3(-10.5, 0.05, 11))
	shadow_route.append(Vector3(-10.5, 0.05, approach_z))
	shadow_route.append(Vector3(stair_x, 0.05, approach_z))
	shadow_route.append(Vector3(stair_x, 0.05, piece_home.z + 7.8 + steps * 1.8))
	for i in range(steps):
		shadow_route.append(Vector3(stair_x, (i + 1) * height / steps + 0.05, piece_home.z + 6 + (steps - i) * 1.8))
	shadow_route.append(piece_home - Vector3.UP * 1.15)
	_clip(shadow, "Run", true)
	shadow.call("set_expression", "surprised")

func _tick_shadow(dt: float) -> void:
	if shadow_state == "RUNNING":
		var movement := dt * 4.5
		while movement > 0 and shadow_route_index < shadow_route.size():
			var destination := shadow_route[shadow_route_index]
			var gap := destination - shadow.position
			var distance := gap.length()
			if distance > 0.01: shadow.rotation.y = atan2(gap.x, gap.z)
			var step := minf(movement, distance)
			shadow.position = shadow.position.move_toward(destination, step)
			movement -= step
			if distance <= step + 0.001: shadow_route_index += 1
		if shadow_route_index >= shadow_route.size():
			shadow_state = "ENTERING"
			shadow_enter_time = 0
	elif shadow_state == "ENTERING":
		shadow_enter_time += dt
		var amount := smoothstep(0, 0.8, shadow_enter_time)
		shadow.position = (piece_home - Vector3.UP * 1.15).lerp(piece_home, amount)
		shadow.scale = Vector3.ONE * (1 - amount)
		if amount >= 1:
			shadow.hide()
			shadow_state = "INSIDE"

func _build_city_boundaries() -> void:
	# Continuous, visible skyscraper blocks close every edge of the hub.
	for side in [-1, 1]:
		for i in range(15):
			var height := 44.0 + (i % 4) * 9
			var tower := _solid(Vector3(side * 130, height * 0.5, 19 - i * 22), Vector3(20, height, 22), Color("101a30"))
			tower.name = "CityBoundarySide_%d_%d" % [side, i]
			for floor_y in range(3, int(height), 5):
				Props.box(tower, Vector3(-side * 10.05, floor_y - height * 0.5, 0), Vector3(0.08, 0.45, 18), Color("34c6de") if side < 0 else Color("da4cae"), 0.8)
	for end in [-310, 40]:
		for i in range(12):
			var height := 46.0 + (i % 3) * 11
			var tower := _solid(Vector3(-110 + i * 20, height * 0.5, end), Vector3(20, height, 20), Color("111d35"))
			tower.name = "CityBoundaryEnd_%d_%d" % [end, i]
			for floor_y in range(3, int(height), 5):
				Props.box(tower, Vector3(0, floor_y - height * 0.5, 10.05 if end < 0 else -10.05), Vector3(17, 0.45, 0.08), Color("6779ed"), 0.8)
