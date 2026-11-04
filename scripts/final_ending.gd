extends "res://scripts/rewind_story.gd"
## Final cinematic: escape, destruction, identity reveal, then the prisoner's fate.
var debris: Array[Node3D] = []
var static_material: ShaderMaterial
var prison: Node3D
var neon_shadow: Node3D
var prison_portal: Node3D
var impact_played := false
var sigh_played := false
var effects: AudioStreamPlayer
var revealed_body: Node3D
var laugh_played := false
var trapped_player: Node3D
var release_boy := false
var choice_panel: Control
var ending_card: Label
var captive_body: Node3D
const City = preload("res://scripts/ending_city.gd")
var ending_city: Node3D
var anger_started := false
var walk_started := false

func _ready() -> void:
	_build_ui()
	_build_room()
	phase = "choice"
	phase_time = 0
	controls.text = ""
	boombox_on = false
	music_fx.playing = false
	portal.show()
	bedroom_model.show()
	_set_eyes(0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	effects = AudioStreamPlayer.new()
	add_child(effects)
	_build_final_props()
	_build_choice()
	ending_city = City.new()
	prison.add_child(ending_city)
	room.hide()
	prison.show()
	_shot(prison.position + Vector3(5, 3, 6), prison.position + Vector3(0, 1.2, -1))

func _build_choice() -> void:
	captive_body = preload("res://runner/runner.tscn").instantiate()
	prison.add_child(captive_body)
	preload("res://scripts/bedroom_outfit.gd").apply(captive_body)
	captive_body.position = Vector3(1.7, 0.05, 0)
	captive_body.call("play_animation", &"Idle", 0.0)
	choice_panel = VBoxContainer.new()
	title.get_parent().add_child(choice_panel)
	choice_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	choice_panel.offset_left = -340
	choice_panel.offset_right = 340
	choice_panel.offset_top = -230
	choice_panel.offset_bottom = -40
	var prompt := Label.new()
	prompt.text = "Only one can return. Who goes through?"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 28)
	choice_panel.add_child(prompt)
	for option in [false, true]:
		var button := Button.new()
		button.text = "Let the shadow go" if option else "Go through yourself"
		button.custom_minimum_size = Vector2(680, 60)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(_choose_ending.bind(option))
		choice_panel.add_child(button)
	ending_card = Label.new()
	title.get_parent().add_child(ending_card)
	ending_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_card.add_theme_font_size_override("font_size", 64)
	ending_card.add_theme_color_override("font_outline_color", Color("050a1a"))
	ending_card.add_theme_constant_override("outline_size", 12)
	ending_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_card.hide()

func _choose_ending(let_boy_go: bool) -> void:
	if phase != "choice": return
	release_boy = let_boy_go
	phase = "finale"
	phase_time = 0.0
	choice_panel.hide()
	prison.hide()
	room.show()
	captive_body.position = Vector3(0, 0.05, 0)
	captive_body.visible = release_boy
	neon_shadow.visible = not release_boy

func _input(_event: InputEvent) -> void:
	pass

func _physics_process(_dt: float) -> void:
	pass

func _build_final_props() -> void:
	for i in range(24):
		var shard := Props.box(room, Vector3.ZERO, Vector3(0.12 + (i % 3) * 0.09, 0.12, 0.18), Color("26394d") if i % 3 else Color("79d9d3"))
		shard.hide()
		debris.append(shard)
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; uniform float strength = 0.0; void fragment(){ float n = fract(sin(dot(floor(UV*90.0)+floor(TIME*30.0), vec2(12.9898,78.233)))*43758.5453); vec3 neon = mix(vec3(0.015,0.005,0.04),mix(vec3(0.1,0.95,1.0),vec3(1.0,0.08,0.7),step(0.5,n)),step(0.58,n)); ALBEDO = neon; EMISSION = neon*1.8; ALPHA = strength; }"
	static_material = ShaderMaterial.new()
	static_material.shader = shader
	for mesh in bedroom_model.find_children("*", "MeshInstance3D", true, false):
		if mesh.visible: mesh.material_overlay = static_material
	revealed_body = preload("res://enemy_runner/enemy_runner.tscn").instantiate()
	walker.add_child(revealed_body)
	revealed_body.hide()
	revealed_body.call("play_animation", &"Idle", 0.0)
	revealed_body.animation_player.speed_scale = 0.45
	for mesh in revealed_body.find_children("*", "MeshInstance3D", true, false):
		if mesh.visible: mesh.material_overlay = static_material
	prison = Node3D.new()
	add_child(prison)
	prison.position = Vector3(100, 0, 0)
	Props.box(prison, Vector3(0, -0.15, -10), Vector3(10, 0.3, 55), Color("100b24"))
	for side in [-1, 1]:
		Props.box(prison, Vector3(side * 4, 0.03, -10), Vector3(0.04, 0.05, 55), Color("e230bf"), 2)
		for i in range(14):
			Props.box(prison, Vector3(side * (5 + i % 3), 2, -i * 3), Vector3(1, 4 + i % 4, 1), Color("191133"))
	neon_shadow = preload("res://enemy_runner/enemy_runner.tscn").instantiate()
	prison.add_child(neon_shadow)
	neon_shadow.position = Vector3(0, 0.05, 0)
	neon_shadow.rotation.y = PI
	neon_shadow.call("play_animation", &"Idle", 0.1)
	trapped_player = neon_shadow
	trapped_player.call("play_animation", &"Idle", 0.0)
	trapped_player.call("set_expression", "surprised")
	trapped_player.show()
	prison_portal = portal.duplicate()
	prison.add_child(prison_portal)
	prison_portal.position = Vector3(0, 1.8, -3)
	var light := OmniLight3D.new()
	prison.add_child(light)
	light.position = Vector3(0, 4, 1)
	light.light_color = Color("9066ec")
	light.light_energy = 3
	light.omni_range = 30
	prison.hide()

