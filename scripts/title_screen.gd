extends Node3D

const GAME_SCENE := "res://scenes/level_0.tscn"

func _ready() -> void:
	_build_title_ui()

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
	get_tree().change_scene_to_file(GAME_SCENE)

func _close_game() -> void:
	get_tree().quit()
