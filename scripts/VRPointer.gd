extends XRController3D
## Independent XR/mouse pointer; visual feedback never moves the tracked camera.
@export var stiffness: float = 100.0
@export var damping: float = 20.0
@export var max_speed: float = 7.0
@export var desktop_enabled := true
@export var pointer_color := Color("7bffdf")
@export_range(0.0, 1.0) var haptic_strength := 1.0
var _hovering: Node3D
@onready var _ray: RayCast3D = $RayCast3D
@onready var _camera: Camera3D = get_parent().get_node("XRCamera3D")
var _claw: Node3D
var _fingers: Array[Node3D] = []
var _velocity := Vector3.ZERO
var _aim := Vector3.FORWARD
var _held := false
var _target: Node3D
var _progress := 0.0
var _cooldown := 0.0
var _info: Label3D
var _initialized := false
var _grip_bar: MeshInstance3D
var _pressed_target: Node3D
var _grip_ratio := 0.0
var held_snail: Node3D
var _elapsed := 0.0
var _idle := 0.0
var _last_aim := Vector3.FORWARD
var _capture_ring: MultiMesh
var _cursor_material: StandardMaterial3D
var _activation_flash := 0.0
var _activation_color := Color.WHITE
var _haptic_until := 0
var _haptic_amplitude := 0.0

func _ready() -> void:
	add_to_group("xr_pointers")
	GameManager.depth_changed.connect(func(_depth: int): pulse(1.0, 0.45))
	GameManager.level_changed.connect(func(_level: int): pulse(0.9, 0.22))
	button_pressed.connect(_pressed)
	button_released.connect(_released)
	$LaserBeam.hide()
	_ray.top_level = true
	_ray.collision_mask = 2
	_ray.collide_with_areas = true
	_ray.collide_with_bodies = false
	_claw = Node3D.new()
	add_child(_claw)
	_claw.top_level = true
	_grip_bar = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.22, 0.018, 0.008)
	_grip_bar.mesh = bar
	var green := StandardMaterial3D.new()
	green.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	green.albedo_color = Color("64ffc1")
	_grip_bar.material_override = green
	_grip_bar.position.y = 0.15
	_claw.add_child(_grip_bar)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.045
	ring.outer_radius = 0.058
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = pointer_color
	_cursor_material = mat
	_part(_claw, ring, Vector3.ZERO, mat)
	_claw.get_child(_claw.get_child_count() - 1).rotation.x = PI / 2
	var ticks := MultiMeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(0.008, 0.016, 0.003)
	_capture_ring = MultiMesh.new()
	_capture_ring.transform_format = MultiMesh.TRANSFORM_3D
	_capture_ring.mesh = shape
	_capture_ring.instance_count = 24
	_capture_ring.visible_instance_count = 0
	ticks.multimesh = _capture_ring
	ticks.material_override = green
	ticks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_claw.add_child(ticks)
	for index in 24:
		var angle := float(index) / 24.0 * TAU
		_capture_ring.set_instance_transform(index, Transform3D(Basis(Vector3.BACK, -angle), Vector3(sin(angle), cos(angle), 0) * 0.075))
	_info = Label3D.new()
	_info.font_size = 24
	_info.pixel_size = 0.0013
	_info.outline_size = 6
	_info.position = Vector3(0, -0.24, -1.0)
	_camera.add_child(_info)
	if not desktop_enabled:
		_info.reparent(_claw, false)
		_info.position = Vector3(0, -0.12, 0)
		_info.pixel_size = 0.001

func _part(parent: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)

func _process(delta: float) -> void:
	_activation_flash = maxf(0.0, _activation_flash - delta)
	var capturing := _held and _progress > 0.0 and GameManager.stun_left <= 0
	var ratio := _grip_ratio if capturing else 0.0
	_capture_ring.visible_instance_count = ceili(ratio * 24.0)
	_grip_bar.visible = capturing
	_grip_bar.scale.x = maxf(0.001, ratio)
	var targeted := is_instance_valid(_target) and _target.is_in_group("interactable")
	var color := pointer_color if targeted else Color("718893")
	if capturing: color = Color("ffe39a")
	if GameManager.stun_left > 0: color = Color("ff6269")
	if _activation_flash > 0: color = _activation_color
	_cursor_material.albedo_color = color
	var size := 1.12 if targeted else 0.85
	if capturing: size += sin(_elapsed * 12.0) * 0.05
	size += _activation_flash * 0.8
	_claw.scale = Vector3.ONE * size

func _unhandled_input(event: InputEvent) -> void:
	if desktop_enabled and not get_viewport().use_xr and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_held = event.pressed
		_idle = 0
		if not _held: _release_snail()

func _pressed(button: String) -> void:
	if button == "trigger_click":
		_held = true

func _released(button: String) -> void:
	if button == "trigger_click":
		_held = false
		_release_snail()

