extends Node3D
class_name RivalBlackProjectile

signal surface_impact(hit_position: Vector3, surface_normal: Vector3, surface: Object, projectile_radius: float)

@export var projectile_radius := 0.82
@export var projectile_speed := 12.0
@export var magnetic_acceleration := 27.0
@export var lifetime_seconds := 8.0
@export var player_touch_radius := 0.95

var player_target: MovementTestPlayer
var velocity := Vector3.ZERO
var target_position := Vector3.ZERO
var target_normal := Vector3.UP
var target_surface: Object
var _lifetime := 0.0
var _mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("rival_black_projectiles")
	_mesh = MeshInstance3D.new()
	_mesh.name = "BlackSphere"
	var sphere := SphereMesh.new()
	sphere.radius = projectile_radius
	sphere.height = projectile_radius * 2.0
	_mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.004, 0.002, 0.008, 1.0)
	material.metallic = 0.18
	material.roughness = 0.22
	material.emission_enabled = true
	material.emission = Color(0.035, 0.003, 0.07)
	material.emission_energy_multiplier = 0.65
	_mesh.material_override = material
	add_child(_mesh)

func launch(player: MovementTestPlayer, initial_direction: Vector3, surface_hint: Vector3) -> void:
	player_target = player
	var direction := initial_direction.normalized()
	if direction.length_squared() < 0.01:
		direction = Vector3.FORWARD
	velocity = direction * projectile_speed
	_acquire_surface_target(surface_hint)

func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= lifetime_seconds:
		queue_free()
		return
	_mesh.rotate_y(delta * 2.5)
	if is_instance_valid(player_target):
		var player_center := player_target.global_position + Vector3.UP * 0.9
		if global_position.distance_to(player_center) <= player_touch_radius + projectile_radius * 0.35:
			player_target.play_hurt_animation()
			queue_free()
			return

	if is_instance_valid(target_surface):
		var to_target := target_position - global_position
		if to_target.length() <= projectile_radius * 0.3:
			_impact(target_position, target_normal, target_surface)
			return
		var desired_velocity := to_target.normalized() * projectile_speed
		velocity = velocity.move_toward(desired_velocity, magnetic_acceleration * delta)

	var next_position := global_position + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position)
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		var normal: Vector3 = hit.get("normal", Vector3.UP)
		var point: Vector3 = hit.get("position", next_position)
		_impact(point, normal, collider)
		return
	global_position = next_position

func _acquire_surface_target(surface_hint: Vector3) -> void:
	var hint := surface_hint.normalized()
	if hint.length_squared() < 0.01:
		hint = Vector3.DOWN
	var hit := _ray_for_surface(hint, 22.0)
	if hit.is_empty():
		hit = _ray_for_surface(Vector3.DOWN, 24.0)
	if hit.is_empty():
		target_position = global_position + Vector3.DOWN * 4.0
		target_normal = Vector3.UP
		target_surface = null
		return
	target_normal = hit.get("normal", Vector3.UP)
	target_position = hit.get("position", global_position) + target_normal * projectile_radius * 0.20
	target_surface = hit.get("collider")

func _ray_for_surface(direction: Vector3, distance: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + direction.normalized() * distance)
	query.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_ray(query)

func _impact(point: Vector3, normal: Vector3, surface: Object) -> void:
	if surface != null:
		surface_impact.emit(point, normal.normalized(), surface, projectile_radius)
	queue_free()
