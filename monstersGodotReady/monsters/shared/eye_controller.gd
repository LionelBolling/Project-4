@tool
extends RefCounted
## Preserve the separately edited normal/hurt geometry and its own painted UVs.
var _normal_meshes: Array[MeshInstance3D] = []
var _hurt_meshes: Array[MeshInstance3D] = []
var expression: StringName = &"normal"

func bind_model(model: Node) -> bool:
	_normal_meshes.clear()
	_hurt_meshes.clear()
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if str(mesh.name).begins_with("Eyes_Normal"):
			_normal_meshes.append(mesh)
		elif str(mesh.name).begins_with("Eyes_Hurt"):
			_hurt_meshes.append(mesh)
	set_eyes(expression)
	return not _normal_meshes.is_empty() and not _hurt_meshes.is_empty()

func set_eyes(value: StringName) -> bool:
	if value != &"normal" and value != &"hurt":
		return false
	expression = value
	for mesh in _normal_meshes:
		mesh.visible = value == &"normal"
	for mesh in _hurt_meshes:
		mesh.visible = value == &"hurt"
	return true
