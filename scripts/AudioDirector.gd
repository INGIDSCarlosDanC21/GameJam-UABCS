extends Node
@export var expedition_music: AudioStreamOggVorbis = preload("res://assets/audio/arcade/expedition.ogg")
@export var fever_music: AudioStreamOggVorbis = preload("res://assets/audio/arcade/fever.ogg")
@export_range(-40.0, 0.0) var music_volume_db := -7.0
@export_range(-50.0, 0.0) var ambience_volume_db := -22.0
var _normal: AudioStreamPlayer
var _fever: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _filter: AudioEffectLowPassFilter
var _blend := 0.0
var _duck_left := 0.0
var _entrance := 0.0

func _ready() -> void:
	name = "AudioDirector"
	_normal = _music(expedition_music)
	_fever = _music(fever_music)
	_ambience = AudioStreamPlayer.new()
	_ambience.stream = preload("res://scripts/ArcadeAudio.gd").make_tone(false)
	_ambience.bus = "Ambience"
	_ambience.volume_db = -60
	add_child(_ambience)
	_ambience.play()
	var bus := AudioServer.get_bus_index("Music")
	_filter = AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	GameManager.sound_requested.connect(func(event: String):
		if event in ["alarm", "depth", "death", "success", "level"]: _duck_left = 0.7)

func _music(source: AudioStreamOggVorbis) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := source.duplicate() as AudioStreamOggVorbis
	stream.loop = true
	player.stream = stream
	player.bus = "Music"
	player.volume_db = -60
	add_child(player)
	return player

func _process(delta: float) -> void:
	var over := GameManager.is_run_over()
	var fever := GameManager.fever_left > 0 and not over
	_blend = move_toward(_blend, 1.0 if fever else 0.0, delta * 2.0)
	_entrance = move_toward(_entrance, 0.0 if over else 1.0, delta * 0.8)
	_duck_left = maxf(0.0, _duck_left - delta)
	var muffled := GameManager.stun_left > 0
	var health := GameManager.ocean_health / GameManager.MAX_HEALTH
	var gain := db_to_linear(music_volume_db - (3.0 if _duck_left > 0 else 0.0) - (10.0 if muffled else 0.0)) * _entrance
	_mix_player(_normal, (1.0 - _blend) * gain)
	_mix_player(_fever, _blend * gain)
	var pitch := 0.78 if muffled else lerpf(0.90, 1.0, health)
	_normal.pitch_scale = lerpf(_normal.pitch_scale, pitch, 1.0 - exp(-delta * 2.0))
	_ambience.pitch_scale = lerpf(0.8, 1.0, health)
	_ambience.volume_db = lerpf(_ambience.volume_db, ambience_volume_db if not over else -60.0, 1.0 - exp(-delta * 2.0))
	if _filter:
		var cutoff := 1200.0 if muffled else maxf(2200.0, 12000.0 * health / (1.0 + GameManager.depth * 0.16))
		_filter.cutoff_hz = lerpf(_filter.cutoff_hz, cutoff, 1.0 - exp(-delta * 2.0))

func _mix_player(player: AudioStreamPlayer, gain: float) -> void:
	player.volume_db = linear_to_db(maxf(0.0001, gain))
	if gain > 0.0001 and not player.playing: player.play()
	elif gain <= 0.0001 and player.playing: player.stop()
