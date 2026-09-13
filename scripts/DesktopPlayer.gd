extends Node
## First-person controls used whenever the game runs without an OpenXR headset.

@export var walk_speed := 2.8
@export var sprint_multiplier := 1.8
@export var look_sensitivity := 0.0025
@export var movement_limit := 8.0

var _origin: XROrigin3D
var _camera: Camera3D
var _enabled := false
var _focus_paused := false
var _restore_capture := false
var _pause_label: Label


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
	# Receive focus notifications even while the rest of the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _exit_tree() -> void:
	if _focus_paused:
		get_tree().paused = false
	if _enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled or _focus_paused:
		return
	var journal := get_tree().get_first_node_in_group("journal_panels") as Node3D
	if journal and journal.is_visible_in_tree(): return
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
	if not _enabled or get_tree().paused or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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
	_pause_label = Label.new()
	_pause_label.text = "PAUSA · Vuelve a la ventana para continuar"
	_pause_label.position = Vector2(20, 52)
	_pause_label.add_theme_font_size_override("font_size", 22)
	_pause_label.hide()
	layer.add_child(_pause_label)

func _notification(what: int) -> void:
	if not _enabled or not is_inside_tree(): return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if get_tree().paused: return
		_restore_capture = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		_focus_paused = true
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if is_instance_valid(_pause_label): _pause_label.show()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and _focus_paused:
		_focus_paused = false
		get_tree().paused = false
		if _restore_capture: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if is_instance_valid(_pause_label): _pause_label.hide()
