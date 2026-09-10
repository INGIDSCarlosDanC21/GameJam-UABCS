extends XRController3D
## Spring-driven bone claw. Only the cursor lags; head tracking stays untouched.
@export var stiffness: float = 100.0
@export var damping: float = 20.0
@export var max_speed: float = 7.0
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

func _ready() -> void:
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
	var ivory := StandardMaterial3D.new()
	ivory.albedo_color = Color("8896a4")
	ivory.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://shaders/ink_outline.gdshader")
	ink.set_shader_parameter("thickness", 0.004)
	ivory.next_pass = ink
	var shaft := CapsuleMesh.new()
	shaft.radius = 0.016
	shaft.height = 0.15
	_part(_claw, shaft, Vector3.ZERO, ivory)
	for side in [-1.0, 1.0]:
		var finger := Node3D.new()
		_claw.add_child(finger)
		finger.position = Vector3(side * 0.028, 0.06, 0)
		_fingers.append(finger)
		var ball := SphereMesh.new()
		ball.radius = 0.026
		ball.height = 0.052
		_part(finger, ball, Vector3(0, 0.045, 0), ivory)
		_part(_claw, ball, Vector3(side * 0.024, -0.065, 0), ivory)
	_info = Label3D.new()
	_info.font_size = 24
	_info.pixel_size = 0.0013
	_info.outline_size = 6
	_info.position = Vector3(0, -0.24, -1.0)
	_camera.add_child(_info)
	var plate := MeshInstance3D.new()
	var panel := BoxMesh.new()
	panel.size = Vector3(0.88, 0.21, 0.008)
	plate.mesh = panel
	var panel_material := StandardMaterial3D.new()
	panel_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	panel_material.albedo_color = Color("102535")
	plate.material_override = panel_material
	plate.position = _info.position + Vector3(0, 0, -0.012)
	_camera.add_child(plate)

func _part(parent: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)

func _unhandled_input(event: InputEvent) -> void:
	if not get_viewport().use_xr and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_held = event.pressed

func _pressed(button: String) -> void:
	if button == "trigger_click":
		_held = true

func _released(button: String) -> void:
	if button == "trigger_click":
		_held = false

func _physics_process(delta: float) -> void:
	_grip_bar.scale.x = maxf(0.001, _grip_ratio)
	_grip_bar.visible = _progress > 0
	if not _held: _pressed_target = null
	var vr := get_viewport().use_xr
	if vr and not get_is_active():
		_held = false
		_claw.hide()
		_clear_target()
		return
	_claw.show()
	var origin := global_position if vr else _camera.project_ray_origin(get_viewport().get_mouse_position())
	var desired := -global_basis.z if vr else _camera.project_ray_normal(get_viewport().get_mouse_position())
	_aim = _aim.lerp(desired, 1.0 - exp(-15.0 * delta)).normalized()
	_ray.global_position = origin
	_ray.global_basis = Basis.IDENTITY
	_ray.target_position = _aim * 8.0
	_ray.force_raycast_update()
	var point := origin + _aim * 3.8
	var hit: Node3D = null
	if _ray.is_colliding():
		point = _ray.get_collision_point()
		hit = _ray.get_collider() as Node3D
	if not _initialized:
		_claw.global_position = point
		_initialized = true
	_velocity += ((point - _claw.global_position) * stiffness - _velocity * damping) * delta
	_velocity = _velocity.limit_length(max_speed)
	_claw.global_position += _velocity * delta
	_claw.global_basis = _camera.global_basis
	_claw.rotate_object_local(Vector3.FORWARD, clampf(_velocity.x * 0.05, -0.3, 0.3))
	for i in range(_fingers.size()):
		var angle := (0.1 if _held else 0.55) * (-1 if i == 0 else 1)
		_fingers[i].rotation.z = lerpf(_fingers[i].rotation.z, angle, 1.0 - exp(-12 * delta))
	_cooldown = maxf(0, _cooldown - delta)
	if hit != _target:
		_clear_target()
		_target = hit
		if is_instance_valid(_target) and _target.has_method("set_hovered"):
			_target.set_hovered(true)
	if not is_instance_valid(_target) or not _target.is_in_group("interactable"):
		_info.text = "Mantén gatillo / clic para cerrar la garra"
		return
	if _held and _pressed_target != _target:
		_pressed_target = _target
		if _target.has_method("on_target_pressed"): _target.on_target_pressed()
	var aligned := _claw.global_position.distance_to(point) < 0.3
	if _target.has_method("get_stats_text"):
		_info.text = _target.get_stats_text()
	else:
		_info.text = "Mantén para reiniciar" if GameManager.defeated else "Mantén para activar"
	if not _held or not aligned or _cooldown > 0:
		_progress = 0.0
		return
	var required: float = _target.capture_time if _target.has_method("get_stats_text") else 0.18
	if GameManager.fever_left > 0: required = 0.06
	_progress += delta
	_grip_ratio = clampf(_progress / required, 0, 1)
	_info.text += "\nGarra: %d%%" % mini(100, int(100.0 * _progress / required))
	if _progress >= required:
		_target.on_click()
		_progress = 0.0
		_cooldown = 0.15 if GameManager.fever_left > 0 else 0.3
		_held = false

func _clear_target() -> void:
	if is_instance_valid(_target) and _target.has_method("set_hovered"):
		_target.set_hovered(false)
	_target = null
	_progress = 0.0
