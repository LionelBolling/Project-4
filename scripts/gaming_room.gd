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
			Props.box(room, Vector3(2.3 + col * 0.6, 2.65 + row * 0.42, -3.25), Vector3(0.48, 0.3, 0.12), Color("20385c") if (row + col) % 2 else Color("122540"))
	for y in [2.2, 3.2]:
		Props.box(room, Vector3(-5.9, y, -3.8), Vector3(1.5, 0.08, 1.1), Color("1d3352"))
		for i in range(5): Props.box(room, Vector3(-6.4 + i * 0.22, y + 0.23, -3.7), Vector3(0.12, 0.42, 0.6), Color("3d5d80").lightened(i * 0.05))
	Props.box(room, Vector3(-5.8, 0.55, 3), Vector3(1.8, 1.1, 0.7), Color("15283f"))
	Props.box(room, Vector3(-5.8, 1.2, 3), Vector3(0.8, 0.18, 0.45), Color("0c1424"))
	for x in [-6.05, -5.55]: Props.box(room, Vector3(x, 1.35, 3), Vector3(0.2, 0.12, 0.22), Color("6d86ac"))
	var glow := OmniLight3D.new()
	room.add_child(glow)
	glow.position = Vector3(4.4, 2, -1.7)
	glow.light_color = Color("4f8bff")
	glow.light_energy = 1.4
	glow.omni_range = 6
