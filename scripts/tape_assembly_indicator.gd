extends Control
## Draws the four repaired tape fragments in the gameplay HUD.

const Progress = preload("res://scripts/city_progress.gd")
const PIECE_COUNT := 4
const JOIN_SECONDS := 1.15
const FRAGMENTS := [
	[Vector2(27, 39), Vector2(107, 39), Vector2(107, 67), Vector2(116, 73), Vector2(108, 80), Vector2(27, 80)],
	[Vector2(107, 39), Vector2(197, 39), Vector2(197, 80), Vector2(108, 80), Vector2(116, 73), Vector2(107, 67)],
	[Vector2(27, 80), Vector2(108, 80), Vector2(113, 88), Vector2(105, 94), Vector2(109, 129), Vector2(27, 129)],
	[Vector2(108, 80), Vector2(197, 80), Vector2(197, 129), Vector2(109, 129), Vector2(105, 94), Vector2(113, 88)],
]
const ENTRY_OFFSETS := [Vector2(-36, -30), Vector2(38, -30), Vector2(-36, 30), Vector2(38, 30)]
const BLUE := Color("37d8ff")
const PINK := Color("ff4cac")
const SHELL := Color("101326")

static var last_assembled_count := 0

var shown_count := -1
var joining_piece := -1
var join_time := 0.0
var title_label: Label
var count_label: Label

func _ready() -> void:
	name = "TapeAssembly"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label = Label.new()
	title_label.position = Vector2(16, 8)
	title_label.size = Vector2(150, 24)
	title_label.text = "REPAIR THE TAPE"
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color("dcf9ff"))
	add_child(title_label)
	count_label = Label.new()
	count_label.position = Vector2(169, 8)
	count_label.size = Vector2(42, 24)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 15)
	count_label.add_theme_color_override("font_color", PINK)
	add_child(count_label)
	visible = Progress.active

func _process(delta: float) -> void:
	visible = Progress.active
	if not visible:
		return
	_sync_count()
	if joining_piece >= 0:
		join_time = minf(JOIN_SECONDS, join_time + delta)
		if join_time >= JOIN_SECONDS:
			last_assembled_count = maxi(last_assembled_count, shown_count)
			joining_piece = -1
		queue_redraw()

func _sync_count() -> void:
	var count := clampi(Progress.piece_index, 0, PIECE_COUNT)
	if count < last_assembled_count:
		last_assembled_count = count
	if count == shown_count:
		return
	shown_count = count
	count_label.text = "%d / %d" % [count, PIECE_COUNT]
	title_label.text = "TAPE RESTORED" if count == PIECE_COUNT else "REPAIR THE TAPE"
	var scene := get_tree().current_scene
	var in_city := scene != null and scene.scene_file_path == "res://scenes/neon_city.tscn"
	joining_piece = count - 1 if in_city and not Progress.ejected and count > last_assembled_count else -1
	join_time = 0.0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 224, 148), Color(0.025, 0.038, 0.095, 0.88))
	draw_rect(Rect2(0, 0, 224, 148), Color("4376a6"), false, 2.0)
	draw_line(Vector2(15, 32), Vector2(209, 32), Color("275372"), 1.0)
	for index in range(PIECE_COUNT):
		var polygon := PackedVector2Array(FRAGMENTS[index])
		var outline := PackedVector2Array(FRAGMENTS[index] + [FRAGMENTS[index][0]])
		draw_colored_polygon(polygon, Color(0.12, 0.18, 0.3, 0.55))
		draw_polyline(outline, Color(0.25, 0.4, 0.54, 0.7), 1.5)
		if index >= shown_count:
			continue
		var offset := Vector2.ZERO
		if index == joining_piece:
			var arrival := smoothstep(0.0, 1.0, join_time / JOIN_SECONDS)
			offset = ENTRY_OFFSETS[index] * (1.0 - arrival)
		draw_set_transform(offset)
		draw_colored_polygon(polygon, SHELL)
		draw_polyline(outline, BLUE if index % 2 == 0 else PINK, 2.5)
		_draw_fragment_detail(index)
		draw_set_transform(Vector2.ZERO)
	if shown_count == PIECE_COUNT:
		draw_line(Vector2(28, 133), Vector2(196, 133), BLUE, 2.0)

func _draw_fragment_detail(index: int) -> void:
	if index < 2:
		var center := Vector2(71, 65) if index == 0 else Vector2(153, 65)
		var accent := BLUE if index == 0 else PINK
		draw_circle(center, 16.0, Color("293954"))
		draw_arc(center, 14.0, 0.0, TAU, 32, accent, 3.0)
		draw_circle(center, 4.0, Color("b5e8f4"))
		draw_line(Vector2(34 if index == 0 else 160, 46), Vector2(59 if index == 0 else 189, 46), accent, 2.0)
	else:
		var accent := BLUE if index == 2 else PINK
		var left := 39.0 if index == 2 else 119.0
		draw_rect(Rect2(left, 100, 62, 17), Color("819cb1"))
		draw_line(Vector2(left + 5, 108), Vector2(left + 57, 108), accent, 2.0)
		draw_rect(Rect2(left + 5, 122, 52, 3), accent)
