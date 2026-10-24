extends RefCounted
## game audio implementation.
## game is the shared scene context; call other systems through its delegates.
var game

func setup(context: Node3D) -> void:
	game = context

func beep(hz: float) -> void:
	if game.muted: return
	var wave = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var data = PackedByteArray()
	data.resize(4410)
	for i in range(2205): data.encode_s16(i * 2, int(sin(TAU * hz * i / 22050.0) * 4500 * (1.0 - i / 2205.0)))
	wave.data = data
	game.audio.stream = wave
	game.audio.play()

func make_ambience() -> void:
	var wave = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_end = 88200
	var data = PackedByteArray()
	data.resize(176400)
	for i in range(88200):
		var t = i / 22050.0
		data.encode_s16(i * 2, int((sin(TAU * 48 * t) + sin(TAU * 48.5 * t) * 0.5 + sin(TAU * 72 * t) * 0.2) * 500))
	wave.data = data
	game.ambience.stream = wave
	game.ambience.play()

func play_scream() -> void:
	if game.muted: return
	var wave = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var samples = 33075
	var data = PackedByteArray()
	data.resize(samples * 2)
	var phase = 0.0
	var filtered = 0.0
	for i in range(samples):
		var t = i / 22050.0
		phase += TAU * (190 + 290 * sin(minf(t * 1.7, PI / 2)) + 40 * sin(t * 48)) / 22050.0
		filtered = lerpf(filtered, randf_range(-1, 1), 0.3)
		var vocal = sin(phase) + sin(phase * 2) * 0.45 + sin(phase * 3.02) * 0.3 + filtered * 0.6
		var envelope = minf(t * 25, 1) * pow(maxf(0, 1 - t / 1.5), 0.5)
		data.encode_s16(i * 2, int(clampf(vocal * envelope * 10000, -26000, 26000)))
	wave.data = data
	game.scream_player.stream = wave
	game.scream_player.play()
