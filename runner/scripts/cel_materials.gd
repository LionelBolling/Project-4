extends RefCounted
## Material overrides preserve the imported mesh, skin, UVs and source paint.
const CEL_SHADER = preload("../materials/runner_cel.gdshader")

static func apply(root: Node, enabled: bool = true) -> void:
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.push_front(root)
	for node in meshes:
		var mesh := node as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		if str(mesh.name).begins_with("Face_"):
			if Engine.is_editor_hint():
				_apply_editor_face(mesh)
			continue
		for surface in range(mesh.mesh.get_surface_count()):
			if not enabled:
				mesh.set_surface_override_material(surface, null)
				continue
			var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var material := ShaderMaterial.new()
			material.shader = CEL_SHADER
			material.resource_name = source.resource_name + "_Cel"
			material.set_shader_parameter("paint_color", source.albedo_color)
			material.set_shader_parameter("use_paint_texture", source.albedo_texture != null)
			if source.albedo_texture != null:
				material.set_shader_parameter("paint_texture", source.albedo_texture)
			var label := source.resource_name.to_lower()
			var flat_detail := "ivory painted highlight" in label or "drawn highlight" in label
			material.set_shader_parameter("flat_painted_detail", flat_detail)
			var neon_surface := (
				"cyan panels" in label or "purple cone facet" in label or "reference purple" in label
				or "electric magenta" in label or "bright edge" in label or "cyan rubber" in label or "cyan side panels" in label
			)
			var jacket_surface := "electric magenta" in label and str(mesh.name).begins_with("Jacket")
			var emission_strength := 1.1 if jacket_surface else 2.4 if neon_surface else 1.0 if flat_detail else 0.34
			material.set_shader_parameter("emission_strength", emission_strength)
			mesh.set_surface_override_material(surface, material)

static func _apply_editor_face(mesh: MeshInstance3D) -> void:
	var source := mesh.mesh.surface_get_material(0) as StandardMaterial3D
	if source == null:
		return
	var material := source.duplicate() as StandardMaterial3D
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.render_priority = {"Face_Eyes": 1, "Face_Brows": 2, "Face_Nose": 3, "Face_Mouth": 4}.get(str(mesh.name), 1)
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
