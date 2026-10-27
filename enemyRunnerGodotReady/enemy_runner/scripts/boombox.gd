@tool
extends Node3D
const CelMaterials = preload("cel_materials.gd")
@export var cel_shading_enabled: bool = true:
	set(value):
		cel_shading_enabled = value
		if is_inside_tree():
			call_deferred("_apply_materials")
func _ready() -> void:
	_apply_materials()
func _apply_materials() -> void:
	var model := get_node_or_null("Model")
	if model != null:
		CelMaterials.apply(model, cel_shading_enabled)
