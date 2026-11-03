extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	change_scene_to_file("res://scenes/boss_cutscene_start.tscn")
	await process_frame
	await process_frame
	var clip := current_scene.get_node("Cutscene1")
	var failures := 0
	for rig_name in ["Player | Runner_Rig controls", "Shadow | Runner_Rig controls"]:
		var rig := clip.get_node(rig_name)
		var colored := 0
		var faces := 0
		for child in rig.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			if str(mesh.name).begins_with("Face_"):
				var face := mesh.material_override as StandardMaterial3D
				if face != null and face.albedo_texture != null:
					faces += 1
				continue
			for surface in range(mesh.mesh.get_surface_count()):
				var paint := mesh.get_surface_override_material(surface) as ShaderMaterial
				if paint != null and paint.get_shader_parameter("paint_color") != Color.WHITE:
					colored += 1
		if colored < 10 or faces != 4:
			push_error("Missing cutscene character paints or face textures: " + rig_name)
			failures += 1
	print("CUTSCENE MATERIALS: ", failures, " failures")
	quit(1 if failures else 0)
