extends Node3D
const ENTRY_DEPTHS: Array[float] = [-2.5, -3.6, -4.8]
const ENTRY_START_DEPTHS: Array[float] = [-17.0, -15.0, -13.0]
@export var entity_scene: PackedScene
var _timer := 0.0
var _seal_timer := 12.0
var _trash_timer := 1.0
func _ready() -> void:
	GameManager.fever_changed.connect(func(active: bool):
		if active: _timer = 0.0
	)
func _process(delta: float) -> void:
	if GameManager.is_run_over(): return
	delta *= GameManager.world_time_scale()
	_timer -= delta
	if GameManager.storm_left > 0: _timer -= delta * 1.5
	_seal_timer -= delta
	if GameManager.fever_left <= 0:
		_trash_timer -= delta
		if _trash_timer <= 0:
			_trash_timer = maxf(0.28, 2.3 / (1.0 + GameManager.depth * 0.75))
			_spawn(true)
	if _timer <= 0:
		_timer = 0.13 if GameManager.fever_left > 0 else maxf(0.38, 2.2 / (GameManager.difficulty() * (1.0 + GameManager.bait_level * 0.18)))
		_spawn()
func _spawn(force_trash: bool = false) -> void:
	if get_tree().get_nodes_in_group("entities").size() >= 65: return
	var e = entity_scene.instantiate()
	var dir := 1.0 if randf() > 0.5 else -1.0
	var kind := 0
	if GameManager.fever_left <= 0:
		kind = 0
		if _seal_timer <= 0 and not force_trash:
			kind = 2
			_seal_timer = 28.0
	if force_trash: kind = 1
	e.setup(kind, dir)
	if kind == 1: e.species = e.TRASH_ART.pick_random()
	if GameManager.fever_left > 0: e.species = "pez dorado millonario" if randf() < 0.015 else ["pez azul", "pez naranja"].pick_random()
	var target_z: float = ENTRY_DEPTHS.pick_random()
	# Start farther in the fog and approach over time, avoiding visible pop-in.
	e.position = Vector3(-2.8 * dir, randf_range(1.2, 1.8), ENTRY_START_DEPTHS.pick_random())
	e.entry_target_z = target_z
	if kind == 1 and e.species.begins_with("botella"):
		e.position.x = randf_range(-2.2, 2.2)
		e.position.y = 3.2
	add_child(e)
