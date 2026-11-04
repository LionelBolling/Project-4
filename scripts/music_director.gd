extends Node
## One music player survives scene changes, so a track keeps its position when reused.

const TRACKS := [
	preload("res://audio/track1.ogg"),
	preload("res://audio/track2.ogg"),
	preload("res://audio/track3.ogg"),
]

var player: AudioStreamPlayer
var current_track := 0

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "Music"
	player.volume_db = -8.0
	add_child(player)
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_sync_current_scene")

func _sync_current_scene() -> void:
	_on_scene_changed()

func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	match scene.scene_file_path:
		"res://scenes/level_0.tscn":
			play_track(3 if scene.get("race_state") == "WORLD_REVEAL" else 1)
		"res://scenes/level_1.tscn", "res://scenes/Level2.tscn", "res://scenes/level_3_beta.tscn":
			play_track(1)
		"res://scenes/neon_city.tscn":
			play_track(2 if scene.get("phase") == "EXPLORE" else 3)
		"res://scenes/boss_cutscene_start.tscn", "res://scenes/bossfight.tscn", "res://scenes/final_ending.tscn":
			play_track(3)
		"res://scenes/bedroom_intro.tscn", "res://scenes/rewind.tscn":
			play_track(0) # The bedroom boombox starts the music.
		_:
			play_track(0)

func play_boombox() -> void:
	play_track(3)

func play_track(number: int) -> void:
	if number == current_track and (number == 0 or player.playing):
		return
	current_track = number
	player.stop()
	if number == 0:
		player.stream = null
		return
	var stream := TRACKS[number - 1] as AudioStreamOggVorbis
	stream.loop = true
	player.stream = stream
	player.play()
