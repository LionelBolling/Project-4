extends Node3D
## Shared scene state and stable delegates. Edit implementations in scripts/systems/.

const FINISH = 530.0
const KEYS = [KEY_Q, KEY_E, KEY_R, KEY_F]
const MINT = Color("65f5db")
const VIOLET = Color("ad70fa")
var state = "title"
var player: CharacterBody3D
var shadow: Node3D
var camera: Camera3D
var hud: Label
var prompt: Label
var banner: Label
var overlay: PanelContainer
var overlay_text: Label
var platforms: Array[Dictionary] = []
var elapsed = 0.0
var ghost_distance = 0.0
var boost = 0.0
var slow = 0.0
var qte_time = 0.0
var qte_key = KEY_Q
var next_qte = 7.0
var coyote = 0.0
var jump_buffer = 0.0
var clock = 0.0
var feedback_time = 0.0
var muted = false
var audio: AudioStreamPlayer
var won = false
var player_visual: Node3D
var shadow_visual: Node3D


## First-person bedroom, tape encounter and race introduction.
var yaw = 0.0
var pitch = 0.0
var phase_time = 0.0
var resume_state = ""
var bedroom: Node3D
var tape: Node3D
var arms: Node3D
var lids_top: ColorRect
var lids_bottom: ColorRect
var veil: ColorRect
var blink_count = 0
var scare_played = false
var scream_player: AudioStreamPlayer
var ambience: AudioStreamPlayer
var view_bob = 0.0
var help_label: Label
var crosshair: Label
var objective = ""
var interaction_text = ""
var tape_revealed = false


var environment = preload("res://scripts/systems/environment.gd").new()
var character_models = preload("res://scripts/systems/character_models.gd").new()
var opening_sequence = preload("res://scripts/systems/opening_sequence.gd").new()
var player_movement = preload("res://scripts/systems/player_movement.gd").new()
var ghost_runner = preload("res://scripts/systems/ghost_runner.gd").new()
var qte = preload("res://scripts/systems/qte.gd").new()
var game_audio = preload("res://scripts/systems/game_audio.gd").new()
var game_ui = preload("res://scripts/systems/game_ui.gd").new()
var game_flow = preload("res://scripts/systems/game_flow.gd").new()

func _init() -> void:
	environment.setup(self)
	character_models.setup(self)
	opening_sequence.setup(self)
	player_movement.setup(self)
	ghost_runner.setup(self)
	qte.setup(self)
	game_audio.setup(self)
	game_ui.setup(self)
	game_flow.setup(self)

func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	return environment.material(color, glow)

func box(parent: Node, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	return environment.box(parent, pos, size, mat)

func caption(parent: Node3D, text: String, pos: Vector3, color: Color, size: int = 38) -> Label3D:
	return environment.caption(parent, text, pos, color, size)

func build_world() -> void:
	environment.build_world()

func solid(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	return environment.solid(parent, pos, size, color)

func build_arrival() -> void:
	environment.build_arrival()

func tile_at(distance: float) -> int:
	return environment.tile_at(distance)

func capsule(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	return character_models.capsule(parent, a, b, radius, mat)

func orb(parent: Node3D, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	return character_models.orb(parent, pos, scale_value, mat)

func make_runner(parent: Node3D, _color: Color) -> Node3D:
	return character_models.make_runner(parent, _color)

func make_hand(parent: Node3D, p: Vector3, side: int, skin: Material) -> void:
	character_models.make_hand(parent, p, side, skin)

func make_view_arms() -> Node3D:
	return character_models.make_view_arms()

func build_bedroom() -> void:
	opening_sequence.build_bedroom()

func begin_sleep() -> void:
	opening_sequence.begin_sleep()

func set_lids(amount: float) -> void:
	opening_sequence.set_lids(amount)

func wake_up() -> void:
	opening_sequence.wake_up()

func trigger_tape() -> void:
	opening_sequence.trigger_tape()

func simulate(dt: float) -> void:
	player_movement.simulate(dt)

func update_camera(dt: float) -> void:
	player_movement.update_camera(dt)

func _unhandled_input(event: InputEvent) -> void:
	player_movement._unhandled_input(event)

func _unhandled_key_input(event: InputEvent) -> void:
	player_movement._unhandled_key_input(event)

func update_ghost(dt: float) -> void:
	ghost_runner.update_ghost(dt)

func resolve_qte(success: bool) -> void:
	qte.resolve_qte(success)

func apply_qte_result(success: bool) -> void:
	qte.apply_qte_result(success)

func beep(hz: float) -> void:
	game_audio.beep(hz)

func make_ambience() -> void:
	game_audio.make_ambience()

func play_scream() -> void:
	game_audio.play_scream()

func build_ui() -> void:
	game_ui.build_ui()

func show_overlay(title: String, text: String) -> void:
	game_ui.show_overlay(title, text)

func build_story_ui() -> void:
	game_ui.build_story_ui()

func update_ui() -> void:
	game_ui.update_ui()

func finish(victory: bool, message: String) -> void:
	game_ui.finish(victory, message)

func show_result(victory: bool, message: String) -> void:
	game_ui.show_result(victory, message)

func _ready() -> void:
	game_flow._ready()

func initialize_game() -> void:
	game_flow.initialize_game()

func reset_race() -> void:
	game_flow.reset_race()

func start_real_race(ghost_start: float = 2.0) -> void:
	game_flow.start_real_race(ghost_start)

func _physics_process(dt: float) -> void:
	game_flow._physics_process(dt)
