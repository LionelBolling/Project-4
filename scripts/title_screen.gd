extends Node3D

const GAME_SCENE := "res://scenes/bedroom_intro.tscn"

const GLITCH_INTERVAL := 2.5
const GLITCH_DURATION := 1.0
var _elapsed := 0.0
var _background_material: ShaderMaterial

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_background()
	_build_title_ui()

func _make_viewport(label_text: String) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = label_text
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	return viewport

func _build_background() -> void:
	var bedroom_view := _make_viewport("BedroomView")
	var bedroom := preload("res://scripts/title_bedroom.gd").new()
	bedroom_view.add_child(bedroom)
	var neon_view := _make_viewport("NeonView")
	var neon_root := Node3D.new()
	neon_view.add_child(neon_root)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	neon_root.add_child(world)
	var camera := Camera3D.new()
	neon_root.add_child(camera)
	camera.position = Vector3(0, -30, 42)
	camera.look_at(Vector3(0, -18, -90))
	camera.current = true
	camera.fov = 75.0
	var city := preload("res://scripts/neon_world.gd").new()
	city.district_length = 180.0
	neon_root.add_child(city)
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture = bedroom_view.get_texture()
	_background_material = ShaderMaterial.new()
	_background_material.shader = preload("res://scripts/title_glitch.gdshader")
	_background_material.set_shader_parameter("neon_texture", neon_view.get_texture())
	background.material = _background_material
	layer.add_child(background)

func _process(delta: float) -> void:
	_elapsed += delta
	# First intrusion at 2.5 seconds; subsequent intrusions start every 2.5 seconds.
	var phase := fposmod(_elapsed, GLITCH_INTERVAL)
	var active := _elapsed >= GLITCH_INTERVAL and phase < GLITCH_DURATION
	var strength := 0.0
	if active:
		strength = 0.35 + 0.65 * maxf(1.0 - phase / 0.16, smoothstep(0.8, 1.0, phase))
	_background_material.set_shader_parameter("elapsed", _elapsed)
	_background_material.set_shader_parameter("neon_amount", 1.0 if active else 0.0)
	_background_material.set_shader_parameter("glitch", strength)

func _build_title_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var title := Label.new()
	title.text = "NEON FEVER"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-500.0, 38.0)
	title.size = Vector2(1000.0, 130.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 88)
	title.add_theme_color_override("font_color", Color("fff2a6"))
	title.add_theme_color_override("font_outline_color", Color("ff3ba9"))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_shadow_color", Color(0.04, 0.72, 1.0, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 8)
	root.add_child(title)

	var buttons := VBoxContainer.new()
	buttons.set_anchors_preset(Control.PRESET_CENTER)
	buttons.position = Vector2(-155.0, 115.0)
	buttons.size = Vector2(310.0, 160.0)
	buttons.add_theme_constant_override("separation", 18)
	root.add_child(buttons)

	var start_button := _make_button("START", Color("ff42b8"), Color("ff94dd"))
	start_button.pressed.connect(_start_game)
	buttons.add_child(start_button)
	var close_button := _make_button("CLOSE", Color("128fd1"), Color("54ddff"))
	close_button.pressed.connect(_close_game)
	buttons.add_child(close_button)

func _make_button(label_text: String, base: Color, hover: Color) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(310.0, 66.0)
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(base, Color(0.9, 0.84, 1.0, 0.9)))
	button.add_theme_stylebox_override("hover", _button_style(hover, Color.WHITE))
	button.add_theme_stylebox_override("pressed", _button_style(base.darkened(0.22), Color.WHITE))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(3)
	style.border_color = border
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.1, 0.0, 0.16, 0.48)
	style.shadow_size = 12
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _start_game() -> void:
	preload("res://scripts/city_progress.gd").reset()
	get_tree().change_scene_to_file(GAME_SCENE)

func _close_game() -> void:
	get_tree().quit()
