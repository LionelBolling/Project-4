extends "res://scripts/level_3_beta.gd"

var _platform_checkpoint := Vector3.ZERO

func _ready() -> void:
	super._ready()
	_platform_checkpoint = player.global_position

func _process(delta: float) -> void:
	# The shared controller assumes a floor at zero; preserve real landing heights.
	_safe_spawn = _platform_checkpoint
	super._process(delta)
	if player.is_on_floor():
		for index in range(player.get_slide_collision_count()):
			var hit := player.get_slide_collision(index)
			var surface := hit.get_collider() as Node
			if hit.get_normal().y > 0.7 and surface != null and surface.get_parent() == $Platforms:
				_platform_checkpoint = player.global_position + Vector3.UP * 0.05
	_safe_spawn = _platform_checkpoint

func _build_speed_markers() -> void:
	# Landing and takeoff edges are marked on the individual platforms.
	pass
