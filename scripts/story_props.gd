extends RefCounted
## Small reusable story objects, built from geometry without additional imports.

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	mat.emission_enabled = glow > 0.0
	mat.emission = color
	mat.emission_energy_multiplier = glow
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

static func tape(parent: Node3D, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = pos
	box(root, Vector3.ZERO, Vector3(0.8, 0.5, 0.12), Color("171728"))
	box(root, Vector3(0, 0.08, 0.07), Vector3(0.68, 0.22, 0.02), Color("ffd384"), 1.4)
	for side in [-1, 1]:
		box(root, Vector3(side * 0.19, 0, 0.09), Vector3(0.12, 0.12, 0.03), Color("65f5db"), 2)
	return root

static func person(parent: Node3D, pos: Vector3, shadow: bool = false) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = pos
	var color := Color("100d21") if shadow else Color("e4b88a")
	box(root, Vector3(0, 1.1, 0), Vector3(0.5, 0.7, 0.2), color)
	box(root, Vector3(0, 1.7, 0), Vector3(0.32, 0.35, 0.25), color)
	for side in [-1, 1]:
		box(root, Vector3(side * 0.16, 0.42, 0), Vector3(0.16, 0.85, 0.18), color)
		box(root, Vector3(side * 0.39, 1.1, 0), Vector3(0.18, 0.7, 0.18), color)
		box(root, Vector3(side * 0.08, 1.73, 0.14), Vector3(0.04, 0.04, 0.025), Color("ad70fa") if shadow else Color("65f5db"), 2)
	return root

static func boombox(parent: Node3D, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = pos
	var model := preload("res://runner/boombox.tscn").instantiate()
	root.add_child(model)
	var bounds := _model_bounds(model, Transform3D.IDENTITY)
	var factor := 2.0 / maxf(bounds.size.x, 0.001)
	model.scale = Vector3.ONE * factor
	model.position = -bounds.get_center() * factor
	model.rotation.y = PI
	return root

static func _model_bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform * node.transform
	var bounds := AABB()
	if node is MeshInstance3D and node.mesh != null:
		bounds = transform * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_bounds := _model_bounds(child, transform)
			if child_bounds.size.length_squared() > 0:
				bounds = child_bounds if bounds.size.length_squared() == 0 else bounds.merge(child_bounds)
	return bounds