func _shot(position: Vector3, target: Vector3) -> void:
	camera.global_position = position
	camera.look_at(target)

func _process(dt: float) -> void:
	if phase in ["complete", "choice"]: return
	if phase == "ending_card":
		phase_time += dt
		if phase_time >= 4.0:
			phase = "complete"
			preload("res://scripts/city_progress.gd").reset()
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		return
	phase_time += dt
	var t := phase_time
	if t < 3.2:
		# Grow from the cassette opening and leap onto the bedroom floor.
		var p := smoothstep(0, 2.5, t)
		walker.position = Vector3(1.4, 1.5, -7.0).lerp(Vector3(1.4, 0.05, -4.7), p) + Vector3.UP * sin(p * PI) * 1.3
		bedroom_model.scale = Vector3.ONE * lerpf(0.12, 1, p)
		bedroom_model.rotation.y = 0
		# The doorway stays alive until the boombox is destroyed.
		portal.scale = Vector3.ONE * 0.65
		# This is the same shadow leaving the tape, not an exchange of bodies.
		var exposed := release_boy or (t >= 0.45 and t < 0.75)
		static_material.set_shader_parameter("strength", 0.0)
		bedroom_model.visible = not exposed
		revealed_body.visible = exposed
		revealed_body.scale = bedroom_model.scale
		revealed_body.rotation = bedroom_model.rotation
		_shot(Vector3(5, 2.7, -2.5), walker.position + Vector3.UP)
	elif t < 6:
		portal.show()
		prisoner.visible = not release_boy
		bedroom_model.visible = not release_boy
		revealed_body.visible = release_boy
		revealed_body.scale = Vector3.ONE
		var p := smoothstep(3.2, 4.5, t)
		walker.position = Vector3(1.4, 0.05, -4.7).lerp(Vector3(1.4, 0.05, -6.1), p)
		bedroom_model.rotation.y = PI
		revealed_body.rotation.y = PI
		boombox.position = Vector3(1.4, 1.5, -7.5).lerp(Vector3(1.4, 2.5, -6.5), smoothstep(4.4, 5.5, t))
		_shot(Vector3(4.7, 2.8, -4.1), Vector3(1.4, 1.7, -6.5))
	elif t < 8:
		var p := smoothstep(6, 6.6, t)
		boombox.position = Vector3(1.4, 2.5, -6.5).lerp(Vector3(1.4, 0.15, -5.3), p)
		boombox.rotation.z = p * 2.4
		if t >= 6.6:
			boombox.hide()
			if not impact_played:
				impact_played = true
				_play_effect(false)
			for i in range(debris.size()):
				var shard := debris[i]
				shard.show()
				var age := minf(t - 6.6, 1.3)
				var direction := Vector3(sin(i * 2.4), 0, cos(i * 2.4))
				shard.position = Vector3(1.4, maxf(0.07, 0.2 + age * (1.5 + i % 3) - 4 * age * age), -5.3) + direction * age * (0.5 + i % 4 * 0.3)
				shard.rotation = Vector3(i, age * i, i * 0.7)
		if t >= 6.6:
			# Match cut from the impact to the same doorway collapsing inside.
			room.hide()
			prison.show()
			prison_portal.scale = Vector3.ONE * (1 - smoothstep(6.6, 7.15, t))
			_shot(prison.position + Vector3(3.3, 2.6, 4.5), prison.position + Vector3(0, 1.3, -1.7))
			camera.position += Vector3(sin(t * 97), cos(t * 83), 0) * 0.12 * (1 - smoothstep(6.6, 7.3, t))
	elif t < 10.5:
		prison.hide()
		room.show()
		portal.hide()
		if release_boy:
			bedroom_model.show()
			revealed_body.hide()
			static_material.set_shader_parameter("strength", sin(smoothstep(8, 9, t) * PI))
		if not sigh_played:
			sigh_played = true
			_play_effect(true)
		# A long exhale: shoulders and head settle before returning to bed.
		bedroom_model.rotation.x = sin(smoothstep(8, 10.5, t) * PI) * 0.09
		_shot(Vector3(3.4, 2.2, -3.5), walker.position + Vector3(0, 1.3, 0))
	elif t < 16:
		var p := smoothstep(10.5, 15, t)
		walker.position = Vector3(1.4, 0.05, -6.1).lerp(Vector3(-3.3, 0.05, -1), p)
		bedroom_model.rotation = Vector3(0, -0.74, 0)
		bedroom_model.call("play_animation", &"Run" if t < 15 else &"Idle", 0.2)
		bedroom_model.animation_player.speed_scale = 0.45
		_shot(Vector3(0, 3.8, 3), walker.position + Vector3.UP)
	elif t < 23:
		# The same rig climbs onto the mattress and lies down in a third-person shot.
		var settle := smoothstep(16, 18, t)
		bedroom_model.show()
		bedroom_model.call("play_animation", &"Idle", 0.2)
		walker.position = Vector3(-3.3, 0.05, -1).lerp(Vector3(-5, 1.23, -0.7), settle)
		bedroom_model.rotation = Vector3(-PI / 2 * settle, 0, 0)
		_shot(Vector3(-1.4, 4.8, 2.2), Vector3(-5, 1.4, -1.2))
		# One short static transition replaces the sleeper with the actual neon rig.
		var revealing := not release_boy and t >= 18.3 and t < 18.7
		static_material.set_shader_parameter("strength", sin(clampf((t - 18.3) / 0.4, 0, 1) * PI) if revealing else 0.0)
		var transformed := not release_boy and t >= 18.5 and t < 20.5
		bedroom_model.visible = not transformed
		revealed_body.visible = transformed
		revealed_body.rotation = bedroom_model.rotation
		if not release_boy and t >= 20.5 and not laugh_played:
			laugh_played = true
			bedroom_model.call("set_expression", "smile")
			_play_laugh()
		if not release_boy and t >= 20.5 and t < 22.0:
			bedroom_model.rotation.x += sin((t - 20.5) * 23) * 0.018 * (1 - (t - 20.5) / 1.8)
		fade.color.a = smoothstep(22, 23, t)
	elif t < 42:
		room.hide()
		prison.show()
		fade.color.a = 1 - smoothstep(23, 24, t)
		prison_portal.scale = Vector3.ZERO
		if release_boy:
			var morph := smoothstep(24.5, 28.5, t)
			captive_body.visible = morph < 1.0
			neon_shadow.visible = morph > 0.0
			City.body_opacity(captive_body, 1.0 - morph)
			City.body_opacity(neon_shadow, morph)
			captive_body.position = Vector3(0, 0.05, -1.7)
			captive_body.rotation.y = PI
			neon_shadow.position = captive_body.position
			ending_city.phase_effect(morph, captive_body.position)
			if t < 29:
				var orbit := smoothstep(23, 29, t)
				_shot(prison.position + Vector3(3.5 - orbit * 5, 2.2, 2.0), prison.position + Vector3(0, 1.2, -1.7))
		else:
			neon_shadow.position = Vector3(0, 0.05, -1.7)
			captive_body.position = neon_shadow.position
			captive_body.rotation = neon_shadow.rotation
			var morph := smoothstep(24.5, 28.5, t)
			neon_shadow.visible = morph < 1.0
			captive_body.visible = morph > 0.0
			City.body_opacity(neon_shadow, 1.0 - morph)
			City.body_opacity(captive_body, morph)
			ending_city.phase_effect(morph, captive_body.position)
			trapped_player = captive_body
			if t < 29:
				if not anger_started:
					anger_started = true
					neon_shadow.call("play_animation", &"hurt", 0.25)
					captive_body.call("play_animation", &"hurt", 0.25)
				neon_shadow.call("set_expression", "frown")
				captive_body.call("set_expression", "frown")
				neon_shadow.rotation.x = sin(smoothstep(24, 27, t) * PI) * 0.22
				captive_body.rotation = neon_shadow.rotation
				if t > 26:
					_reach_for_exit(neon_shadow)
					_reach_for_exit(captive_body)
				_shot(prison.position + Vector3(1.8, 1.8, -4.7), prison.position + Vector3(0, 1.35, -1.7))
		if t >= 29:
			var walking_body := neon_shadow if release_boy else captive_body
			walking_body.skeleton.clear_bones_global_pose_override()
			walking_body.rotation.y = lerp_angle(PI, 0, smoothstep(29, 31, t))
			walking_body.rotation.x = 0.0 if release_boy else 0.1
			walking_body.position.z = -1.7 + maxf(0, t - 31) * 1.3
			if not walk_started:
				walk_started = true
				walking_body.call("play_animation", &"Run", 0.5)
				walking_body.animation_player.speed_scale = 0.32
				walking_body.call("set_expression", "neutral" if release_boy else "frown")
			var rise := smoothstep(32, 42, t)
			var follow: float = walking_body.position.z
			ending_city.phase_light.position = walking_body.position + Vector3(1, 3, 2)
			ending_city.phase_light.light_energy = 3.0
			_shot(prison.position + Vector3(2.8 - rise * 2, 2.8 + rise * 19, follow - 7 - rise * 8), prison.position + Vector3(0, 1.2 + rise * 3, follow + rise * 17))
			if t >= 37:
				ending_card.text = "Good Ending" if release_boy else "Bad Ending"
				ending_card.modulate.a = smoothstep(37, 39, t)
				ending_card.show()
	else:
		phase = "ending_card"
		phase_time = 0.0
		fade.color.a = 0.0
		ending_card.text = "Good Ending" if release_boy else "Bad Ending"
		ending_card.show()
	if t >= 4.4 and t < 6.6:
		_pose_pickup()
	else:
		bedroom_model.skeleton.clear_bones_global_pose_override()
		revealed_body.skeleton.clear_bones_global_pose_override()

