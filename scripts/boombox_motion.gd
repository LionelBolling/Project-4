extends Node3D

var playing := true
var clock := 0.0
var bars: Array[MeshInstance3D] = []
var home := Vector3.ZERO
var base_scale := Vector3.ONE
var glow: OmniLight3D

func _ready() -> void:
	home = get_parent().position
	base_scale = get_parent().scale
	for i in range(13):
		bars.append(preload("res://scripts/story_props.gd").box(self, Vector3((i - 6) * 0.13, 0.9, 0), Vector3(0.065, 0.3, 0.065), Color("65f5db") if i % 2 else Color("fa60b8"), 2.0))
	glow = OmniLight3D.new()
	glow.light_color = Color("b35cff")
	glow.omni_range = 4
	add_child(glow)

func _process(dt: float) -> void:
	clock += dt
	var beat := pow(maxf(0, sin(clock * TAU * 2)), 3)
	var box := get_parent() as Node3D
	box.position = home + Vector3(0, beat * 0.07, 0) if playing else home
	box.rotation.z = sin(clock * TAU * 2) * 0.025 if playing else 0.0
	box.scale = base_scale * Vector3(1 + beat * 0.025, 1 - beat * 0.035, 1) if playing else base_scale
	glow.light_energy = 0.6 + beat * 1.3 if playing else 0.0
	for i in range(bars.size()):
		bars[i].visible = playing
		bars[i].scale.y = 0.3 + absf(sin(clock * 7 + i * 0.8)) * (1 + beat)
