extends Node3D
var quality := 1
var age := 0.0
var _bubble_time := 0.0
var cooldown := 0.0
var side := 1.0
func _ready() -> void:
	add_to_group("cleaners")
	var sprite := Sprite3D.new()
	sprite.texture = preload("res://assets/art/robot aspiradora.png")
	if quality == 2: sprite.texture = preload("res://assets/art/robot de basura 2.png")
	if quality == 3: sprite.texture = preload("res://assets/art/robot de basura 3.png")
	var bounds := sprite.texture.get_image().get_used_rect()
	sprite.region_enabled = true
	sprite.region_rect = Rect2(bounds)
	sprite.pixel_size = 0.42 / maxi(bounds.size.x, 1)
	sprite.modulate = [Color.WHITE, Color("96dcff"), Color("ffdc80")][quality - 1]
	add_child(sprite)
func _physics_process(delta: float) -> void:
	if GameManager.defeated: return
	age += delta
	_bubble_time -= delta
	if _bubble_time <= 0:
		_bubble_time = 1.3 / quality
		GameManager.bubbles_requested.emit(global_position)
	cooldown -= delta
	if age >= 60:
		GameManager.active_cleaners = maxi(0, GameManager.active_cleaners - 1)
		get_parent().explode_at(global_position)
		queue_free()
		return
	var nearest: Node3D
	var distance := INF
	for trash in get_tree().get_nodes_in_group("trash"):
		if trash._clicked: continue
		var d := global_position.distance_to(trash.global_position)
		if d < distance:
			distance = d
			nearest = trash
	var destination := Vector3(side * 2.4, 1.15, -3.5)
	if nearest: destination = nearest.global_position
	global_position = global_position.move_toward(destination, [0.75, 1.15, 1.65][quality - 1] * delta)
	if nearest and distance < 0.3 and cooldown <= 0:
		if nearest.collect_by_robot(): cooldown = [3.0, 1.4, 0.65][quality - 1]
	elif not nearest and global_position.distance_to(destination) < 0.1:
		side *= -1
