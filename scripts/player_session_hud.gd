extends CanvasLayer
const Progress = preload("res://scripts/city_progress.gd")
var player
var health_root: Control
var health_fill: ProgressBar
var health_text: Label
var glide_root: Control
var glide_fill: ProgressBar
var glide_text: Label

func _ready() -> void:
	name = "SessionHUD"
	layer = 30
	player = get_parent()
	_build_health()
	_build_glide()
	# Move existing race progress below health, keeping both readable.
	if Progress.active:
		for canvas in player.get_parent().find_children("*", "CanvasLayer", true, false):
			if canvas.name in ["RaceHUD", "EnemyQTEHUD", "Level3HUD", "BossHUD"]:
				for panel in canvas.get_children():
					if panel is PanelContainer and panel.position.y < 110:
						panel.position.y = 116
	_update()

func _style(color: Color, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

func _bar(parent: Control, pos: Vector2, dimensions: Vector2, tint: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = dimensions
	bar.show_percentage = false
	bar.max_value = 100
	bar.add_theme_stylebox_override("background", _style(Color("10172e")))
	bar.add_theme_stylebox_override("fill", _style(tint))
	parent.add_child(bar)
	return bar

func _label(parent: Control, pos: Vector2, dimensions: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = dimensions
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label

func _build_health() -> void:
	health_root = Control.new()
	health_root.position = Vector2(22, 20)
	health_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_root)
	health_fill = _bar(health_root, Vector2(58, 24), Vector2(240, 24), Color("4de7c0"))
	health_text = _label(health_root, Vector2(80, 0), Vector2(210, 24))
	var frame := Panel.new()
	frame.size = Vector2(78, 78)
	var style := _style(Color("11223d"), 40)
	style.border_color = Color("65f3ec")
	style.set_border_width_all(3)
	frame.add_theme_stylebox_override("panel", style)
	health_root.add_child(frame)
	if not Progress.active: return
	var portrait_view := SubViewport.new()
	portrait_view.size = Vector2i(192, 192)
	portrait_view.own_world_3d = true
	portrait_view.transparent_bg = true
	portrait_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	frame.add_child(portrait_view)
	var model := preload("res://runner/runner.tscn").instantiate()
	portrait_view.add_child(model)
	model.call("play_animation", &"Idle")
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("15203d")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("bdd7ff")
	env.environment.ambient_light_energy = 0.9
	portrait_view.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -20, 0)
	portrait_view.add_child(light)
	var camera := Camera3D.new()
	portrait_view.add_child(camera)
	camera.position = Vector3(0, 1.52, 1.65)
	camera.fov = 34
	camera.current = true
	var texture := TextureRect.new()
	texture.position = Vector2(4, 4)
	texture.size = Vector2(70, 70)
	texture.texture = portrait_view.get_texture()
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); float mask=1.0-smoothstep(0.48,0.50,length(UV-vec2(0.5))); COLOR=vec4(c.rgb,c.a*mask);}"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	texture.material = mat
	frame.add_child(texture)

func _build_glide() -> void:
	glide_root = Control.new()
	add_child(glide_root)
	glide_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	glide_root.offset_left = -170
	glide_root.offset_right = 170
	glide_root.offset_top = -94
	glide_root.offset_bottom = -32
	glide_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glide_fill = _bar(glide_root, Vector2(0, 31), Vector2(340, 15), Color("4ddcea"))
	glide_text = _label(glide_root, Vector2(0, 0), Vector2(340, 26))
	glide_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _update() -> void:
	health_root.visible = Progress.active
	health_fill.value = Progress.health
	health_text.text = "%d / %d" % [Progress.health, Progress.MAX_HEALTH]
	glide_root.visible = player.state == "GLIDING" and not player.is_on_floor() and player.is_physics_processing()
	glide_fill.value = 100 * (1 - clampf(player.glide_timer / player.glide_max_duration, 0, 1))
	var background := glide_fill.get_theme_stylebox("background") as StyleBoxFlat
	background.set_border_width_all(2)
	background.border_color = Color("ff4e79") if player.glide_exhausted else Color("3b7891")
	glide_fill.modulate = Color("ff4e79") if player.glide_exhausted else Color.WHITE
	glide_text.text = ("EMPTY - STUN ON LANDING" if player.glide_timer >= player.glide_max_duration else "GLIDE - STUN ON LANDING") if player.glide_exhausted else "GLIDE"

func _process(_dt: float) -> void:
	_update()
