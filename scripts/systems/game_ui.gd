extends RefCounted
## game ui implementation.
## game is the shared scene context; call other systems through its delegates.
var game

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
	game.hud = Label.new()
	root.add_child(game.hud)
	game.hud.position = Vector2(28, 20)
	game.hud.add_theme_font_size_override("font_size", 20)
	game.hud.add_theme_color_override("font_color", game.MINT)
	game.banner = Label.new()
	root.add_child(game.banner)
	game.banner.position = Vector2(28, 112)
	game.banner.add_theme_font_size_override("font_size", 18)
	game.prompt = Label.new()
	root.add_child(game.prompt)
	game.prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	game.prompt.offset_left = -250
	game.prompt.offset_right = 250
	game.prompt.offset_top = 165
	game.prompt.offset_bottom = 305
	game.prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.prompt.add_theme_font_size_override("font_size", 32)
	game.prompt.add_theme_color_override("font_color", Color("e0baff"))
	var help = Label.new()
	root.add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.offset_left = 28
	help.offset_top = -47
	help.offset_right = 1252
	help.offset_bottom = -20
	help.text = "WASD / ARROWS  MOVE     SPACE  JUMP + GLIDE     SHIFT / DOWN  DIVE     ESC  PAUSE     M  SOUND"
	help.add_theme_font_size_override("font_size", 15)
	game.overlay = PanelContainer.new()
	root.add_child(game.overlay)
	game.overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game.overlay.offset_left = -460
	game.overlay.offset_right = 460
	game.overlay.offset_top = -225
	game.overlay.offset_bottom = 225
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.1, 0.96)
	style.border_color = Color("3b766f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 30
	style.content_margin_right = 30
	game.overlay.add_theme_stylebox_override("panel", style)
	game.overlay_text = Label.new()
	game.overlay.add_child(game.overlay_text)
	game.overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.overlay_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game.overlay_text.add_theme_font_size_override("font_size", 22)
	game.overlay_text.add_theme_color_override("font_color", game.MINT)

func show_overlay(title: String, text: String) -> void:
	game.overlay.visible = true
	game.overlay_text.text = title + "\n\n" + text

func build_story_ui() -> void:
	var root = game.hud.get_parent()
	game.help_label = root.get_child(3)
	game.help_label.text = "WASD  MOVE   MOUSE  LOOK   SPACE  JUMP / GLIDE   SHIFT  DIVE   ESC  PAUSE   M  SOUND"
	game.crosshair = Label.new()
	root.add_child(game.crosshair)
	game.crosshair.text = "+"
	game.crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game.crosshair.offset_left = -6
	game.crosshair.offset_top = -12
	game.crosshair.add_theme_color_override("font_color", Color(0.8, 0.9, 0.85, 0.65))
	game.tutorial_panel = PanelContainer.new()
	root.add_child(game.tutorial_panel)
	game.tutorial_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	game.tutorial_panel.offset_left = -500
	game.tutorial_panel.offset_right = 500
	game.tutorial_panel.offset_top = -195
	game.tutorial_panel.offset_bottom = -65
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.025, 0.045, 0.07, 0.95)
	bg.set_corner_radius_all(10)
	bg.content_margin_left = 24
	bg.content_margin_top = 15
	bg.content_margin_bottom = 15
	game.tutorial_panel.add_theme_stylebox_override("panel", bg)
	game.tutorial_label = Label.new()
	game.tutorial_panel.add_child(game.tutorial_label)
	game.tutorial_label.add_theme_font_size_override("font_size", 19)
	game.tutorial_label.add_theme_color_override("font_color", Color("c6e8df"))
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
	if not is_instance_valid(game.tutorial_panel): return
	game.hud.visible = game.state in ["race", "tutorial", "countdown"]
	game.help_label.visible = game.state not in ["sleep", "wake", "encounter", "forced_turn", "result"]
	game.crosshair.visible = game.state in ["explore", "tutorial", "race"]
	game.banner.visible = game.state in ["sleep", "wake", "explore", "encounter", "forced_turn", "race", "countdown"] and game.feedback_time > 0
	if game.state == "race":
		var distance = maxf(0, -game.player.position.z)
		game.hud.text = "THE OTHER SIDE / RACE\n%d m TO EXIT   %.1f s   DOUBLE: %d m %s" % [int(maxf(0, game.FINISH - distance)), game.elapsed, int(absf(game.ghost_distance - distance)), "AHEAD" if game.ghost_distance > distance else "BEHIND"]
	elif game.state == "tutorial":
		game.hud.text = "LEARNING TO SURVIVE / %d OF 7\nRIVAL AND RACE TIMER PAUSED" % (game.tutorial_step + 1)
		if not game.tutorial_waiting: game.tutorial_label.text = game.LESSONS[game.tutorial_step][0] + "\n" + game.LESSONS[game.tutorial_step][1] + "\nPerform the action successfully to continue."
	if game.state != "countdown":
		game.prompt.visible = game.qte_time > 0 and game.state in ["race", "tutorial"]
		game.prompt.text = "FIGHT THE TAKEOVER\n[ %s ]   %.1f" % [OS.get_keycode_string(game.qte_key), game.qte_time]

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
