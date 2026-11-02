extends CanvasLayer
## Survives scene replacement so both sides of a teleport share one fade.
var cover: ColorRect

func begin(tree: SceneTree, destination: String, already_black: bool = false) -> void:
	layer = 100
	tree.root.add_child(self)
	cover = ColorRect.new()
	cover.color = Color(0, 0, 0, 1 if already_black else 0)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cover)
	if tree.current_scene: tree.current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	if not already_black:
		var out := create_tween()
		out.tween_property(cover, "color:a", 1.0, 0.7)
		await out.finished
	tree.change_scene_to_file(destination)
	await tree.process_frame
	await tree.process_frame
	var scene := tree.current_scene
	if scene: scene.process_mode = Node.PROCESS_MODE_DISABLED
	var inside := create_tween()
	inside.tween_property(cover, "color:a", 0.0, 1.0)
	await inside.finished
	if is_instance_valid(scene): scene.process_mode = Node.PROCESS_MODE_INHERIT
	preload("res://scripts/city_progress.gd").transitioning = false
	queue_free()
