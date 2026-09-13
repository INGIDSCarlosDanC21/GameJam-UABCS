extends Node3D
var quality := 1
var age := 0.0
var _bubble_time := 0.0
var cooldown := 0.0
var side := 1.0
var _sprite: Sprite3D
var paralyzed_left := 0.0
const RESERVATION := "filtrobot_owner"
var _target: Node3D
var _search_left := 0.0
var _patrol_phase := 0.0
var _patrol_direction := 1.0
var _patrol_height := 1.15
var _status_light: MeshInstance3D
var _status_material: StandardMaterial3D
var _celebrate := 0.0
var _eating_left := 0.0
var _eating_duration := 0.0
var _meal: Sprite3D
static var _bounds_cache: Dictionary = {}
func _ready() -> void:
	add_to_group("cleaners")
	var slot := get_tree().get_nodes_in_group("cleaners").size() - 1
	_patrol_phase = float(slot) * 2.399963
	_patrol_direction = -1.0 if slot % 2 == 0 else 1.0
	_patrol_height = 0.9 + (slot % 4) * 0.24
	_search_left = (slot % 5) * 0.04
	_sprite = Sprite3D.new()
	_sprite.shaded = true
	add_child(_sprite)
	set_quality(quality)
	_status_light = MeshInstance3D.new()
	var bulb := SphereMesh.new()
	bulb.radius = 0.025
	bulb.height = 0.05
	bulb.radial_segments = 6
	bulb.rings = 3
	_status_light.mesh = bulb
	_status_material = StandardMaterial3D.new()
	_status_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_status_light.material_override = _status_material
	_status_light.position = Vector3(0, 0.13, 0)
	add_child(_status_light)
func _process(delta: float) -> void:
	# Opaque cutouts must enter the opaque pass sampled by the refracting glass.
	# Alpha=1 alone still leaves a Sprite3D in the transparent pass.
	var working := _eating_left > 0 or is_instance_valid(_target)
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD if working else SpriteBase3D.ALPHA_CUT_DISABLED
	_sprite.modulate.a = 1.0 if working else 0.38
	_celebrate = maxf(0, _celebrate - delta)
	_status_material.albedo_color = Color("bd91ff") if paralyzed_left > 0 else (Color("fff19c") if _celebrate > 0 or _eating_left > 0 else (Color("69ffd0") if is_instance_valid(_target) else Color("76a8c2")))
	_status_light.scale = Vector3.ONE * (1.0 + sin(age * 9.0) * 0.2 if paralyzed_left > 0 else 1.0)
	if _celebrate > 0: _sprite.rotation.z += sin(_celebrate * 18.0) * delta * 0.6

func set_quality(value: int) -> void:
	quality = clampi(value, 1, 3)
	if not is_instance_valid(_sprite): return
	_sprite.texture = preload("res://assets/art/robot aspiradora.png")
	if quality == 2: _sprite.texture = preload("res://assets/art/robot de basura 2.png")
	if quality == 3: _sprite.texture = preload("res://assets/art/robot de basura 3.png")
	if not _bounds_cache.has(quality): _bounds_cache[quality] = _sprite.texture.get_image().get_used_rect()
	var bounds: Rect2i = _bounds_cache[quality]
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(bounds)
	_sprite.pixel_size = 0.26 / maxi(bounds.size.x, 1)
	_sprite.modulate = [Color.WHITE, Color("96dcff"), Color("ffdc80")][quality - 1]
	_sprite.modulate.a = 0.38
