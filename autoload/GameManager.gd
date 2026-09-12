extends Node
signal coins_changed(value: int)
signal ocean_health_changed(value: float)
signal defeat_changed(is_defeat: bool)
signal level_changed(value: int)
signal depth_changed(value: int)
signal fever_changed(active: bool)
signal cleaner_bought(quality: int)
signal sound_requested(event: String)
signal sound_at_requested(event: String, at: Vector3)
signal bubbles_requested(at: Vector3)
signal coin_requested(at: Vector3, amount: int)
signal expedition_ended(success: bool)
const EXPEDITION_SECONDS := 300.0
enum PlayMode { EDUCATIONAL, ARCADE }
var play_mode: PlayMode = PlayMode.EDUCATIONAL
var mode_selected := false

func select_mode(value: PlayMode) -> void:
	play_mode = value
	mode_selected = true
const WASTE_GOAL := 15
const HEALTH_GOAL := 70.0
const CONSERVATION_SECONDS := 30.0
var expedition_left := EXPEDITION_SECONDS
var expedition_finished := false
var expedition_success := false
var conservation_time := 0.0
var robots_deployed := 0
const MAX_HEALTH := 100.0
const BAIT_COST := 10
const FILTER_COST := 20
var coins := 25
var ocean_health := 100.0
var bait_level := 0
var net_level := 0
const MAX_NET_LEVEL := 5

func net_cost() -> int:
	return 15 + net_level * 15

func buy_net() -> bool:
	if is_run_over() or net_level >= MAX_NET_LEVEL or coins < net_cost(): return false
	coins -= net_cost()
	net_level += 1
	coins_changed.emit(coins)
	return true

func capture_duration(base: float, is_fish: bool) -> float:
	return maxf(0.10, base / (1.0 + net_level * 0.45)) if is_fish else base
var filter_level := 0
var level := 1
var depth := 0
var experience := 0
var fever_left := 0.0
var active_cleaners := 0
var defeated := false
var stun_left := 0.0
var slow_time_left := 0.0
var waste_removed := 0
var fish_caught := 0

func _ready() -> void:
	_apply_audio()

func _process(delta: float) -> void:
	if is_run_over(): return
	advance_expedition(delta)
	stun_left = maxf(0, stun_left - delta)
	slow_time_left = maxf(0, slow_time_left - delta)
	if fever_left > 0 and not defeated:
		fever_left = maxf(0, fever_left - delta)
		if fever_left == 0:
			fever_changed.emit(false)

func difficulty() -> float:
	return minf(2.3, 1.0 + (level - 1) * 0.05 + depth * 0.12)

func is_run_over() -> bool:
	return not mode_selected or defeated or expedition_finished

func advance_expedition(delta: float) -> void:
	if is_run_over() or play_mode == PlayMode.ARCADE: return
	var elapsed := minf(delta, expedition_left)
	expedition_left = maxf(0.0, expedition_left - elapsed)
	if waste_removed >= WASTE_GOAL and robots_deployed > 0 and ocean_health >= HEALTH_GOAL:
		conservation_time = minf(CONSERVATION_SECONDS, conservation_time + elapsed)
	else:
		conservation_time = 0.0
	if conservation_time >= CONSERVATION_SECONDS or expedition_left <= 0.0:
		expedition_finished = true
		expedition_success = conservation_time >= CONSERVATION_SECONDS
		fever_left = 0.0
		stun_left = 0.0
		slow_time_left = 0.0
		fever_changed.emit(false)
		expedition_ended.emit(expedition_success)

func mission_text() -> String:
	if play_mode == PlayMode.ARCADE: return "ARCADE · SIN LÍMITE DE TIEMPO · PROTEGE EL OCÉANO"
	if waste_removed < WASTE_GOAL:
		return "1/3 · RETIRA RESIDUOS  %d/%d" % [waste_removed, WASTE_GOAL]
	if robots_deployed == 0:
		return "2/3 · COMPRA UN FILTROBOT EN LA TIENDA"
	return "3/3 · CONSERVA SALUD ≥70%%  %d/30 s" % int(conservation_time)

