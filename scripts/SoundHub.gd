extends Node
@export var button_touch: AudioStream
@export var button_success: AudioStream
@export var button_error: AudioStream
@export var explosion: AudioStream
@export var alarm: AudioStream
var _sounds: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _ui_voices: Array[AudioStreamPlayer] = []
var _spatial: Array[AudioStreamPlayer3D] = []
var _alarm_voice: AudioStreamPlayer3D
var _cooldowns: Dictionary = {}

func _ready() -> void:
	add_to_group("sound_hub")
	var folder := "res://assets/audio/arcade/"
	if not button_touch: button_touch = load(folder + "click_001.ogg")
	if not button_success: button_success = load(folder + "confirmation_002.ogg")
	if not button_error: button_error = load(folder + "error_003.ogg")
	if not explosion: explosion = load(folder + "glitch_001.ogg")
	if not alarm: alarm = preload("res://scripts/ArcadeAudio.gd").make_tone(true)
	var files := {"puffer": "bong_001", "snail": "scratch_001", "snail_throw": "drop_002", "death": "back_001", "fever": "maximize_001", "lantern_out": "minimize_001", "level": "confirmation_002", "fish": "pluck_001", "trash": "glass_002", "depth": "minimize_001", "robot": "drop_002"}
	for event in files: _sounds[event] = load(folder + files[event] + ".ogg")
	for index in 8:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_voices.append(voice)
	for index in 2:
		var voice := AudioStreamPlayer.new()
		voice.bus = "UI"
		add_child(voice)
		_ui_voices.append(voice)
	for index in 4:
		var voice := AudioStreamPlayer3D.new()
		voice.bus = "SFX"
		voice.unit_size = 2.0
		voice.max_distance = 10.0
		voice.panning_strength = 0.65
		add_child(voice)
		_spatial.append(voice)
	_alarm_voice = AudioStreamPlayer3D.new()
	_alarm_voice.bus = "Alarm"
	_alarm_voice.stream = alarm
	_alarm_voice.volume_db = -12
	_alarm_voice.position = Vector3(0, 0.85, -1.45)
	_alarm_voice.unit_size = 3.0
	_alarm_voice.panning_strength = 0.3
	add_child(_alarm_voice)
	GameManager.sound_requested.connect(play_event)
	GameManager.sound_at_requested.connect(play_at)

func _process(delta: float) -> void:
	for event in _cooldowns.keys(): _cooldowns[event] = maxf(0.0, float(_cooldowns[event]) - delta)
	if GameManager.is_run_over() or GameManager.ocean_health >= 30:
		_alarm_voice.stop()
	else:
		play_event("alarm")

func _stream(event: String) -> AudioStream:
	match event:
		"touch": return button_touch
		"success": return button_success
		"error": return button_error
		"explosion": return explosion
	return _sounds.get(event)

func _allow(event: String, interval: float) -> bool:
	if float(_cooldowns.get(event, 0.0)) > 0: return false
	_cooldowns[event] = interval
	return true

func play_event(event: String) -> void:
	if event == "alarm":
		if GameManager.is_run_over() or GameManager.ocean_health >= 30: return
		if not _alarm_voice.playing and _allow(event, 1.1): _alarm_voice.play()
		return
	var stream := _stream(event)
	if not stream or not _allow(event, 0.08 if event in ["fish", "trash"] else 0.12): return
	var ui := event in ["touch", "success", "error", "death", "level"]
	var pool := _ui_voices if ui else _voices
	var voice: AudioStreamPlayer
	for candidate in pool:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null and ui and event != "touch": voice = pool[0]
	if voice == null: return
	voice.stream = stream
	voice.volume_db = -16 if ui else -20
	voice.pitch_scale = randf_range(0.94, 1.06) if event in ["fish", "trash", "touch"] else 1.0
	voice.play()

func play_at(event: String, at: Vector3) -> void:
	var stream := _stream(event)
	if not stream or not _allow("spatial_" + event, 0.25 if event == "robot" else 0.12): return
	var voice: AudioStreamPlayer3D
	for candidate in _spatial:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null and event == "explosion": voice = _spatial[0]
	if voice == null: return
	voice.global_position = at
	voice.stream = stream
	voice.volume_db = -26 if event == "robot" else -17
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()
