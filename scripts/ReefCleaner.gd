extends Node3D
var quality := 1
var age := 0.0
var _bubble_time := 0.0
var cooldown := 0.0
var side := 1.0
var _sprite: Sprite3D
var paralyzed_left := 0.0
func _ready() -> void:
	add_to_group("cleaners")
	_sprite = Sprite3D.new()
	add_child(_sprite)
	set_quality(quality)

func set_quality(value: int) -> void:
	quality = clampi(value, 1, 3)
	if not is_instance_valid(_sprite): return
	_sprite.texture = preload("res://assets/art/robot aspiradora.png")
	if quality == 2: _sprite.texture = preload("res://assets/art/robot de basura 2.png")
	if quality == 3: _sprite.texture = preload("res://assets/art/robot de basura 3.png")
	var bounds := _sprite.texture.get_image().get_used_rect()
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(bounds)
	_sprite.pixel_size = 0.42 / maxi(bounds.size.x, 1)
	_sprite.modulate = [Color.WHITE, Color("96dcff"), Color("ffdc80")][quality - 1]
func _physics_process(delta: float) -> void:
	if GameManager.is_run_over(): return
	delta *= GameManager.world_time_scale()
	age += delta
	paralyzed_left = maxf(0.0, paralyzed_left - delta)
	if paralyzed_left > 0.0:
		_sprite.modulate = Color("a6eaff")
		return
	_sprite.modulate = [Color.WHITE, Color("96dcff"), Color("ffdc80")][quality - 1]
	_bubble_time -= delta
	if _bubble_time <= 0:
		_bubble_time = 1.3 / quality
		GameManager.bubbles_requested.emit(global_position)
		GameManager.sound_at_requested.emit("robot", global_position)
	cooldown -= delta
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
	_animate_heading(destination - global_position, delta)
	global_position = global_position.move_toward(destination, [0.75, 1.15, 1.65][quality - 1] * delta)
	if nearest and distance < 0.3 and cooldown <= 0:
		if nearest.collect_by_robot(): cooldown = [3.0, 1.4, 0.65][quality - 1]
	elif not nearest and global_position.distance_to(destination) < 0.1:
		side *= -1

func paralyze(seconds: float) -> void:
	paralyzed_left = maxf(paralyzed_left, seconds)
	for effect in get_children():
		if effect is Node3D and effect.get_script() == preload("res://scripts/RobotShock.gd"):
			effect.left = paralyzed_left
			return
	var shock := Node3D.new()
	shock.set_script(preload("res://scripts/RobotShock.gd"))
	add_child(shock)

func _animate_heading(travel: Vector3, delta: float) -> void:
	if absf(travel.x) > 0.04:
		var yaw := 0.0 if travel.x >= 0 else PI
		_sprite.rotation.y = lerp_angle(_sprite.rotation.y, yaw, 1.0 - exp(-delta * 4.5))
	var bank := clampf(travel.y * 0.22, -0.20, 0.20) + sin(age * 3.0) * 0.045
	_sprite.rotation.z = lerp_angle(_sprite.rotation.z, bank, 1.0 - exp(-delta * 4.0))
	_sprite.position.y = sin(age * 2.2) * 0.025
