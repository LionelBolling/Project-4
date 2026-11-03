extends SceneTree

const LEVELS := [
	["res://scenes/level_0.tscn", "GoalTapePiece_1", "CourseGeometry/FinishLine"],
	["res://scenes/level_1.tscn", "GoalTapePiece_2", "FinishLine"],
	["res://scenes/Level2.tscn", "GoalTapePiece_3", "CourseGeometry/FinishLine"],
	["res://scenes/level_3_beta.tscn", "GoalTapePiece_4", "FinishLine"],
]

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var failures := 0
	for data in LEVELS:
		var level := load(data[0]).instantiate() as Node3D
		root.add_child(level)
		await physics_frame
		var piece := level.find_child(data[1], true, false) as Node3D
		var finish := level.get_node_or_null(data[2]) as Node3D
		if piece == null or finish == null:
			push_error("Missing tape or finish in " + data[0])
			failures += 1
		else:
			var horizontal_gap := Vector2(piece.global_position.x - finish.global_position.x, piece.global_position.z - finish.global_position.z).length()
			var model_count := piece.find_children("*", "MeshInstance3D", true, false).size()
			if horizontal_gap > 2.0 or piece.global_position.y < finish.global_position.y + 1.0 or model_count == 0:
				push_error("Tape is missing or misplaced in " + data[0])
				failures += 1
			else:
				print(data[0], " tape at finish; meshes: ", model_count)
		level.queue_free()
		await process_frame
	print("TAPE GOALS: ", failures, " failures")
	quit(1 if failures else 0)
