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
	var ring := TorusMesh.new()
	ring.inner_radius = 0.045
	ring.outer_radius = 0.058
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("7bffdf")
	_part(_claw, ring, Vector3.ZERO, mat)
	_claw.get_child(_claw.get_child_count() - 1).rotation.x = PI / 2
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
	_aim = desired.normalized()
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
	if hit != _target:
		_clear_target()
		_target = hit
		if is_instance_valid(_target) and _target.has_method("set_hovered"):
			_target.set_hovered(true)
	if not is_instance_valid(_target) or not _target.is_in_group("interactable"):
		_info.text = "Apunta y mantén gatillo / clic para capturar"
		return
	if _held and _pressed_target != _target:
		_pressed_target = _target
		if _target.has_method("on_target_pressed"): _target.on_target_pressed()
	var aligned := true
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
		GameManager.bubbles_requested.emit(point)
		_target.on_click()
		_progress = 0.0
		_cooldown = 0.15 if GameManager.fever_left > 0 else 0.3
		_held = false

func _clear_target() -> void:
	if is_instance_valid(_target) and _target.has_method("set_hovered"):
		_target.set_hovered(false)
	_target = null
	_progress = 0.0
