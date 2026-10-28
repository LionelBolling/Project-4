@tool
extends RefCounted
const TOON = preload("monster_toon.gdshader")

static func apply(model: Node, flat_names: Array, enabled: bool) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface in range(mesh.mesh.get_surface_count()):
			var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var is_eye := str(mesh.name).begins_with("Eyes_")
			if is_eye or source.albedo_texture != null:
				var art := source.duplicate() as StandardMaterial3D
				art.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				art.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				art.cull_mode = BaseMaterial3D.CULL_DISABLED
				art.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				art.render_priority = 2 if is_eye else 1
				mesh.set_surface_override_material(surface, art)
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				continue
			if not enabled:
				mesh.set_surface_override_material(surface, null)
				continue
			var material := ShaderMaterial.new()
			material.shader = TOON
			material.resource_name = source.resource_name + "_Toon"
			material.set_shader_parameter("paint_color", source.albedo_color)
			var flat := false
			for label in flat_names:
				if str(source.resource_name).begins_with(str(label)):
					flat = true
					break
			material.set_shader_parameter("flat_painted_detail", flat)
			mesh.set_surface_override_material(surface, material)
