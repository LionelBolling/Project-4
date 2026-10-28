extends RefCounted
## Instance-only wardrobe; the race asset and imported meshes stay untouched.
static func apply(model: Node3D) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var label := str(mesh.name)
		if label.begins_with("Boombox") or label.begins_with("Belt") or label.begins_with("Hair white") or (label.begins_with("Jacket") and not "sleeve" in label) or label.begins_with("Glove"):
			mesh.hide()
			continue
		var color := Color.TRANSPARENT
		if label.begins_with("Pants") or label.begins_with("Leg underneath"):
			color = Color("375b89")
		elif label.begins_with("Undershirt") or "sleeve" in label:
			color = Color("c8c9c6")
		elif label.begins_with("Sneaker"):
			color = Color("c3c5cb") if "sole" in label or "inset" in label else Color("282b35")
		elif label.begins_with("Hand palm"):
			color = Color("925d3f")
		if color.a == 0: continue
		for i in range(mesh.mesh.get_surface_count()):
			var material := StandardMaterial3D.new()
			material.albedo_color = color.darkened(i * 0.12)
			material.roughness = 0.95
			mesh.set_surface_override_material(i, material)
