extends Node3D

const QTE_SECONDS := 2.0
const APPROACH_DISTANCE := 8.5

@onready var player: MovementTestPlayer = $Player
@onready var monsters: Array[MonsterQteTarget] = [
	$DiscoBall,
	$Speaker,
	$Microphone
]

var phase := "APPROACH"
var current_target: MonsterQteTarget
var _retry_target: MonsterQteTarget
var qte_timer := 0.0
var rush_timer := 0.0
var post_hit_timer := 0.0
var _rush_direction := Vector3.FORWARD
var _rush_target_position := Vector3.ZERO
var _qte_entry_momentum := Vector3.ZERO
var _safe_spawn := Vector3.ZERO
var _hud_status: Label
var _hud_prompt: Label

func _ready() -> void:
	_safe_spawn = player.global_position
	_build_environment()
	_build_hud()
	player.status_label = _hud_status
	_update_hud()

func _process(delta: float) -> void:
	if player.is_on_floor() and absf(player.global_position.x) < 6.5:
		_safe_spawn = player.global_position
		_safe_spawn.y = 0.05
	if player.global_position.y < -12.0:
		_respawn_player()
		return
	match phase:
		"APPROACH":
			current_target = _next_target()
			if current_target == null:
				phase = "CLEAR"
			else:
				_check_approach()
		"QTE":
			qte_timer -= delta
			if qte_timer <= 0.0:
				_fail_qte("TOO SLOW — BACK OFF TO RETRY")
		"POST_HIT":
			post_hit_timer -= delta
			if post_hit_timer <= 0.0:
				phase = "APPROACH"
		"RETRY_GAP":
			if not is_instance_valid(_retry_target):
				phase = "APPROACH"
			else:
				var gap := _retry_target.global_position - player.global_position
				gap.y = 0.0
				if gap.length() > APPROACH_DISTANCE + 4.0:
					_retry_target = null
					phase = "APPROACH"
	_update_hud()

func _physics_process(delta: float) -> void:
	if phase != "RUSH":
		return
	player.global_position = player.global_position.move_toward(_rush_target_position, 28.0 * delta)
	rush_timer -= delta
	if player.global_position.distance_to(_rush_target_position) <= 0.08 or rush_timer <= 0.0:
		player.global_position = _rush_target_position
		_finish_rush()

func _input(event: InputEvent) -> void:
	if phase != "QTE" or not event is InputEventKey or not event.pressed or event.echo:
		return
	var pressed := ""
	match event.keycode:
		KEY_Q: pressed = "Q"
		KEY_E: pressed = "E"
		KEY_R: pressed = "R"
		_: return
	get_viewport().set_input_as_handled()
	if pressed == current_target.required_key:
		_begin_rush()
	else:
		_fail_qte("WRONG KEY — BACK OFF TO RETRY")

func _check_approach() -> void:
	var horizontal_gap := current_target.global_position - player.global_position
	horizontal_gap.y = 0.0
	var horizontal_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal_gap.length() > APPROACH_DISTANCE or horizontal_velocity.length() < 2.0:
		return
	var toward := horizontal_gap.normalized()
	if horizontal_velocity.normalized().dot(toward) < 0.25:
		return
	phase = "QTE"
	qte_timer = QTE_SECONDS
	_qte_entry_momentum = Vector3(player.velocity.x, 0.0, player.velocity.z)
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.set_physics_process(false)
	_hud_prompt.text = "PRESS  %s" % current_target.required_key

func _begin_rush() -> void:
	phase = "RUSH"
	rush_timer = 0.55
	var toward := current_target.global_position - player.global_position
	toward.y = 0.0
	_rush_direction = toward.normalized() if toward.length_squared() > 0.001 else Vector3.FORWARD
	_rush_target_position = current_target.global_position - _rush_direction * 1.0
	_rush_target_position.y = player.global_position.y
	player.visual.rotation.y = atan2(_rush_direction.x, _rush_direction.z)
	player.call("_set_animation", "dive")
	_hud_prompt.text = "GO!"

func _finish_rush() -> void:
	current_target.launch_from_hit(-_rush_direction)
	var carried_momentum := Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.3
	var boost := (_rush_direction * 16.5 + carried_momentum).limit_length(20.0)
	player.velocity = Vector3(boost.x, 9.5, boost.z)
	player.state = "JUMPING"
	player.jump_pending = false
	player.jump_buffer = 0.0
	player.jump_start_timer = 0.0
	player.coyote_timer = 0.0
	player.air_time = 0.0
	player.was_airborne = true
	player.visual.rotation.x = 0.0
	player.call("_set_animation", "jumpRise")
	player.set_physics_process(true)
	phase = "POST_HIT"
	post_hit_timer = 0.45
	current_target = null
	_hud_prompt.text = "MONSTER LAUNCHED — SPEED BOOST!"

func _fail_qte(message: String) -> void:
	if current_target == null:
		return
	phase = "RETRY_GAP"
	_retry_target = current_target
	var knockback_direction := current_target.global_position - player.global_position
	knockback_direction.y = 0.0
	if knockback_direction.length_squared() > 0.001:
		current_target.flinch_from_failed_qte(knockback_direction.normalized())
	player.velocity.x = _qte_entry_momentum.x * 0.28
	player.velocity.z = _qte_entry_momentum.z * 0.28
	player.call("play_hurt_animation")
	player.set_physics_process(true)
	current_target = null
	_hud_prompt.text = message
	# Require the player to leave the encounter radius before it can trigger again.

func _next_target() -> MonsterQteTarget:
	for monster in monsters:
		if not monster.defeated:
			return monster
	return null

func _respawn_player() -> void:
	player.spawn_position = _safe_spawn
	player.global_position = _safe_spawn
	player.velocity = Vector3.ZERO
	player.call("_respawn_at_start")
	player.set_physics_process(true)
	current_target = null
	phase = "APPROACH"

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8074b8")
	environment.ambient_light_energy = 0.7
	environment.glow_enabled = true
	environment.glow_intensity = 0.9
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 16.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "MONSTER TEST RUN"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("62f4e1"))
	stack.add_child(title)
	_hud_status = Label.new()
	_hud_status.add_theme_color_override("font_color", Color("ffe385"))
	stack.add_child(_hud_status)
	var controls := Label.new()
	controls.text = "WASD run   Mouse camera   Space jump   Shift glide   Ctrl dive"
	controls.add_theme_font_size_override("font_size", 14)
	stack.add_child(controls)
	_hud_prompt = Label.new()
	_hud_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_hud_prompt.position = Vector2(-330.0, -75.0)
	_hud_prompt.size = Vector2(660.0, 110.0)
	_hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_prompt.add_theme_font_size_override("font_size", 46)
	_hud_prompt.add_theme_color_override("font_color", Color("ffe385"))
	layer.add_child(_hud_prompt)

func _update_hud() -> void:
	if _hud_status == null:
		return
	var defeated_count := 0
	for monster in monsters:
		if monster.defeated:
			defeated_count += 1
	if phase == "QTE":
		_hud_status.text = "%s   QTE  %.1f s" % [current_target.title, maxf(qte_timer, 0.0)]
	elif phase == "CLEAR":
		_hud_status.text = "ALL MONSTERS DEFEATED"
	else:
		var target := _next_target()
		_hud_status.text = "%d / 3 DEFEATED   %s" % [defeated_count, target.title if target != null else "CLEAR"]
	if phase == "APPROACH":
		_hud_prompt.text = "RUN NEAR THE NEXT MONSTER"

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.12, 0.9)
	style.border_color = Color("46e8df")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style
