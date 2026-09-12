extends Node
## First-person controls used whenever the game runs without an OpenXR headset.

@export var walk_speed := 2.8
@export var sprint_multiplier := 1.8
@export var look_sensitivity := 0.0025
@export var movement_limit := 8.0

var _origin: XROrigin3D
var _camera: Camera3D
var _enabled := false


func _ready() -> void:
	name = "DesktopPlayer"
	_origin = get_parent().get_node("XROrigin3D")
	_camera = _origin.get_node("XRCamera3D")
	_enabled = not get_viewport().use_xr
	if not _enabled:
		set_process(false)
		set_process_unhandled_input(false)
		return
	_show_controls()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _exit_tree() -> void:
	if _enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_origin.rotate_y(-event.relative.x * look_sensitivity)
		_camera.rotation.x = clampf(_camera.rotation.x - event.relative.y * look_sensitivity, -1.25, 1.15)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var direction := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): direction.z -= 1.0
	if Input.is_key_pressed(KEY_S): direction.z += 1.0
	if Input.is_key_pressed(KEY_A): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D): direction.x += 1.0
	if Input.is_key_pressed(KEY_SPACE): direction.y += 1.0
	if Input.is_key_pressed(KEY_CTRL): direction.y -= 1.0
	if direction == Vector3.ZERO:
		return
	var speed := walk_speed * (sprint_multiplier if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	var world_direction := _origin.global_basis * direction.normalized()
	_origin.global_position += world_direction * speed * delta
	_origin.position.x = clampf(_origin.position.x, -movement_limit, movement_limit)
	_origin.position.y = clampf(_origin.position.y, -movement_limit, movement_limit)
	_origin.position.z = clampf(_origin.position.z, -movement_limit, movement_limit)


func _show_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DesktopControls"
	add_child(layer)
	var label := Label.new()
	label.text = "MODO PC  ·  WASD mover  ·  Ratón mirar  ·  Shift rápido  ·  Espacio/Ctrl subir-bajar  ·  Clic izquierdo interactuar  ·  Esc liberar ratón"
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = Color("c8f6ff")
	layer.add_child(label)
