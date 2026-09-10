extends Node
signal coins_changed(value: int)
signal ocean_health_changed(value: float)
signal defeat_changed(is_defeat: bool)
signal level_changed(value: int)
signal depth_changed(value: int)
signal fever_changed(active: bool)
signal cleaner_bought(quality: int)
signal sound_requested(event: String)
signal bubbles_requested(at: Vector3)
signal coin_requested(at: Vector3, amount: int)
const MAX_HEALTH := 100.0
const BAIT_COST := 10
const FILTER_COST := 20
var coins := 25
var ocean_health := 100.0
var bait_level := 0
var filter_level := 0
var level := 1
var depth := 0
var experience := 0
var fever_left := 0.0
var active_cleaners := 0
var defeated := false
var stun_left := 0.0
var slow_time_left := 0.0
var _pitch_fx: AudioEffectPitchShift

func _ready() -> void:
	var bus := AudioServer.get_bus_index("Master")
	for i in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) is AudioEffectPitchShift:
			_pitch_fx = AudioServer.get_bus_effect(bus, i)
	if not _pitch_fx:
		_pitch_fx = AudioEffectPitchShift.new()
		AudioServer.add_bus_effect(bus, _pitch_fx)
	_apply_audio()

func _process(delta: float) -> void:
	stun_left = maxf(0, stun_left - delta)
	slow_time_left = maxf(0, slow_time_left - delta)
	if fever_left > 0 and not defeated:
		fever_left = maxf(0, fever_left - delta)
		if fever_left == 0:
			fever_changed.emit(false)

func difficulty() -> float:
	return minf(2.3, 1.0 + (level - 1) * 0.05 + depth * 0.12)

func cleaner_quality() -> int:
	# The Filtrobot evolves at levels 5 and 10; its maximum quality is level 3.
	return clampi(1 + level / 5, 1, 3)

func progress() -> void:
	if defeated: return
	experience += 1
	if experience >= 6:
		experience = 0
		level += 1
		level_changed.emit(level)
		sound_requested.emit("level")
		if can_descend(): descend()

func start_fever() -> void:
	if defeated: return
	fever_left = 10.0
	fever_changed.emit(true)
	sound_requested.emit("fever")

func start_slow_time() -> void:
	if defeated: return
	slow_time_left = 5.0

func world_time_scale() -> float:
	return 0.38 if slow_time_left > 0 else 1.0

func can_descend() -> bool:
	return not defeated and level >= (depth + 1) * 5

func descend() -> bool:
	if not can_descend(): return false
	depth += 1
	depth_changed.emit(depth)
	sound_requested.emit("depth")
	return true

func clean_trash(manual: bool = true) -> void:
	if defeated: return
	if manual:
		_add_coins(5)
		progress()
		sound_requested.emit("trash")
	_set_health(ocean_health + (7.0 if manual else 4.0) + mini(filter_level, 3))

func ignore_trash() -> void:
	if not defeated:
		_set_health(ocean_health - (8.0 + depth * 2.0) * difficulty() / (1.0 + filter_level * 0.4))

func fish_stats(rarity: int, size_factor: float, aura: int = 0) -> Dictionary:
	var mult: float = [1.0, 1.5, 2.2, 3.5][clampi(rarity, 0, 3)]
	return {"reward": maxi(1, roundi((3 + bait_level) * mult * size_factor * (1.0 + aura * 0.6) * (2.0 if fever_left > 0 else 1.0))), "damage": 0.0 if fever_left > 0 else 1.2 * mult * size_factor}

func catch_fish(rarity: int = 0, size_factor: float = 1.0, aura: int = 0) -> void:
	if defeated: return
	var stats := fish_stats(rarity, size_factor, aura)
	_add_coins(stats.reward)
	_set_health(ocean_health - stats.damage)
	if not defeated: progress()
	sound_requested.emit("fish")

func let_fish_go() -> void:
	if not defeated: _set_health(ocean_health + 0.5)

func buy_bait() -> bool:
	if defeated or coins < BAIT_COST: return false
	coins -= BAIT_COST
	bait_level += 1
	coins_changed.emit(coins)
	return true

func filter_cost() -> int:
	return FILTER_COST + filter_level * 10 + depth * 10

func buy_filter() -> bool:
	if defeated or coins < filter_cost() or active_cleaners >= 10: return false
	coins -= filter_cost()
	filter_level += 1
	active_cleaners += 1
	cleaner_bought.emit(cleaner_quality())
	coins_changed.emit(coins)
	return true

func _add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func _set_health(value: float) -> void:
	if defeated: return
	ocean_health = clampf(value, 0, MAX_HEALTH)
	ocean_health_changed.emit(ocean_health)
	_apply_audio()
	if ocean_health <= 0:
		defeated = true
		fever_left = 0
		fever_changed.emit(false)
		defeat_changed.emit(true)

func _apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(lerpf(0.2, 1, ocean_health / 100.0)))
	if _pitch_fx: _pitch_fx.pitch_scale = lerpf(0.7, 1, ocean_health / 100.0)

func restart() -> void:
	coins = 25
	ocean_health = 100
	bait_level = 0
	filter_level = 0
	level = 1
	depth = 0
	experience = 0
	fever_left = 0
	active_cleaners = 0
	defeated = false
	stun_left = 0.0
	slow_time_left = 0.0
	_apply_audio()
	get_tree().reload_current_scene()
