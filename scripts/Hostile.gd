extends Area3D
@export var snail := false
@export var jellyfish := false
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
var _settle_target := Vector3.ZERO
var _crawling := false
var _swim_direction := 1.0
var _swim_y := 0.0
var _swim_z := -5.5
const SNAIL_GAP := 0.17
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
	_sprite.shaded = jellyfish
	if snail:
		_sprite.no_depth_test = true
		_sprite.render_priority = 10
	_snail_index = randi_range(0,2)
	_set_art(["caracol 1","caracol2","caracol3"][_snail_index] if snail else ("medusa" if jellyfish else "pez goblo tranquilo"))
	var shape := CollisionShape3D.new()
	var box := SphereShape3D.new()
	box.radius = 0.08 if snail else (0.13 if jellyfish else 0.11)
	shape.shape = box
	add_child(shape)
	var spread := maxf(0.10, 0.32 - GameManager.depth * 0.045)
	_offset = Vector3(randf_range(-spread,spread),randf_range(-spread * 0.65,spread * 0.65),-0.9)
	if jellyfish:
		_swim_direction = 1.0 if randf() > 0.5 else -1.0
		_swim_y = randf_range(0.7, 2.4)
		_swim_z = randf_range(-7.2, -4.8)
		_offset = Vector3(-3.6 * _swim_direction, _swim_y, _swim_z)
	if snail:
		_settle_target = _choose_snail_slot()
		var queue_depth := 0
		for other in get_tree().get_nodes_in_group("hostiles"):
			if other != self and other.snail and other._crawling and absf(other._settle_target.x - _settle_target.x) < 0.08:
				queue_depth += 1
		_offset = Vector3(_settle_target.x, -0.68 - queue_depth * 0.18, -0.9)
		_crawling = true
	global_position = _offset if jellyfish else _camera.to_global(_offset)
	if snail: GameManager.sound_at_requested.emit("snail", global_position)
func _set_art(name_text: String) -> void:
	_sprite.texture = load("res://assets/art/" + name_text + ".png")
	var rect := _sprite.texture.get_image().get_used_rect()
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(rect)
	var target_width := 0.14 if snail else (0.28 if jellyfish else 0.22)
	_sprite.pixel_size = target_width / maxi(1, maxi(rect.size.x, rect.size.y)) if snail else target_width / maxi(1, rect.size.x)
func _process(_delta: float) -> void:
	# Follow the rendered head pose, not only the fixed physics tick.
	if snail and not grabbed and not leaving and is_instance_valid(_camera):
		global_transform = _camera.global_transform * Transform3D(Basis.IDENTITY, _offset)
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
	elif jellyfish:
		_sprite.rotation.z = sin(age * 2.8) * 0.13
		_sprite.modulate = Color(0.55 + 0.45 * pow(GameManager.ocean_health / 100.0, 2.0), 0.72 + 0.28 * pow(GameManager.ocean_health / 100.0, 2.0), 1.0, 1.0)
		if triggered:
			if age >= 1.0: depart()
		else:
			_offset.x += _swim_direction * (0.30 + GameManager.depth * 0.025) * delta
			_offset.y = _swim_y + sin(age * 1.35) * 0.32
			_offset.z = _swim_z + sin(age * 0.85) * 0.32
			global_position = _offset
			if absf(_offset.x) > 3.7 or age >= 14: depart()
	elif snail:
		if _crawling:
			_offset = _offset.move_toward(_settle_target, delta * 0.18)
			_crawling = _offset.distance_to(_settle_target) > 0.002
		_sprite.rotation.z = lerp_angle(_sprite.rotation.z, sin(age * 5.0) * 0.09 if _crawling else 0.0, 1.0 - exp(-delta * 6.0))
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
	elif jellyfish:
		triggered = true
		age = 0
		collision_layer = 0
		_set_art("medusa electricidad")
		for cleaner in get_tree().get_nodes_in_group("cleaners"):
			cleaner.paralyze(5.0)
		GameManager.sound_requested.emit("electric")
	else:
		triggered = true
		age = 0
		_set_art("pez goblo alterado")
		GameManager.stun_left = 2.5
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
		_settle_target = _choose_snail_slot(_offset)
		_crawling = true
		collision_layer = 2

func shake_off() -> void:
	if not snail or leaving: return
	grabbed = false
	if is_instance_valid(_pointer) and _pointer.held_snail == self:
		_pointer.held_snail = null
	depart()

func _choose_snail_slot(preferred: Vector3 = Vector3(0, 0.16, -0.9)) -> Vector3:
	var best := Vector3(0, 0.16, -0.9)
	var score := INF
	for row in 3:
		for column in 5:
			var slot := Vector3((column - 2) * SNAIL_GAP, 0.16 - row * SNAIL_GAP, -0.9)
			var free := true
			for other in get_tree().get_nodes_in_group("hostiles"):
				if other == self or not other.snail or other.leaving or other.is_queued_for_deletion(): continue
				if slot.distance_to(other._settle_target) < SNAIL_GAP * 0.9:
					free = false
					break
			if not free: continue
			var candidate := slot.distance_to(preferred) + randf_range(0.0, 0.04)
			if candidate < score:
				score = candidate
				best = slot
	return best
func depart() -> void:
	leaving = true
	collision_layer = 0
	velocity = (_camera.global_basis.x * (1 if _offset.x >= 0 else -1) + _camera.global_basis.y * 0.4 - _camera.global_basis.z).normalized() * 2
func get_stats_text() -> String:
	if snail: return "CARACOL: mantén, arrastra al borde y suelta"
	if jellyfish: return "MEDUSA: al tocarla paraliza todos los robots durante 5 s"
	return "PEZ GLOBO: evita tocarlo"
