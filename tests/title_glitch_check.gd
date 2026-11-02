extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	title.set_process(false)
	await process_frame
	await process_frame
	for moment in [0.0, 2.49, 2.5, 3.0, 3.5, 4.99, 5.0, 6.0]:
		title._elapsed = moment
		title._process(0.0)
		var expected: bool = moment >= 2.5 and fposmod(moment, 2.5) < 1.0
		assert(title._background_material.get_shader_parameter("neon_amount") == (1.0 if expected else 0.0))
	print("Title bedroom/neon timing checks passed")
	quit()
