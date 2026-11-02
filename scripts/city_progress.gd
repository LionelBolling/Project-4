extends RefCounted
## Session progression shared by the city and existing race scenes.
const HUB := "res://scenes/neon_city.tscn"
const LEVELS := ["res://scenes/level_0.tscn", "res://scenes/level_1.tscn", "res://scenes/Level2.tscn", "res://scenes/level_3_beta.tscn", "res://scenes/bossfight.tscn"]
const MAX_HEALTH := 100
const FAILURE_DAMAGE := 25
static var active := false
static var arrived := false
static var piece_index := 0
static var health := MAX_HEALTH
static var ejected := false
static var transitioning := false

static func reset() -> void:
	active = false
	arrived = false
	piece_index = 0
	health = MAX_HEALTH
	ejected = false
	transitioning = false

static func travel(tree: SceneTree, destination: String, already_black: bool = false) -> void:
	if transitioning: return
	transitioning = true
	# Load at runtime to avoid a cyclic preload between session and transition.
	var overlay = load("res://scripts/city_transition.gd").new()
	overlay.begin(tree, destination, already_black)

static func fail_race(tree: SceneTree) -> bool:
	if not active: return false
	if transitioning: return true
	health = maxi(0, health - FAILURE_DAMAGE)
	ejected = true
	Engine.time_scale = 1.0
	travel(tree, HUB)
	return true

static func complete_race(tree: SceneTree, fallback: String) -> void:
	if active:
		if transitioning: return
		piece_index = mini(piece_index + 1, LEVELS.size())
		travel(tree, HUB)
	else:
		tree.change_scene_to_file(fallback)
