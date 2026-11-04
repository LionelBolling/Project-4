extends Node3D
## The sealed portal opens onto the same neon world the captive must return to.
const Props = preload("res://scripts/story_props.gd")
var motes: Array[Node3D] = []
var rings: Array[Node3D] = []
var phase_light: OmniLight3D
var elapsed := 0.0

func _ready() -> void:
	name = "EndingCity"
	var moon := DirectionalLight3D.new()
	add_child(moon)
	moon.rotation_degrees = Vector3(-38, -28, 0)
	moon.light_color = Color("8bb9ff")
	moon.light_energy = 1.4
	var rim := DirectionalLight3D.new()
	add_child(rim)
	rim.rotation_degrees = Vector3(-25, 145, 0)
	rim.light_color = Color("e18bda")
	rim.light_energy = 0.8
	Props.box(self, Vector3(0, -0.22, 35), Vector3(140, 0.2, 150), Color("080d23"))
	Props.box(self, Vector3(0, -0.08, 35), Vector3(11, 0.12, 100), Color("12192f"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3481
	for side in [-1, 1]:
		for row in range(3):
			for i in range(11):
				var x: float = side * (10.0 + row * 13.0)
				var z := -16.0 + i * 10.0
				var height := rng.randf_range(9, 32) + row * 5
				var color := Color("39dce8") if (i + row) % 2 == 0 else Color("df3ba9")
				Props.box(self, Vector3(x, height / 2, z), Vector3(7, height, 7), Color("11182e"))
				for edge in [-1, 1]:
					Props.box(self, Vector3(x + edge * 3.5, height / 2, z - 3.55), Vector3(0.07, height, 0.08), color, 2.8)
				for floor_index in range(2, int(height), 3):
					Props.box(self, Vector3(x, floor_index, z - 3.56), Vector3(5.8, 0.12, 0.08), color.darkened(0.35), 1.8)
		for i in range(20):
			Props.box(self, Vector3(side * 5.3, 0.03, i * 4), Vector3(0.09, 0.05, 2.8), Color("32cde1"), 3)
		for i in range(8):
			var z := 5.0 + i * 10
			Props.box(self, Vector3(side * 6.2, 2.5, z), Vector3(0.12, 5, 0.12), Color("263658"))
			Props.box(self, Vector3(side * 5.6, 5, z), Vector3(1.4, 0.1, 0.2), Color("8ce9ff"), 4)
			var lamp := OmniLight3D.new()
			add_child(lamp)
			lamp.position = Vector3(side * 5.6, 4, z)
			lamp.light_color = Color("43badb")
			lamp.light_energy = 1.8
			lamp.omni_range = 9
	for z in [22.0, 52.0, 82.0]:
		Props.box(self, Vector3(0, 8, z), Vector3(20, 0.3, 0.3), Color("e449c2"), 3)
		var sign := Label3D.new()
		add_child(sign)
		sign.position = Vector3(0, 9.8, z)
		sign.rotation.y = PI
		sign.text = "NEON FEVER" if z == 22 else "KEEP DREAMING"
		sign.font_size = 96
		sign.pixel_size = 0.015
		sign.modulate = Color("6cf5ee")
	for i in range(60):
		var mote := Props.box(self, Vector3(rng.randf_range(-18, 18), rng.randf_range(0.3, 12), rng.randf_range(-5, 75)), Vector3.ONE * 0.035, Color("8deaff"), 3)
		motes.append(mote)
	for i in range(3):
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.72
		mesh.outer_radius = 0.76
		ring.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color("53f8f2")
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 4
		ring.material_override = mat
		add_child(ring)
		ring.hide()
		rings.append(ring)
	phase_light = OmniLight3D.new()
	add_child(phase_light)
	phase_light.light_color = Color("51fff3")
	phase_light.omni_range = 7
	phase_light.light_energy = 0

func _process(dt: float) -> void:
	elapsed += dt
	for i in range(motes.size()):
		motes[i].position.y = fposmod(motes[i].position.y + dt * (0.16 + i % 4 * 0.05), 12.0)
		motes[i].rotation.y += dt

func phase_effect(progress: float, origin: Vector3) -> void:
	var active := progress > 0.0 and progress < 1.0
	for i in range(rings.size()):
		rings[i].visible = active
		rings[i].position = origin + Vector3(0, fposmod(progress * 3 + i * 0.7, 2.2), 0)
		rings[i].scale = Vector3.ONE * (1 + sin(progress * TAU * 3 + i) * 0.12)
	phase_light.position = origin + Vector3.UP
	phase_light.light_energy = sin(progress * PI) * 5 if active else 0.0

static func body_opacity(body: Node3D, opacity: float) -> void:
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		mesh.transparency = 1.0 - opacity
		if not mesh.has_meta("phase_materials"):
			var materials: Array[ShaderMaterial] = []
			for surface in range(mesh.mesh.get_surface_count()):
				var source: Material = mesh.get_active_material(surface)
				if source == null: continue
				var material := ShaderMaterial.new()
				var shader := Shader.new()
				var code: String
				if source is ShaderMaterial:
					material = source.duplicate()
					code = source.shader.code
				else:
					code = "shader_type spatial; uniform vec4 paint_color : source_color = vec4(1.0); uniform sampler2D paint_texture : source_color; uniform bool use_paint_texture = false; void fragment() { vec4 paint = paint_color; if(use_paint_texture) paint *= texture(paint_texture, UV); if(paint.a < 0.1) discard; ALBEDO = paint.rgb; ROUGHNESS = 1.0; }"
					material.set_shader_parameter("paint_color", source.albedo_color)
					material.set_shader_parameter("use_paint_texture", source.albedo_texture != null)
					if source.albedo_texture != null:
						material.set_shader_parameter("paint_texture", source.albedo_texture)
				code = code.replace("void fragment() {", "uniform float phase_opacity = 1.0; void fragment() { float noise = fract(sin(dot(floor(FRAGCOORD.xy / 3.0), vec2(12.9898,78.233))) * 43758.5453); if(noise > phase_opacity) discard;")
				shader.code = code
				material.shader = shader
				mesh.set_surface_override_material(surface, material)
				materials.append(material)
			mesh.set_meta("phase_materials", materials)
		for material in mesh.get_meta("phase_materials"):
			material.set_shader_parameter("phase_opacity", opacity)
