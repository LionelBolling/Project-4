extends CanvasLayer

var _overlay: Control
var _was_mouse_captured := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _overlay.visible:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _build_menu() -> void:
	_overlay = Control.new()
	_overlay.name = "PauseOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.025, 0.01, 0.07, 0.76)
	tint.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(tint)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-220.0, -205.0)
	panel.size = Vector2(440.0, 410.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	_overlay.add_child(panel)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)

	var heading := Label.new()
	heading.text = "PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 48)
	heading.add_theme_color_override("font_color", Color("fff0a8"))
	heading.add_theme_color_override("font_outline_color", Color("ff42cf"))
	heading.add_theme_constant_override("outline_size", 5)
	stack.add_child(heading)

	var continue_button := _make_button("CONTINUE", Color("ff42b8"), Color("ff94dd"))
	continue_button.pressed.connect(_resume_game)
	stack.add_child(continue_button)
	var retry_button := _make_button("RETRY", Color("128fd1"), Color("54ddff"))
	retry_button.pressed.connect(_retry_scene)
	stack.add_child(retry_button)
	continue_button.grab_focus.call_deferred()

func _pause_game() -> void:
	if get_tree().paused:
		return
	_was_mouse_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_overlay.visible = true
	get_tree().paused = true

func _resume_game() -> void:
	get_tree().paused = false
	_overlay.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _was_mouse_captured else Input.MOUSE_MODE_VISIBLE

func _retry_scene() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _make_button(label_text: String, base: Color, hover: Color) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(300.0, 64.0)
	button.add_theme_font_size_override("font_size", 25)
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
	style.shadow_size = 10
	return style

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.035, 0.14, 0.97)
	style.set_border_width_all(3)
	style.border_color = Color("62e8ff")
	style.set_corner_radius_all(18)
	style.shadow_color = Color(1.0, 0.05, 0.48, 0.42)
	style.shadow_size = 18
	style.content_margin_left = 48.0
	style.content_margin_right = 48.0
	style.content_margin_top = 30.0
	style.content_margin_bottom = 30.0
	return style
