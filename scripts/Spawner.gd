extends Node3D
@export var entity_scene: PackedScene
var _timer := 0.0
var _seal_timer := 12.0
func _process(delta: float) -> void:
	if GameManager.defeated: return
	_timer -= delta
	_seal_timer -= delta
	if _timer <= 0:
		_timer = 0.23 if GameManager.fever_left > 0 else maxf(0.9, 2.2 / GameManager.difficulty())
		_spawn()
func _spawn() -> void:
	if get_tree().get_nodes_in_group("entities").size() >= 35: return
	var e = entity_scene.instantiate()
	var dir := 1.0 if randf() > 0.5 else -1.0
	var kind := 0
	if GameManager.fever_left <= 0:
		kind = 0 if randf() < 0.7 else 1
		if _seal_timer <= 0:
			kind = 2
			_seal_timer = 28.0
	e.setup(kind, dir)
	if GameManager.fever_left > 0: e.species = ["pez azul", "pez naranja", "pez dorado millonario"].pick_random()
	e.position = Vector3(-2.8 * dir, randf_range(1.2, 1.8), [-2.5, -3.6, -4.8].pick_random())
	add_child(e)