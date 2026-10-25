extends RefCounted
## Caleb / qte implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

func tick(dt: float) -> void:
	if game.state == "race" and game.elapsed >= game.next_qte and game.qte_time <= 0:
		game.qte_time = 2
		game.qte_key = game.KEYS[randi() % 4]
		game.next_qte = game.elapsed + randf_range(6, 9)
		game.beep(300)
	if game.qte_time > 0:
		game.qte_time -= dt
		if game.qte_time <= 0:
			game.resolve_qte(false)

func resolve_qte(success: bool) -> void:
	game.apply_qte_result(success)

func apply_qte_result(success: bool) -> void:
	game.qte_time = 0
	game.boost = 2.5 if success else 0.0
	game.slow = 0.0 if success else 1.8
	game.banner.text = "CONTROL RECLAIMED / SPEED BOOST" if success else "THE SHADOW STEALS YOUR MOMENTUM"
	game.feedback_time = 2.5
	game.beep(740 if success else 120)
