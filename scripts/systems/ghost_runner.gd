extends RefCounted
## Lionel / ghost runner implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

func update_ghost(dt: float) -> void:
	# A competitive rival with a faster pace and occasional surges.
	var surge = 2.2 if fmod(game.elapsed, 12) > 9 else 0.0
	game.ghost_distance += (14.0 + minf(game.elapsed * 0.018, 1.8) + surge) * dt
	var gi = game.tile_at(game.ghost_distance)
	var gy = 0.0
	if gi >= 0:
		var p = game.platforms[gi]
		gy = p.y + sin(p.slope) * (game.ghost_distance - (p.start + p.end) / 2)
		if game.ghost_distance > p.start + 4 and not p.corrupt:
			p.corrupt = true
			p.mesh.material_override = game.material(Color("42295f"), 0.25)
	else: gy = 1.2
	game.shadow.position = Vector3(1.7 * sin(game.ghost_distance * 0.035), gy + 0.04, -game.ghost_distance)
	game.shadow.rotation.y = 0
	game.shadow_visual.get_node("LegL").rotation.x = sin(game.clock * 16) * 0.65
	game.shadow_visual.get_node("LegR").rotation.x = -sin(game.clock * 16) * 0.65
	game.shadow_visual.get_node("ArmL").rotation.x = -sin(game.clock * 16) * 0.6
	game.shadow_visual.get_node("ArmR").rotation.x = sin(game.clock * 16) * 0.6


func create_shadow() -> void:
	game.shadow = Node3D.new()
	game.add_child(game.shadow)
	game.shadow_visual = game.make_runner(game.shadow, game.VIOLET)
	game.caption(game.shadow, "YOUR SHADOW", Vector3(0, 2.8, 0), game.VIOLET, 26)