func _physics_process(delta: float) -> void:
	if not desktop_enabled and not get_viewport().use_xr:
		_claw.hide()
		return
	_elapsed += delta
	_idle += delta
	_info.modulate.a = move_toward(_info.modulate.a, 1.0 if _elapsed < 60 or _idle >= 5 or is_instance_valid(_target) else 0.0, delta)
	if GameManager.stun_left > 0:
		_held = false
		_progress = 0
		_info.text = "BLOQUEADO %.1f s" % GameManager.stun_left
		_info.modulate.a = 1
		_release_snail()
		return
	if not _held: _pressed_target = null
	var vr := get_viewport().use_xr
	if vr and not get_is_active():
		_held = false
		_release_snail()
		_claw.hide()
		_info.hide()
		_clear_target()
		return
	_claw.show()
	_info.show()
	var origin := global_position if vr else _camera.project_ray_origin(get_viewport().get_mouse_position())
	var desired := -global_basis.z if vr else _camera.project_ray_normal(get_viewport().get_mouse_position())
	_aim = desired.normalized()
	if _aim.distance_to(_last_aim) > 0.015 or _held: _idle = 0
	_last_aim = _aim
	_ray.global_position = origin
	_ray.global_basis = Basis.IDENTITY
	_ray.target_position = _aim * 8.0
	_ray.force_raycast_update()
	var point := origin + _aim * 3.8
	var hit: Node3D = null
	if _ray.is_colliding():
		point = _ray.get_collision_point()
		hit = _ray.get_collider() as Node3D
	_claw.global_position = point + (_camera.global_position - point).normalized() * 0.035
	_claw.global_basis = _camera.global_basis
	_cooldown = maxf(0, _cooldown - delta)
	if is_instance_valid(held_snail):
		_info.text = "Arrastra el caracol al borde y suelta"
		return
	if hit != _target:
		_clear_target()
		_target = hit
		if is_instance_valid(_target) and _target.is_queued_for_deletion():
			_target = null
		if is_instance_valid(_target) and _target.has_method("set_hovered"):
			_set_hover(_target, true)
		if is_instance_valid(_target): pulse(0.12, 0.025)
	if not is_instance_valid(_target) or not _target.is_in_group("interactable"):
		_info.text = "Pinza" if _uses_hands() else "Mantén"
		return
	if _held and _pressed_target != _target:
		_pressed_target = _target
		if _target.has_method("on_target_pressed"): _target.on_target_pressed()
	var aligned := true
	if _target.has_method("get_stats_text"):
		_info.text = _target.get_stats_text()
	else:
		_info.text = "Mantén"
	if not _held or not aligned or _cooldown > 0:
		_progress = 0.0
		return
	var required: float = _target.capture_time if _target.has_method("get_stats_text") else 0.18
	if _target.is_in_group("fish"):
		required = GameManager.capture_duration(required, true)
	if GameManager.fever_left > 0: required = 0.06
	_progress += delta
	_grip_ratio = clampf(_progress / required, 0, 1)
	_info.text += "  %d%%" % mini(100, int(100.0 * _progress / required))
	if _progress >= required:
		GameManager.bubbles_requested.emit(point)
		activate_target(_target)
		_progress = 0.0
		_cooldown = 0.15 if GameManager.fever_left > 0 else 0.3
		if not is_instance_valid(held_snail): _held = false

func _clear_target() -> void:
	if is_instance_valid(_target) and _target.has_method("set_hovered"):
		_set_hover(_target, false)
	_target = null
	_progress = 0.0
	_grip_ratio = 0.0

func _release_snail() -> void:
	if is_instance_valid(held_snail): held_snail.release()
	held_snail = null

func activate_target(target: Node3D) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion(): return
	if Time.get_ticks_msec() < int(target.get_meta("direct_touch_until",0)): return
	if target.has_method("on_pointer_click"):
		target.on_pointer_click(self)
	else:
		target.on_click()
	_activation_flash = 0.25
	_activation_color = Color("a0ffe0")
	if target.is_in_group("shop_items") and not target._accepted:
		_activation_color = Color("ff6269")
	pulse(0.45, 0.065)

func _set_hover(target: Node3D, active: bool) -> void:
	if active:
		_hovering = target
		target.set_hovered(true)
	else:
		_hovering = null
		for pointer in get_tree().get_nodes_in_group("xr_pointers"):
			if pointer != self and pointer._hovering == target: return
		target.set_hovered(false)

func pulse(amplitude: float, seconds: float) -> void:
	if not get_viewport().use_xr or not get_is_active() or haptic_strength <= 0 or _uses_hands(): return
	var now := Time.get_ticks_msec()
	# Hover feedback must not cancel a stronger level/descent pulse.
	if now < _haptic_until and amplitude < _haptic_amplitude: return
	_haptic_until = now + int(seconds * 1000)
	_haptic_amplitude = amplitude
	trigger_haptic_pulse("haptic", 0.0, clampf(amplitude * haptic_strength, 0, 1), seconds, 0.0)

func _uses_hands() -> bool:
	var side := "left" if not desktop_enabled else "right"
	var hand := XRServer.get_tracker("/user/hand_tracker/" + side) as XRHandTracker
	return hand != null and hand.has_tracking_data and hand.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_UNOBSTRUCTED
