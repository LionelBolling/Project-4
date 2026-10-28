extends CharacterBody3D
class_name MonsterQteTarget

@export_enum("Q", "E", "R") var required_key := "Q"
@export_range(0.0, 6.0, 0.1) var hover_height := 0.0
@export_range(0.1, 6.0, 0.1) var hover_speed := 1.8
@export var title := "MONSTER"

@onready var visual: Node3D = $Visual

var defeated := false
var launched := false
var _home_y := 0.0
var _hover_phase := 0.0
var _bounce_count := 0
var _failure_flinch := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.25
	_home_y = global_position.y
	_hover_phase = randf_range(0.0, TAU)

func _physics_process(delta: float) -> void:
	if not launched:
		if not defeated and hover_height > 0.0:
			global_position.y = _home_y + sin(Time.get_ticks_msec() * 0.001 * hover_speed + _hover_phase) * hover_height
		return
	velocity.y -= 24.0 * delta
	move_and_slide()
	visual.rotation.x += delta * 6.5
	visual.rotation.z += delta * 8.0
	if is_on_floor() and velocity.y <= 0.0:
		_bounce_count += 1
		if _bounce_count == 1:
			var bounce_strength := 4.2 if _failure_flinch else 7.5
			var momentum_keep := 0.42 if _failure_flinch else 0.68
			velocity = Vector3(velocity.x * momentum_keep, bounce_strength, velocity.z * momentum_keep)
		else:
			launched = false
			velocity = Vector3.ZERO
			visual.rotation = Vector3.ZERO
			if _failure_flinch:
				_failure_flinch = false
				if visual.has_method("play_idle"):
					visual.call("play_idle", 0.1)

func launch_from_hit(backward_direction: Vector3) -> void:
	if defeated:
		return
	defeated = true
	launched = true
	_bounce_count = 0
	var horizontal := Vector3(backward_direction.x, 0.0, backward_direction.z).normalized()
	velocity = horizontal * 25.0 + Vector3.UP * 15.0
	if visual.has_method("play_hurt"):
		visual.call("play_hurt", 0.06)

func flinch_from_failed_qte(backward_direction: Vector3) -> void:
	if defeated or launched:
		return
	launched = true
	_failure_flinch = true
	_bounce_count = 0
	var horizontal := Vector3(backward_direction.x, 0.0, backward_direction.z).normalized()
	velocity = horizontal * 8.0 + Vector3.UP * 5.0
	if visual.has_method("play_hurt"):
		visual.call("play_hurt", 0.06)
