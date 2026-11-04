extends "res://scripts/level_3_beta.gd"

# Keep the shared race mechanics while recording raised landing heights.
func _process(delta: float) -> void:
	super._process(delta)
	if player.is_on_floor() and absf(player.global_position.x) < 6.5:
		_safe_spawn = player.global_position + Vector3(0.0, 0.05, 0.0)