func _physics_process(delta: float) -> void:
	if GameManager.is_run_over():
		_release_target()
		return
	delta *= GameManager.world_time_scale()
	age += delta
	paralyzed_left = maxf(0.0, paralyzed_left - delta)
	if paralyzed_left > 0.0:
		_release_target()
		_sprite.modulate = Color("a6eaff")
		_sprite.modulate.a = 0.38
		return
	_sprite.modulate = [Color.WHITE, Color("96dcff"), Color("ffdc80")][quality - 1]
	_sprite.modulate.a = 1.0 if _eating_left > 0 or is_instance_valid(_target) else 0.38
	if _eating_left > 0:
		_eating_left = maxf(0, _eating_left - delta)
		var elapsed := _eating_duration - _eating_left
		_sprite.position.y = sin(elapsed * 12.0) * 0.045
		_sprite.rotation.z = sin(elapsed * 6.0) * 0.08
		if is_instance_valid(_meal):
			var suction := smoothstep(0.0, 0.65, elapsed)
			_meal.position = Vector3(0.18 * (1.0 - suction), _sprite.position.y, 0.025)
			_meal.scale = Vector3.ONE * lerpf(1.0, 0.18, suction)
			_meal.modulate.a = minf(1.0, _eating_left / 0.3)
		if _eating_left <= 0:
			if is_instance_valid(_meal): _meal.queue_free()
			_meal = null
			_celebrate = 0.6
		return
	_bubble_time -= delta
	if _bubble_time <= 0:
		_bubble_time = 4.0 + randf() * 2.0
		if is_instance_valid(_target): GameManager.sound_at_requested.emit("robot", global_position)
	cooldown -= delta
	if is_instance_valid(_target) and not _available(_target): _release_target()
	_search_left -= delta
	if not is_instance_valid(_target) and cooldown <= 0.0 and _search_left <= 0.0:
		_search_left = 0.25
		_find_target()
	var phase := _patrol_phase + age * 0.22 * _patrol_direction
	var destination := Vector3((-1.0 if _patrol_direction < 0 else 1.0) * (3.5 + sin(phase) * 0.6), 0.4 + sin(phase * 1.7) * 0.25, -5.5 + cos(phase) * 0.8)
	if is_instance_valid(_target): destination = _target.global_position
	_animate_heading(destination - global_position, delta)
	global_position = global_position.move_toward(destination, [0.75, 1.15, 1.65][quality - 1] * delta)
	if is_instance_valid(_target) and global_position.distance_to(destination) < 0.3 and cooldown <= 0:
		var source := _target.get_node_or_null("Sprite3D") as Sprite3D
		var meal := source.duplicate() as Sprite3D if source != null else null
		if _target.collect_by_robot():
			_eating_duration = [5.0, 3.5, 2.0][quality - 1]
			_eating_left = _eating_duration
			cooldown = 0.25
			_meal = meal
			if _meal != null:
				_meal.material_override = null
				_meal.rotation = Vector3.ZERO
				add_child(_meal)
			GameManager.sound_at_requested.emit("robot_clean", global_position)
		elif meal != null: meal.free()
		_release_target()

func _available(trash: Node3D) -> bool:
	if not is_instance_valid(trash) or trash.is_queued_for_deletion() or trash._clicked or trash.collision_layer == 0: return false
	var claim: WeakRef = trash.get_meta(RESERVATION) if trash.has_meta(RESERVATION) else null
	var owner: Object = claim.get_ref() if claim != null else null
	return not is_instance_valid(owner) or owner == self

func _find_target() -> void:
	if _eating_left > 0 or paralyzed_left > 0: return
	var working := 0
	for robot in get_tree().get_nodes_in_group("cleaners"):
		if robot != self and (is_instance_valid(robot._target) or robot._eating_left > 0): working += 1
	# Keep the interaction lanes readable even with a large purchased fleet.
	if working >= 4: return
	var distance := INF
	for trash in get_tree().get_nodes_in_group("trash"):
		if not _available(trash): continue
		var candidate := global_position.distance_squared_to(trash.global_position)
		if candidate < distance:
			distance = candidate
			_target = trash
	if is_instance_valid(_target): _target.set_meta(RESERVATION, weakref(self))

func _release_target() -> void:
	if is_instance_valid(_target):
		var claim: WeakRef = _target.get_meta(RESERVATION) if _target.has_meta(RESERVATION) else null
		if claim != null and claim.get_ref() == self: _target.remove_meta(RESERVATION)
	_target = null

func _exit_tree() -> void:
	_release_target()

func paralyze(seconds: float) -> void:
	_release_target()
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
