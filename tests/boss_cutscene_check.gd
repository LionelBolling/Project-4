extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var failures := 0
	change_scene_to_file("res://scenes/boss_cutscene_start.tscn")
	await process_frame
	await process_frame
	var cutscene := current_scene
	var clip := cutscene.get_node("Cutscene1")
	var animation_player := clip.get_node("AnimationPlayer") as AnimationPlayer
	var animation := animation_player.get_animation("cutscene1")
	if not animation_player.is_playing() or animation.length < 4.5:
		push_error("The exported cutscene did not start its full animation")
		failures += 1
	var camera := cutscene.get_node("Camera3D") as Camera3D
	var skeleton := clip.get_node("Player | Runner_Rig controls/Skeleton3D") as Skeleton3D
	var head := (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Head_2"))).origin
	var toward_player := (head - camera.global_position).normalized()
	if -camera.global_basis.z.dot(toward_player) < 0.99:
		push_error("The camera is not centered on the Player")
		failures += 1
	await create_timer(4.5).timeout
	if is_instance_valid(cutscene):
		var cover := cutscene.get("fade_cover") as ColorRect
		if cover == null or cover.color.a < 0.1:
			push_error("The cutscene did not start fading near its end")
			failures += 1
	else:
		push_error("The cutscene ended before the fade")
		failures += 1
	await create_timer(1.2).timeout
	if current_scene == null or current_scene.scene_file_path != "res://scenes/bossfight.tscn":
		push_error("The cutscene did not continue to the bossfight")
		failures += 1
	print("BOSS CUTSCENE: ", failures, " failures")
	quit(1 if failures else 0)
