@tool
extends StaticBody3D

@export var visual_mesh_path: NodePath = NodePath("Mesh")
@export var collider_path: NodePath = NodePath("CollisionShape3D")

var _last_visual_transform := Transform3D.IDENTITY
var _last_collider_transform := Transform3D.IDENTITY
var _has_transform_snapshot := false

func _ready() -> void:
	_capture_transforms()

func _process(_delta: float) -> void:
	var visual := get_node_or_null(visual_mesh_path) as MeshInstance3D
	var collider := get_node_or_null(collider_path) as CollisionShape3D
	if visual == null or collider == null:
		return
	if not _has_transform_snapshot:
		_capture_transforms()
		return
	var visual_moved := not visual.transform.is_equal_approx(_last_visual_transform)
	var collider_moved := not collider.transform.is_equal_approx(_last_collider_transform)
	if visual_moved and not collider_moved:
		collider.transform = visual.transform
	elif collider_moved and not visual_moved:
		visual.transform = collider.transform
	elif visual_moved and collider_moved and not visual.transform.is_equal_approx(collider.transform):
		collider.transform = visual.transform
	_capture_transforms()

func _capture_transforms() -> void:
	var visual := get_node_or_null(visual_mesh_path) as MeshInstance3D
	var collider := get_node_or_null(collider_path) as CollisionShape3D
	if visual == null or collider == null:
		return
	_last_visual_transform = visual.transform
	_last_collider_transform = collider.transform
	_has_transform_snapshot = true