func cleaner_quality() -> int:
	# The Filtrobot evolves at levels 5 and 10; its maximum quality is level 3.
	return clampi(1 + level / 5, 1, 3)

func progress() -> void:
	if is_run_over(): return
	experience += 1
	if experience >= 6:
		experience = 0
		level += 1
		level_changed.emit(level)
		sound_requested.emit("level")
		if can_descend(): descend()

func start_fever() -> void:
	if is_run_over(): return
	fever_left = 10.0
	fever_changed.emit(true)
	sound_requested.emit("fever")

func start_slow_time() -> void:
	if is_run_over(): return
	slow_time_left = 5.0

func world_time_scale() -> float:
	return 0.38 if slow_time_left > 0 else 1.0

func can_descend() -> bool:
	return not is_run_over() and level >= (depth + 1) * 5

func descend() -> bool:
	if not can_descend(): return false
	depth += 1
	depth_changed.emit(depth)
	sound_requested.emit("depth")
	return true

func clean_trash(manual: bool = true) -> void:
	if is_run_over(): return
	waste_removed += 1
	progress()
	if manual:
		_add_coins(5)
		sound_requested.emit("trash")
	_set_health(ocean_health + (7.0 if manual else 4.0) + mini(filter_level, 3))

func ignore_trash() -> void:
	if not is_run_over():
		_set_health(ocean_health - (8.0 + depth * 2.0) * difficulty() / (1.0 + filter_level * 0.4))

func fish_stats(rarity: int, size_factor: float, aura: int = 0) -> Dictionary:
	var mult: float = [1.0, 1.5, 2.2, 3.5][clampi(rarity, 0, 3)]
	return {"reward": maxi(1, roundi((3 + bait_level) * mult * size_factor * (1.0 + aura * 0.6) * (2.0 if fever_left > 0 else 1.0))), "damage": 0.0 if fever_left > 0 else 1.2 * mult * size_factor}

func catch_fish(rarity: int = 0, size_factor: float = 1.0, aura: int = 0) -> void:
	if is_run_over(): return
	fish_caught += 1
	var stats := fish_stats(rarity, size_factor, aura)
	_add_coins(stats.reward)
	_set_health(ocean_health - stats.damage)
	if not is_run_over(): progress()
	sound_requested.emit("fish")

func let_fish_go() -> void:
	if not is_run_over(): _set_health(ocean_health + 0.5)

func buy_bait() -> bool:
	if is_run_over() or coins < BAIT_COST: return false
	coins -= BAIT_COST
	bait_level += 1
	coins_changed.emit(coins)
	return true

func filter_cost() -> int:
	return FILTER_COST + filter_level * 10 + depth * 10

func buy_filter() -> bool:
	if is_run_over() or coins < filter_cost() or active_cleaners >= 10: return false
	coins -= filter_cost()
	filter_level += 1
	active_cleaners += 1
	robots_deployed += 1
	cleaner_bought.emit(cleaner_quality())
	coins_changed.emit(coins)
	return true

func _add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func _set_health(value: float) -> void:
	if is_run_over(): return
	ocean_health = clampf(value, 0, MAX_HEALTH)
	ocean_health_changed.emit(ocean_health)
	_apply_audio()
	if ocean_health <= 0:
		defeated = true
		fever_left = 0
		fever_changed.emit(false)
		defeat_changed.emit(true)

func _apply_audio() -> void:
	# Gameplay attenuation never muffles UI or emergency cues, or overwrites Master.
	var bus := AudioServer.get_bus_index("World")
	if bus >= 0: AudioServer.set_bus_volume_db(bus, lerpf(-9.0, 0.0, ocean_health / MAX_HEALTH))

func restart() -> void:
	expedition_left = EXPEDITION_SECONDS
	expedition_finished = false
	expedition_success = false
	conservation_time = 0.0
	robots_deployed = 0
	waste_removed = 0
	fish_caught = 0
	coins = 25
	ocean_health = 100
	bait_level = 0
	net_level = 0
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
