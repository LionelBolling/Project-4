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
	box(root, Vector3.ZERO, Vector3(2.0, 0.85, 0.5), Color("202535"))
	for side in [-1, 1]:
		box(root, Vector3(side * 0.66, 0, 0.27), Vector3(0.46, 0.6, 0.04), Color("080c17"))
		box(root, Vector3(side * 0.66, 0, 0.3), Vector3(0.24, 0.3, 0.02), Color("4d667c"))
	box(root, Vector3(0, 0, 0.28), Vector3(0.58, 0.36, 0.04), Color("65f5db"), 0.6)
	box(root, Vector3(0, 0.64, 0), Vector3(1.2, 0.08, 0.09), Color("556273"))
	for side in [-1, 1]: box(root, Vector3(side * 0.56, 0.51, 0), Vector3(0.08, 0.3, 0.09), Color("556273"))
	return root
