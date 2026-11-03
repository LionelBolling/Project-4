@tool
extends Node3D

const CEL_SHADER = preload("res://runner/materials/runner_cel.gdshader")

func _ready() -> void:
	_apply_character(get_node_or_null("Player | Runner_Rig controls"))
	_apply_character(get_node_or_null("Shadow | Runner_Rig controls"))

func _apply_character(rig: Node) -> void:
	if rig == null:
		return
	for child in rig.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh.mesh == null:
			continue
		if str(mesh.name).begins_with("Face_"):
			_apply_face(mesh)
			continue
		for surface in range(mesh.mesh.get_surface_count()):
			var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var material := ShaderMaterial.new()
			material.resource_name = source.resource_name + "_CutsceneCel"
			material.shader = CEL_SHADER
			material.set_shader_parameter("paint_color", source.albedo_color)
			material.set_shader_parameter("use_paint_texture", source.albedo_texture != null)
			if source.albedo_texture != null:
				material.set_shader_parameter("paint_texture", source.albedo_texture)
			var label := source.resource_name.to_lower()
			var flat_detail := "ivory painted highlight" in label or "drawn highlight" in label
			material.set_shader_parameter("flat_painted_detail", flat_detail)
			var neon := "electric magenta" in label or "bright edge" in label or "cyan" in label or "scarf | neon blue" in label
			material.set_shader_parameter("emission_strength", 1.0 if flat_detail else 2.0 if neon else 0.34)
			mesh.set_surface_override_material(surface, material)

func _apply_face(mesh: MeshInstance3D) -> void:
	var source := mesh.mesh.surface_get_material(0) as StandardMaterial3D
	if source == null:
		return
	var material := source.duplicate() as StandardMaterial3D
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.render_priority = 1 if "Eyes" in mesh.name else 2 if "Brows" in mesh.name else 3 if "Nose" in mesh.name else 4
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
