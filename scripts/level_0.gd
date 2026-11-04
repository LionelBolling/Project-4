@tool
extends "res://scripts/runner_race_scene.gd"

const WORLD_REVEAL_SECONDS := 9.0
var reveal_time := 0.0
var reveal_camera: Camera3D
var reveal_overlay: CanvasLayer
var arrival_fade: ColorRect

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint(): return
	if preload("res://scripts/city_progress.gd").active: return
	race_state = "WORLD_REVEAL"
	get_node("RaceHUD").hide()
	player.set_process_unhandled_input(false)
	reveal_camera = Camera3D.new()
	reveal_camera.name = "WorldRevealCamera"
	reveal_camera.far = 600.0
	reveal_camera.fov = 72.0
	add_child(reveal_camera)
	reveal_camera.make_current()
	_build_reveal_overlay()
	_tick_world_reveal(0.0)

func _build_reveal_overlay() -> void:
	reveal_overlay = CanvasLayer.new()
	reveal_overlay.layer = 15
	add_child(reveal_overlay)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reveal_overlay.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = 0.0 if top else -48.0
		bar.offset_bottom = 48.0 if top else 0.0
	arrival_fade = ColorRect.new()
	arrival_fade.color = Color.BLACK
	arrival_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(arrival_fade)
	arrival_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if race_state == "WORLD_REVEAL":
		_tick_world_reveal(delta)
		return
	super._process(delta)

func _tick_world_reveal(delta: float) -> void:
	reveal_time = minf(reveal_time + delta, WORLD_REVEAL_SECONDS)
	arrival_fade.color.a = 1.0 - smoothstep(0.0, 0.8, reveal_time)
	var position_keys := [Vector3(24, 62, 40), Vector3(18, 45, -120), Vector3(0, 9, -30), player.camera.global_position]
	var focus_keys := [Vector3(0, 0, -80), Vector3(0, 1, -155), Vector3(0, 2, 8), player.camera.global_position - player.camera.global_basis.z * 20.0]
	var segment := mini(int(reveal_time / 3.0), 2)
	var blend := smoothstep(0.0, 1.0, (reveal_time - segment * 3.0) / 3.0)
	reveal_camera.global_position = position_keys[segment].lerp(position_keys[segment + 1], blend)
	reveal_camera.look_at(focus_keys[segment].lerp(focus_keys[segment + 1], blend))
	reveal_camera.fov = lerpf(72.0, player.camera.fov, smoothstep(6.0, 9.0, reveal_time))
	if reveal_time >= WORLD_REVEAL_SECONDS:
		MusicDirector.play_track(1)
		player.camera.make_current()
		player.set_process_unhandled_input(true)
		reveal_camera.queue_free()
		reveal_overlay.queue_free()
		get_node("RaceHUD").show()
		race_state = "COUNTDOWN"
		countdown_time = 3.0
