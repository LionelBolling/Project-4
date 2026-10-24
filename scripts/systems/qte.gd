extends RefCounted
## Caleb / qte implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

## Returns true when the tutorial was stopped by a failed attempt.
func tick(dt: float) -> bool:
	if game.state == "race" and game.elapsed >= game.next_qte and game.qte_time <= 0:
		game.qte_time = 2
		game.qte_key = game.KEYS[randi() % 4]
		game.next_qte = game.elapsed + randf_range(6, 9)
		game.beep(300)
	if game.qte_time > 0:
		game.qte_time -= dt
		if game.qte_time <= 0:
			game.resolve_qte(false)
			return game.state == "tutorial"
	return false

func resolve_qte(success: bool) -> void:
	game.apply_qte_result(success)
	if game.state == "tutorial" and game.tutorial_step == 6:
		if success: game.complete_lesson()
		else:
			game.tutorial_waiting = true
			game.tutorial_label.text = "THE DOUBLE GOT IN. TRY AGAIN.\nPress only the displayed key within two seconds.\nENTER to retry. You cannot skip this lesson."

func apply_qte_result(success: bool) -> void:
	game.qte_time = 0
	game.boost = 2.5 if success else 0.0
	game.slow = 0.0 if success else 1.8
	game.banner.text = "CONTROL RECLAIMED / SPEED BOOST" if success else "THE SHADOW STEALS YOUR MOMENTUM"
	game.feedback_time = 2.5
	game.beep(740 if success else 120)
