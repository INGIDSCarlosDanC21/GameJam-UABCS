extends Area3D
@export var snail := false
var age := 0.0
var capture_time := 0.16
var grabbed := false
var leaving := false
var triggered := false
var velocity := Vector3.ZERO
var _sprite: Sprite3D
var _camera: Camera3D
var _pointer: Node3D
var _offset := Vector3.ZERO
var _leave_age := 0.0
var _snail_index := 0
func _ready() -> void:
	add_to_group("hostiles")
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	_camera = get_viewport().get_camera_3d()
	_pointer = get_tree().current_scene.get_node("XROrigin3D/RightController")
	_sprite = Sprite3D.new()
	add_child(_sprite)
	_snail_index = randi_range(0,2)
	_set_art(["caracol 1","caracol2","caracol3"][_snail_index] if snail else "pez goblo tranquilo")
	var shape := CollisionShape3D.new()
	var box := SphereShape3D.new()
	box.radius = 0.11
	shape.shape = box
	add_child(shape)
	var spread := maxf(0.10, 0.32 - GameManager.depth * 0.045)
	_offset = Vector3(randf_range(-spread,spread),randf_range(-spread * 0.65,spread * 0.65),-0.9)
	global_position = _camera.to_global(_offset)
	if snail: GameManager.sound_requested.emit("snail")
func _set_art(name_text: String) -> void:
	_sprite.texture = load("res://assets/art/" + name_text + ".png")
	var rect := _sprite.texture.get_image().get_used_rect()
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(rect)
	_sprite.pixel_size = (0.14 if snail else 0.22) / maxi(1,rect.size.x)
func _physics_process(delta: float) -> void:
	if GameManager.is_run_over():
		queue_free()
		return
	delta *= GameManager.world_time_scale()
	age += delta
	global_basis = _camera.global_basis
	if leaving:
		_leave_age += delta
		global_position += velocity * delta
		_sprite.modulate.a = maxf(0,1-_leave_age/2.0)
		if _leave_age > 2: queue_free()
	elif grabbed:
		global_position = _pointer._ray.global_position + _pointer._aim * 0.9
	elif snail:
		global_position = _camera.to_global(_offset)
	elif triggered:
		if age >= 5: depart()
	else:
		var target: Vector3 = _pointer._ray.global_position + _pointer._aim * 1.1
		target += _camera.global_basis.x * cos(age * 1.4) * 0.18 + _camera.global_basis.y * sin(age * 1.4) * 0.18
		global_position = global_position.move_toward(target,delta * 0.45)
		if age >= 5: depart()
func on_target_pressed() -> void:
	if not snail: on_click()
func on_click() -> void:
	if leaving or triggered or grabbed: return
	if snail:
		grabbed = true
		collision_layer = 0
		_set_art(["caracol1 agitado","caracol2 agitado","caracol3 agitado"][_snail_index])
		_pointer.held_snail = self
	else:
		triggered = true
		age = 0
		_set_art("pez goblo alterado")
		GameManager.stun_left = 5
		GameManager.sound_requested.emit("puffer")

func on_pointer_click(pointer: Node3D) -> void:
	if leaving or triggered or grabbed: return
	_pointer = pointer
	on_click()
func release() -> void:
	grabbed = false
	var local := _camera.to_local(global_position)
	if Vector2(local.x,local.y).length() > 0.4:
		depart()
		GameManager.sound_requested.emit("snail_throw")
	else:
		_offset = Vector3(local.x,local.y,-0.9)
		collision_layer = 2
func depart() -> void:
	leaving = true
	collision_layer = 0
	velocity = (_camera.global_basis.x * (1 if _offset.x >= 0 else -1) + _camera.global_basis.y * 0.4 - _camera.global_basis.z).normalized() * 2
func get_stats_text() -> String:
	return "CARACOL: mantén, arrastra al borde y suelta" if snail else "PEZ GLOBO: evita tocarlo"