# Pose the existing skinned arms toward the boombox grip.
func _reach_for_exit(body: Node3D) -> void:
	var rig: Skeleton3D = body.skeleton
	var upper := rig.find_bone("UpperArm.R")
	var forearm := rig.find_bone("Forearm.R")
	var pose := rig.get_bone_global_pose(upper)
	var current := (rig.get_bone_global_pose(forearm).origin - pose.origin).normalized()
	var target := rig.to_local(prison.global_position + Vector3(0.3, 1.4, -3))
	pose.basis = Basis(Quaternion(current, (target - pose.origin).normalized())) * pose.basis
	rig.set_bone_global_pose_override(upper, pose, 1.0, true)

func _pose_pickup() -> void:
	var body := revealed_body if release_boy else bedroom_model
	var rig: Skeleton3D = body.skeleton
	body.animation_player.advance(0)
	for side in ["L", "R"]:
		var upper := rig.find_bone("UpperArm." + side)
		var forearm := rig.find_bone("Forearm." + side)
		var hand := rig.find_bone("Hand." + side)
		var grip := boombox.global_position + Vector3(-0.48 if side == "L" else 0.48, 0.15, 0)
		for pair in [[upper, forearm], [forearm, hand]]:
			var bone: int = pair[0]
			var pose := rig.get_bone_global_pose(bone)
			var child := rig.get_bone_global_pose(pair[1])
			var current := (child.origin - pose.origin).normalized()
			var desired := (rig.to_local(grip) - pose.origin).normalized()
			pose.basis = Basis(Quaternion(current, desired)) * pose.basis
			rig.set_bone_global_pose_override(bone, pose, 1.0, true)

