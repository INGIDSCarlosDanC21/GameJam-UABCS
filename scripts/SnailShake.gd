extends Node
## A quick head turn in VR or a rapid mouse shake in desktop mode removes snails.

@export var turn_speed_required := 2.8
@export var cooldown_seconds := 0.8
@export var required_swipes := 5
@export var swipe_window := 0.9

var _camera: Camera3D
var _previous_forward := Vector3.FORWARD
var _cooldown := 0.0
var _last_direction := 0.0
var _swipes := 0
var _swipe_left := 0.0


func _ready() -> void:
	name = "SnailShake"
	_camera = get_parent().get_node("XROrigin3D/XRCamera3D")
	_previous_forward = -_camera.global_basis.z


func _process(delta: float) -> void:
	if delta <= 0.0 or GameManager.is_run_over():
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	var forward := -_camera.global_basis.z
	var horizontal_speed := _previous_forward.cross(forward).y / delta
	_previous_forward = forward
	_swipe_left = maxf(0.0, _swipe_left - delta)
	if _swipe_left <= 0.0:
		_swipes = 0
		_last_direction = 0.0
	if _cooldown > 0.0 or absf(horizontal_speed) < turn_speed_required:
		return
	var direction := signf(horizontal_speed)
	if direction != _last_direction:
		_last_direction = direction
		_swipes += 1
		_swipe_left = swipe_window
		if _swipes >= required_swipes:
			shake_off_snails()
			_swipes = 0
			_last_direction = 0.0


func shake_off_snails() -> void:
	var removed := false
	for hostile in get_tree().get_nodes_in_group("hostiles"):
		if hostile.snail and not hostile.leaving and _camera.is_position_in_frustum(hostile.global_position):
			hostile.shake_off()
			removed = true
	if removed:
		_cooldown = cooldown_seconds
		GameManager.sound_requested.emit("snail_throw")
