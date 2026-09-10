extends Node
## Autoload: economía, Salud del Océano y post-proceso de audio global.
## Prototipo Ocean VR — 2026-09-10

signal coins_changed(value: int)
signal ocean_health_changed(value: float)
signal defeat_changed(is_defeat: bool)

const MAX_HEALTH := 100.0
const BAIT_COST := 10
const FILTER_COST := 20

var coins: int = 25
var ocean_health: float = 100.0
## Cebo: más recompensa al pescar (sobrepesca más lucrativa).
var bait_level: int = 0
## Filtro: mitiga el daño de ignorar basura y bonus al limpiar.
var filter_level: int = 0

var _pitch_fx: AudioEffectPitchShift
var _is_defeat: bool = false


func _ready() -> void:
	_ensure_pitch_fx()
	_apply_audio()
	coins_changed.emit(coins)
	ocean_health_changed.emit(ocean_health)


func clean_trash() -> void:
	_add_coins(5)
	_set_health(ocean_health + 8.0 + float(filter_level) * 2.0)


func ignore_trash() -> void:
	var dmg := 12.0 / (1.0 + float(filter_level))
	_set_health(ocean_health - dmg)


func catch_fish(rarity: int = 0, size_factor: float = 1.0) -> void:
	var multiplier: float = [1.0, 2.0, 4.0, 8.0][clampi(rarity, 0, 3)]
	var size := clampf(size_factor, 0.75, 1.5)
	_add_coins(maxi(1, roundi((3 + bait_level * 2) * multiplier * size)))
	_set_health(ocean_health - 6.0 * multiplier * size)


func let_fish_go() -> void:
	_set_health(ocean_health + 2.0)


func buy_bait() -> bool:
	if coins < BAIT_COST:
		return false
	coins -= BAIT_COST
	bait_level += 1
	coins_changed.emit(coins)
	return true


func buy_filter() -> bool:
	if coins < FILTER_COST:
		return false
	coins -= FILTER_COST
	filter_level += 1
	coins_changed.emit(coins)
	return true


func _add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


func _set_health(value: float) -> void:
	ocean_health = clampf(value, 0.0, MAX_HEALTH)
	ocean_health_changed.emit(ocean_health)
	var defeat := ocean_health <= 0.0
	if defeat != _is_defeat:
		_is_defeat = defeat
		defeat_changed.emit(_is_defeat)
	_apply_audio()


func _ensure_pitch_fx() -> void:
	var bus := AudioServer.get_bus_index("Master")
	for i in AudioServer.get_bus_effect_count(bus):
		var fx := AudioServer.get_bus_effect(bus, i)
		if fx is AudioEffectPitchShift:
			_pitch_fx = fx
			return
	_pitch_fx = AudioEffectPitchShift.new()
	_pitch_fx.oversampling = 4
	AudioServer.add_bus_effect(bus, _pitch_fx)


func _apply_audio() -> void:
	var t := ocean_health / MAX_HEALTH
	var bus := AudioServer.get_bus_index("Master")
	var linear := lerpf(0.12, 1.0, t)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(linear, 0.001)))
	if _pitch_fx:
		_pitch_fx.pitch_scale = lerpf(0.55, 1.0, t)
