extends CharacterBody3D
class_name MonsterQteTarget

signal disappeared(world_position: Vector3)

@export_enum("Q", "E", "R") var required_key := "Q"
@export_range(0.0, 6.0, 0.1) var hover_height := 0.0
@export_range(0.1, 6.0, 0.1) var hover_speed := 1.8
@export var title := "MONSTER"

@onready var visual: Node3D = $Visual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var defeated := false
var skipped := false
var launched := false
var _home_y := 0.0
var _hover_phase := 0.0
var _bounce_count := 0
var _failure_flinch := false
var _disappear_timer := -1.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.25
	_home_y = global_position.y
	_hover_phase = randf_range(0.0, TAU)

func _physics_process(delta: float) -> void:
	if defeated:
		_disappear_timer -= delta
		if _disappear_timer <= 0.0:
			disappeared.emit(global_position)
			visual.visible = false
			collision_shape.set_deferred("disabled", true)
			set_physics_process(false)
			return
	if not launched:
		if not defeated and hover_height > 0.0:
			var bob := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * hover_speed + _hover_phase)
			global_position.y = _home_y + bob * hover_height
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
			# Keep the monster knocked over while the three-second poof timer runs.
			visual.rotation.x = PI * 0.5
			visual.rotation.z = 0.12

func launch_from_hit(launch_direction: Vector3) -> void:
	if defeated:
		return
	defeated = true
	launched = true
	collision_shape.set_deferred("disabled", true)
	_bounce_count = 0
	_disappear_timer = 3.0
	_failure_flinch = false
	var horizontal := Vector3(launch_direction.x, 0.0, launch_direction.z).normalized()
	velocity = horizontal * 25.0 + Vector3.UP * 15.0
	if visual.has_method("play_hurt"):
		visual.call("play_hurt", 0.06)

func launch_from_failed_qte(launch_direction: Vector3) -> void:
	if defeated or launched:
		return
	defeated = true
	launched = true
	collision_shape.set_deferred("disabled", true)
	_failure_flinch = true
	_bounce_count = 0
	_disappear_timer = 3.0
	var horizontal := Vector3(launch_direction.x, 0.0, launch_direction.z).normalized()
	velocity = horizontal * 16.0 + Vector3.UP * 10.0
	if visual.has_method("play_hurt"):
		visual.call("play_hurt", 0.06)
