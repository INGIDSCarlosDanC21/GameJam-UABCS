extends Node3D

@export var entity_scene: PackedScene
@export var interval: float = 1.35

var _timer: float = 0.0


func _process(delta: float) -> void:
	_timer += delta
	var wait := interval / (1.0 + float(GameManager.bait_level) * 0.15)
	if _timer >= wait:
		_timer = 0.0
		_spawn()


func _spawn() -> void:
	if entity_scene == null:
		return
	var e: Area3D = entity_scene.instantiate()
	var from_left := randf() > 0.5
	var dir := 1.0 if from_left else -1.0
	# Cebo aumenta aparición de peces (más tentación de sobrepesca).
	var fish_chance := clampf(0.45 + float(GameManager.bait_level) * 0.08, 0.45, 0.8)
	var kind: int = e.Kind.FISH if randf() < fish_chance else e.Kind.TRASH
	e.setup(kind, dir)
	e.position = Vector3(-2.6 if from_left else 2.6, randf_range(1.05, 1.75), [-2.5, -3.9, -5.6].pick_random() + randf_range(-0.15, 0.15))
	add_child(e)
