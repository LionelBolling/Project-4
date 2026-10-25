extends RefCounted
## game ui implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("09152bee")
	style.border_color = Color("30568c")
	style.set_border_width_all(1)
	style.border_width_top = 3
	style.set_corner_radius_all(6)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func top_center(control: Control, top: float, bottom: float) -> void:
	control.anchor_left = 0.12
	control.anchor_right = 0.88
	control.anchor_top = 0
	control.anchor_bottom = 0
	control.offset_left = 0
	control.offset_right = 0
	control.offset_top = top
	control.offset_bottom = bottom

func center_label(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func setup(context: Node3D) -> void:
	game = context

func build_ui() -> void:
	var layer = CanvasLayer.new()
	game.add_child(layer)
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme = Theme.new()
	theme.default_font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	theme.default_font_size = 22
	theme.set_color("font_color", "Label", Color("dceaff"))
	theme.set_color("font_shadow_color", "Label", Color("020817"))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 2)
	root.theme = theme
	game.hud = Label.new()
	root.add_child(game.hud)
	top_center(game.hud, 18, 90)
	center_label(game.hud)
	game.hud.add_theme_stylebox_override("normal", panel_style())
	game.hud.add_theme_font_size_override("font_size", 22)
	game.banner = Label.new()
	root.add_child(game.banner)
	top_center(game.banner, 102, 164)
	center_label(game.banner)
	game.banner.add_theme_stylebox_override("normal", panel_style())
	game.banner.add_theme_font_size_override("font_size", 24)
	game.prompt = Label.new()
	root.add_child(game.prompt)
	game.prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	game.prompt.offset_left = -250
	game.prompt.offset_right = 250
	game.prompt.offset_top = 246
	game.prompt.offset_bottom = 346
	game.prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.prompt.add_theme_font_size_override("font_size", 32)
	game.prompt.add_theme_color_override("font_color", Color("92beff"))
	game.prompt.add_theme_stylebox_override("normal", panel_style())
	var help = Label.new()
	root.add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	help.offset_left = 24
	help.offset_top = -47
	help.offset_right = -24
	help.offset_bottom = -20
	help.text = "WASD / ARROWS  MOVE     SPACE  JUMP + GLIDE     SHIFT / DOWN  DIVE     ESC  PAUSE     M  SOUND"
	center_label(help)
	help.add_theme_font_size_override("font_size", 17)
	help.add_theme_color_override("font_color", Color("8ca9d2"))
	game.overlay = PanelContainer.new()
	root.add_child(game.overlay)
	top_center(game.overlay, 100, 390)
	var style = panel_style()
	game.overlay.add_theme_stylebox_override("panel", style)
	game.overlay_text = Label.new()
	game.overlay.add_child(game.overlay_text)
	game.overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.overlay_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game.overlay_text.add_theme_font_size_override("font_size", 24)
	game.overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func show_overlay(title: String, text: String) -> void:
	game.overlay.visible = true
	game.overlay_text.text = title + "\n\n" + text

func build_story_ui() -> void:
	var root = game.hud.get_parent()
	game.help_label = root.get_child(3)
	game.help_label.text = "WASD  MOVE   MOUSE  LOOK   E  INTERACT   SPACE  JUMP / GLIDE   SHIFT  DIVE   ESC  PAUSE"
	game.crosshair = Label.new()
	root.add_child(game.crosshair)
	game.crosshair.text = "+"
	game.crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game.crosshair.offset_left = -6
	game.crosshair.offset_top = -12
	game.crosshair.add_theme_color_override("font_color", Color("92beffa6"))
	for i in range(3):
		var rect = ColorRect.new()
		root.add_child(rect)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.color = Color.BLACK
		if i == 0: game.lids_top = rect
		elif i == 1: game.lids_bottom = rect
		else: game.veil = rect
	game.veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.veil.color.a = 0

func update_ui() -> void:
	if not is_instance_valid(game.help_label): return
	game.hud.visible = game.state in ["bedroom", "explore", "race"]
	game.help_label.visible = game.state in ["bedroom", "explore", "race"]
	game.crosshair.visible = game.help_label.visible
	game.banner.visible = game.state != "paused" and game.state != "result" and game.feedback_time > 0
	if game.state in ["bedroom", "explore"]:
		game.hud.text = "OBJECTIVE\n" + game.objective
	if game.state == "race":
		var distance = maxf(0, -game.player.position.z)
		game.hud.text = "THE OTHER SIDE / RACE\n%d m TO EXIT   %.1f s   DOUBLE: %d m %s" % [int(maxf(0, game.FINISH - distance)), game.elapsed, int(absf(game.ghost_distance - distance)), "AHEAD" if game.ghost_distance > distance else "BEHIND"]
	game.prompt.visible = game.qte_time > 0 and game.state == "race"
	game.prompt.text = "FIGHT THE TAKEOVER\n[ %s ]   %.1f" % [OS.get_keycode_string(game.qte_key), game.qte_time]
	if game.state in ["bedroom", "explore"]:
		game.prompt.visible = not game.interaction_text.is_empty()
		game.prompt.text = game.interaction_text

func finish(victory: bool, message: String) -> void:
	game.show_result(victory, message)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.arms.hide()
	game.qte_time = 0

func show_result(victory: bool, message: String) -> void:
	game.won = victory
	game.state = "result"
	game.show_overlay("YOU ARE STILL YOU" if victory else "REPLACED", message + "\n\n%.1f SECONDS\nENTER TO RACE AGAIN" % game.elapsed)
	game.beep(880 if victory else 110)
