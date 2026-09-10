extends Node
@export var button_touch: AudioStream
@export var button_success: AudioStream
@export var button_error: AudioStream
@export var explosion: AudioStream
@export var alarm: AudioStream
var _sounds: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _beep: AudioStreamWAV
var _alarm_voice: AudioStreamPlayer
func _ready() -> void:
	add_to_group("sound_hub")
	if not button_touch: button_touch = load("res://assets/audio/effects/laser1.mp3")
	if not button_success: button_success = load("res://assets/audio/effects/burbuja pop.mp3")
	if not button_error: button_error = load("res://assets/audio/effects/laser2.mp3")
	if not alarm: alarm = preload("res://assets/audio/effects/FNAF 3 ventilation error.mp3")
	_alarm_voice = AudioStreamPlayer.new()
	add_child(_alarm_voice)
	_alarm_voice.volume_db = -4
	for pair in [["puffer", "se infla pez globo"], ["snail", "Gary the Snail Moving Sound Effect"], ["snail_throw", "lancer-splat"], ["death", "sonido de muerte o perdiste"], ["fever", "foca talvez"], ["lantern_out", "pez linterna muere"]]:
		_sounds[pair[0]] = load("res://assets/audio/effects/" + pair[1] + ".mp3")
	if not explosion: explosion = preload("res://assets/audio/effects/deltarune-explosion.mp3")
	for pair in [["level", "subir lv"], ["fish", "quitar pez"], ["trash", "quitar basura"], ["depth", "bajar mas profundo"]]:
		_sounds[pair[0]] = load("res://assets/audio/effects/" + pair[1] + ".mp3")
	_beep = AudioStreamWAV.new()
	_beep.format = AudioStreamWAV.FORMAT_16_BITS
	_beep.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(4410 * 2)
	for i in range(4410):
		var wave := sin(TAU * 740.0 * i / 22050.0) * sin(PI * float(i) / 4410.0) * 0.25
		data.encode_s16(i * 2, int(wave * 32767))
	_beep.data = data
	for i in range(6):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_voices.append(player)
	GameManager.sound_requested.connect(play_event)
func _process(_delta: float) -> void:
	if GameManager.defeated or GameManager.ocean_health >= 30: _alarm_voice.stop()

func play_event(event: String) -> void:
	if event == "alarm":
		if not _alarm_voice.playing:
			_alarm_voice.stream = alarm
			_alarm_voice.play()
		return
	var stream: AudioStream = _sounds.get(event)
	match event:
		"touch": stream = button_touch
		"success": stream = button_success
		"error": stream = button_error
		"explosion": stream = explosion
		"alarm": stream = alarm
	if not stream: stream = _beep
	for player in _voices:
		if not player.playing:
			player.stream = stream
			player.volume_db = -8 if event == "alarm" else -16
			player.play()
			break