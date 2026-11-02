extends RefCounted
const Props = preload("res://scripts/story_props.gd")

static func build(room: Node3D) -> void:
	# Wide desk, two monitors, keyboard, mouse mat and glass-sided RGB tower.
	Props.box(room, Vector3(4.3, 0.9, -2.3), Vector3(3.9, 0.16, 1.5), Color("14233b"))
	for x in [2.55, 6.05]: Props.box(room, Vector3(x, 0.45, -2.3), Vector3(0.1, 0.9, 1.3), Color("0a1427"))
	for x in [3.4, 4.9]:
		Props.box(room, Vector3(x, 1.55, -2.8), Vector3(1.4, 0.85, 0.1), Color("080e1a"))
		Props.box(room, Vector3(x, 1.55, -2.73), Vector3(1.29, 0.73, 0.015), Color("183c6b"), 0.7)
		Props.box(room, Vector3(x, 1.05, -2.8), Vector3(0.07, 0.3, 0.08), Color("53647a"))
		for i in range(6): Props.box(room, Vector3(x - 0.45 + i * 0.18, 1.5 + sin(i) * 0.17, -2.71), Vector3(0.1, 0.16 + i * 0.03, 0.01), Color("487ed1"), 0.8)
	Props.box(room, Vector3(4, 1, -1.95), Vector3(2.4, 0.025, 0.6), Color("090e21"))
	Props.box(room, Vector3(3.7, 1.04, -2), Vector3(1.2, 0.05, 0.34), Color("202d43"))
	for i in range(14): Props.box(room, Vector3(3.17 + i * 0.08, 1.07, -2), Vector3(0.045, 0.01, 0.24), Color("5386c4"), 0.8)
	Props.box(room, Vector3(4.7, 1.04, -1.95), Vector3(0.15, 0.07, 0.24), Color("637ba2"))
	Props.box(room, Vector3(5.8, 1.4, -2.1), Vector3(0.48, 0.9, 0.78), Color("080f20"))
	for y in [1.2, 1.55]:
		Props.box(room, Vector3(5.8, y, -1.7), Vector3(0.32, 0.26, 0.025), Color("4887d3"), 1.1)
		Props.box(room, Vector3(5.8, y, -1.68), Vector3(0.19, 0.14, 0.025), Color("101b32"))
	# Padded chair and five-point base.
	Props.box(room, Vector3(4.1, 0.65, -0.7), Vector3(0.85, 0.18, 0.8), Color("182b49"))
	Props.box(room, Vector3(4.1, 1.25, -0.25), Vector3(0.85, 1.3, 0.18), Color("193864"))
	Props.box(room, Vector3(4.1, 0.3, -0.7), Vector3(0.09, 0.6, 0.09), Color("65778e"))
	for i in range(5):
		var leg := Props.box(room, Vector3(4.1, 0.08, -0.7), Vector3(0.1, 0.08, 1.1), Color("151e31"))
		leg.rotation.y = i * TAU / 5
	# Acoustic tiles, shelving, controller and console beneath wall art.
	for row in range(3):
		for col in range(7):
			Props.box(room, Vector3(2.3 + col * 0.6, 2.25 + row * 0.28, -7.35), Vector3(0.48, 0.3, 0.12), Color("20385c") if (row + col) % 2 else Color("122540"))
	for y in [2.2, 3.2]:
		Props.box(room, Vector3(-5.9, y, -3.8), Vector3(1.5, 0.08, 1.1), Color("1d3352"))
		for i in range(5): Props.box(room, Vector3(-6.4 + i * 0.22, y + 0.23, -3.7), Vector3(0.12, 0.42, 0.6), Color("3d5d80").lightened(i * 0.05))
	Props.box(room, Vector3(-8.4, 0.55, 3), Vector3(1.8, 1.1, 0.7), Color("15283f"))
	Props.box(room, Vector3(-8.4, 1.2, 3), Vector3(0.8, 0.18, 0.45), Color("0c1424"))
	for x in [-8.65, -8.15]: Props.box(room, Vector3(x, 1.35, 3), Vector3(0.2, 0.12, 0.22), Color("6d86ac"))
	var glow := OmniLight3D.new()
	room.add_child(glow)
	glow.position = Vector3(4.4, 2, -1.7)
	glow.light_color = Color("4f8bff")
	glow.light_energy = 1.4
	glow.omni_range = 6
	# RGB desk edging and a large illuminated desk mat.
	Props.box(room, Vector3(4.3, 0.91, -1.53), Vector3(3.9, 0.035, 0.025), Color("ec40bd"), 1.2)
	Props.box(room, Vector3(4, 1.02, -1.95), Vector3(2.5, 0.012, 0.67), Color("28c7dc"), 0.8)
	Props.box(room, Vector3(4, 1.035, -1.95), Vector3(2.44, 0.012, 0.61), Color("101729"))
	# Two circular RGB fans in the PC case.
	for y in [1.2, 1.55]:
		var fan := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.085
		ring.outer_radius = 0.125
		fan.mesh = ring
		fan.position = Vector3(5.8, y, -1.65)
		fan.rotation.x = PI / 2
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("e34cbd")
		mat.emission_enabled = true
		mat.emission = Color("e34cbd")
		mat.emission_energy_multiplier = 1.2
		fan.material_override = mat
		room.add_child(fan)
	# Headset on its stand beside the keyboard.
	Props.box(room, Vector3(2.8, 1.02, -2.1), Vector3(0.32, 0.03, 0.24), Color("293a56"))
	Props.box(room, Vector3(2.8, 1.25, -2.1), Vector3(0.045, 0.45, 0.045), Color("53647a"))
	Props.box(room, Vector3(2.8, 1.52, -2.1), Vector3(0.34, 0.06, 0.09), Color("db58b2"))
	for side in [-1, 1]:
		Props.box(room, Vector3(2.8 + side * 0.17, 1.4, -2.1), Vector3(0.09, 0.25, 0.15), Color("202038"))
	# Wall-mounted geometric light panels above the gaming setup.
	for i in range(7):
		var tile := Props.box(room, Vector3(2.5 + i * 0.53, 3.35 + (i % 2) * 0.35, -7.35), Vector3(0.36, 0.36, 0.045), Color("39b7dc") if i % 2 else Color("d74aa6"), 0.9)
		tile.rotation.z = PI / 4
	# Gaming posters and a display shelf on the rear wall.
	for i in range(2):
		var x := -2.6 + i * 1.5
		Props.box(room, Vector3(x, 2.6, -7.35), Vector3(1.1, 1.55, 0.08), Color("070e20"))
		for j in range(5):
			var stripe := Props.box(room, Vector3(x - 0.36 + j * 0.18, 2.6, -7.29), Vector3(0.07, 0.6 + sin(j * 2.0) * 0.4, 0.025), Color("c3429d") if i == 0 else Color("38b8ca"), 0.6)
			stripe.rotation.z = -0.4
