extends "res://scripts/rewind_story.gd"
## Build the actual opening bedroom without starting its story or taking input.
func _ready() -> void:
	controls = Label.new()
	_build_room()
	controls.free()
	walker.process_mode = Node.PROCESS_MODE_DISABLED
	walker.hide()
	camera.position = Vector3(0.5, 3.0, 6.5)
	camera.look_at(Vector3(0, 1.4, -4.5))
	camera.fov = 75.0

func _input(_event: InputEvent) -> void:
	pass

func _process(_dt: float) -> void:
	pass

func _physics_process(_dt: float) -> void:
	pass
