@tool
extends Node3D
## The imported GLB also contains cutscene characters; expose only its finished tape.

func _ready() -> void:
	for child in get_children():
		if child is Node3D:
			child.visible = str(child.name) == "Tape_Rig | pose Tape_Master"