func _play_effect(sigh: bool) -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var duration := 2.0 if sigh else 0.7
	var bytes := PackedByteArray()
	bytes.resize(int(duration * 22050) * 2)
	var filtered := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in range(bytes.size() / 2):
		var time := float(i) / 22050
		filtered = lerpf(filtered, rng.randf_range(-1, 1), 0.12 if sigh else 0.8)
		var envelope := sin(time / duration * PI) * 0.35 if sigh else exp(-time * 9) * 0.85
		var sample := filtered * envelope
		bytes.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	wav.data = bytes
	effects.stream = wav
	effects.play()





# A low, voiced three-beat laugh with a fading breath and a short room echo.
func _play_laugh() -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(22050 * 2 * 2)
	var samples := PackedFloat32Array()
	samples.resize(22050 * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 83
	for i in range(samples.size()):
		var time := float(i) / 22050.0
		var sample := 0.0
		for beat in range(3):
			var age := time - float(beat) * 0.36
			if age >= 0 and age < 0.34:
				var envelope := smoothstep(0, 0.025, age) * exp(-age * 10) * (1 - smoothstep(0.23, 0.34, age))
				var pitch := 112.0 - beat * 9.0
				var voiced := sin(TAU * pitch * age) * 0.45 + sin(TAU * pitch * 2 * age) * 0.25 + sin(TAU * pitch * 6 * age) * 0.13 + sin(TAU * pitch * 10 * age) * 0.08
				sample += (voiced + rng.randf_range(-0.12, 0.12)) * envelope * 0.65
		samples[i] = sample
		if i >= 3969: sample += samples[i - 3969] * 0.25
		bytes.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	wav.data = bytes
	effects.stream = wav
	effects.play()
