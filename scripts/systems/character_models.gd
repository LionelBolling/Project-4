extends RefCounted
## character models implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

func capsule(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(a.distance_to(b), radius * 2.01)
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = (a + b) / 2
	if a.distance_to(b) > 0.001:
		var up = Vector3.FORWARD if absf((b - a).normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
		node.look_at_from_position(node.global_position, node.global_position + (b - a), up)
		node.rotate_object_local(Vector3.RIGHT, PI / 2)
	return node

func orb(parent: Node3D, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var m = SphereMesh.new()
	m.radius = 0.5
	m.height = 1
	n.mesh = m
	n.material_override = mat
	parent.add_child(n)
	n.position = pos
	n.scale = scale_value
	return n

func make_runner(parent: Node3D, _color: Color) -> Node3D:
	# The original and double share the same face, clothes and identifying scar.
	var root = Node3D.new()
	parent.add_child(root)
	var cloth = game.material(Color("283d4b"))
	var seam = game.material(Color("70868c"))
	var leather = game.material(Color("17212a"))
	var skin = game.material(Color("b99a86"))
	var hair = game.material(Color("17151c"))
	var white = game.material(Color("b8b5a9"))
	var dark = game.material(Color("140e18"))
	var eye = game.material(Color("c6e7de"), 0.7)
	game.orb(root, Vector3(0, 1.16, 0), Vector3(0.62, 0.77, 0.39), cloth)
	game.box(root, Vector3(0, 0.87, 0), Vector3(0.47, 0.19, 0.31), leather)
	game.box(root, Vector3(0, 1.15, -0.205), Vector3(0.025, 0.57, 0.025), seam)
	game.box(root, Vector3(0.14, 1.23, -0.205), Vector3(0.17, 0.12, 0.025), leather)
	game.box(root, Vector3(-0.14, 1.23, -0.205), Vector3(0.17, 0.12, 0.025), leather)
	for side in [-1, 1]:
		game.capsule(root, Vector3(side * 0.12, 1.38, -0.14), Vector3(side * 0.25, 1.26, -0.21), 0.036, seam)
		var leg = Node3D.new()
		root.add_child(leg)
		leg.name = "LegL" if side < 0 else "LegR"
		leg.position = Vector3(side * 0.17, 0.84, 0)
		game.capsule(leg, Vector3.ZERO, Vector3(0, -0.36, 0), 0.12, leather)
		game.capsule(leg, Vector3(0, -0.36, 0), Vector3(0, -0.68, 0), 0.095, cloth)
		game.box(leg, Vector3(0, -0.75, -0.055), Vector3(0.23, 0.16, 0.39), leather)
		for lace in range(3): game.box(leg, Vector3(0, -0.662, -0.08 - lace * 0.045), Vector3(0.13, 0.015, 0.015), seam)
		var arm = Node3D.new()
		root.add_child(arm)
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.33, 1.4, 0)
		game.capsule(arm, Vector3.ZERO, Vector3(side * 0.06, -0.33, 0), 0.12, cloth)
		game.capsule(arm, Vector3(side * 0.06, -0.33, 0), Vector3(side * 0.06, -0.59, -0.06), 0.09, cloth)
		game.box(arm, Vector3(side * 0.06, -0.59, -0.06), Vector3(0.17, 0.08, 0.18), seam)
		game.make_hand(arm, Vector3(side * 0.06, -0.7, -0.06), side, skin)
		if side == -1:
			game.box(arm, Vector3(side * 0.06, -0.53, -0.15), Vector3(0.11, 0.09, 0.025), leather)
			game.box(arm, Vector3(side * 0.06, -0.53, -0.166), Vector3(0.075, 0.05, 0.01), game.material(game.MINT, 0.5))
	game.capsule(root, Vector3(0, 1.45, 0), Vector3(0, 1.65, 0), 0.09, skin)
	game.orb(root, Vector3(0, 1.8, 0), Vector3(0.37, 0.49, 0.35), skin)
	game.orb(root, Vector3(0, 1.97, 0.035), Vector3(0.39, 0.22, 0.36), hair)
	for i in range(11):
		game.capsule(root, Vector3(-0.17 + i * 0.033, 1.98, -0.08), Vector3(-0.16 + i * 0.032, 1.87 - 0.04 * sin(i), -0.16), 0.022, hair)
	for side in [-1, 1]:
		game.orb(root, Vector3(side * 0.183, 1.8, 0), Vector3(0.065, 0.12, 0.08), skin)
		game.orb(root, Vector3(side * 0.075, 1.83, -0.153), Vector3(0.1, 0.057, 0.042), white)
		game.orb(root, Vector3(side * 0.075, 1.83, -0.176), Vector3(0.035, 0.039, 0.016), eye)
		game.orb(root, Vector3(side * 0.075, 1.83, -0.185), Vector3(0.015, 0.03, 0.008), dark)
		game.capsule(root, Vector3(side * 0.035, 1.87, -0.16), Vector3(side * 0.12, 1.88, -0.145), 0.018, hair)
	game.orb(root, Vector3(0, 1.78, -0.18), Vector3(0.055, 0.09, 0.085), skin)
	var mouth = game.orb(root, Vector3(0, 1.69, -0.146), Vector3(0.12, 0.035, 0.04), dark)
	mouth.name = "Mouth"
	for i in range(6): game.box(root, Vector3(-0.047 + i * 0.019, 1.704, -0.171), Vector3(0.014, 0.014, 0.012), white)
	game.capsule(root, Vector3(-0.115, 1.76, -0.14), Vector3(-0.07, 1.69, -0.155), 0.007, game.material(Color("8f5a61")))
	return root

func make_hand(parent: Node3D, p: Vector3, side: int, skin: Material) -> void:
	var hand = Node3D.new()
	hand.name = "HandL" if side < 0 else "HandR"
	parent.add_child(hand)
	hand.position = p
	var nails = game.material(Color("c6aa98"))
	nails.roughness = 0.48
	# A narrow wrist flows into a flattened palm and a soft thumb pad.
	game.orb(hand, Vector3(0, 0.068, 0), Vector3(0.098, 0.11, 0.071), skin)
	game.orb(hand, Vector3(0, -0.012, 0), Vector3(0.148, 0.173, 0.077), skin)
	game.orb(hand, Vector3(-side * 0.043, 0.008, -0.012), Vector3(0.066, 0.105, 0.065), skin)
	# Index through little finger: mirrored spacing, distinct lengths and a relaxed curl.
	var lengths = [0.119, 0.137, 0.128, 0.099]
	var radii = [0.0175, 0.0185, 0.017, 0.0145]
	for i in range(4):
		var x = side * (-0.051 + i * 0.034)
		var length: float = lengths[i]
		var radius: float = radii[i]
		var base = Vector3(x, -0.067 + (0.012 if i == 3 else 0.0), 0)
		var joint = base + Vector3(side * (i - 1.3) * 0.004, -length * 0.46, -0.007)
		var bend = joint + Vector3(0, -length * 0.30, -0.015 - i * 0.002)
		var tip = bend + Vector3(0, -length * 0.24, -0.019)
		game.orb(hand, base, Vector3(radius * 2.15, radius * 2.0, radius * 2.1), skin)
		finger_segment(hand, base, joint, radius, skin)
		finger_segment(hand, joint, bend, radius * 0.88, skin)
		finger_segment(hand, bend, tip, radius * 0.76, skin)
		var nail = game.orb(hand, tip + Vector3(0, 0.009, 0.011), Vector3(radius * 1.22, 0.025, 0.004), nails)
		nail.rotation.x = -0.55
	var thumb_base = Vector3(-side * 0.054, 0.016, -0.006)
	var thumb_joint = Vector3(-side * 0.091, -0.022, -0.022)
	var thumb_tip = Vector3(-side * 0.103, -0.065, -0.042)
	finger_segment(hand, thumb_base, thumb_joint, 0.023, skin)
	finger_segment(hand, thumb_joint, thumb_tip, 0.019, skin)
	var thumbnail = game.orb(hand, thumb_tip + Vector3(0, 0.009, 0.014), Vector3(0.023, 0.026, 0.004), nails)
	thumbnail.rotation = Vector3(-0.4, 0, -side * 0.22)

func finger_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, skin: Material) -> void:
	# Capsule height includes its end caps; keep the joints exactly at a and b.
	var segment = game.capsule(parent, a, b, radius, skin)
	segment.mesh = segment.mesh.duplicate()
	segment.mesh.height = a.distance_to(b) + radius * 2.0

func make_view_arms() -> Node3D:
	var root = Node3D.new()
	game.camera.add_child(root)
	var cloth = game.material(Color("283d4b"))
	var seams = game.material(Color("70868c"))
	var skin = game.material(Color("b99a86"))
	for side in [-1, 1]:
		var arm = Node3D.new()
		root.add_child(arm)
		arm.position = Vector3(side * 0.38, -0.36, -0.37)
		arm.rotation = Vector3(-0.9, side * -0.18, side * -0.12)
		game.capsule(arm, Vector3(side * 0.12, -0.45, 0.05), Vector3(0, -0.04, 0), 0.095, cloth)
		game.box(arm, Vector3(0, -0.025, 0), Vector3(0.17, 0.075, 0.16), seams)
		var hand = Node3D.new()
		arm.add_child(hand)
		hand.position = Vector3(0, 0.08, 0)
		hand.rotation.z = PI
		game.make_hand(hand, Vector3.ZERO, -side, skin)
		# Wristwatch, knuckle marks and sleeve stitching match the double.
		if side == -1:
			game.box(arm, Vector3(0, -0.09, -0.085), Vector3(0.11, 0.09, 0.025), game.material(Color("151923")))
			game.box(arm, Vector3(0, -0.09, -0.101), Vector3(0.075, 0.05, 0.01), game.material(game.MINT, 0.5))
		for i in range(4): game.box(arm, Vector3(0.075, -0.12 - i * 0.055, -0.04), Vector3(0.008, 0.026, 0.01), seams)
	disable_view_shadows(root)
	return root

func disable_view_shadows(node: Node) -> void:
	if node is GeometryInstance3D: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): disable_view_shadows(child)
