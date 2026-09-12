extends Node
## Index-tip contact in button-local coordinates. Requires approach, press, release.
var _states: Dictionary = {}
var _last_press: Dictionary = {}
var _tips: Dictionary = {}
var _origin: XROrigin3D
var _camera: Camera3D
func _ready() -> void:
	name = "HandTouchButtons"
	_origin = get_parent().get_node("XROrigin3D")
	_camera = _origin.get_node("XRCamera3D")
	for side in ["left", "right"]:
		var tip := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.008
		sphere.height = 0.016
		tip.mesh = sphere
		tip.material_override = preload("res://scripts/ConsoleButtonTrim.gd").material(Color("80ffe0"))
		get_parent().add_child(tip)
		tip.hide()
		_tips[side] = tip
func _physics_process(_delta: float) -> void:
	if not get_viewport().use_xr: return
	for side in ["left", "right"]:
		var hand := XRServer.get_tracker("/user/hand_tracker/" + side) as XRHandTracker
		var valid := hand != null and hand.has_tracking_data and hand.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_UNOBSTRUCTED
		if valid:
			var flags := hand.get_hand_joint_flags(XRHandTracker.HAND_JOINT_INDEX_FINGER_TIP)
			valid = (flags & XRHandTracker.HAND_JOINT_FLAG_POSITION_VALID) != 0 and (flags & XRHandTracker.HAND_JOINT_FLAG_POSITION_TRACKED) != 0
		_tips[side].visible = valid
		if not valid:
			_states.erase(side)
			continue
		var tip: Vector3 = _origin.global_transform * hand.get_hand_joint_transform(XRHandTracker.HAND_JOINT_INDEX_FINGER_TIP).origin
		_tips[side].global_position = tip
		feed_tip(side, tip)
func feed_tip(side: String, tip: Vector3) -> void:
	var near: Node3D
	for button in get_tree().get_nodes_in_group("touch_buttons"):
		if not button.is_visible_in_tree() or button.collision_layer == 0: continue
		var local: Vector3 = button.to_local(tip)
		var half: Vector2 = button.get_meta("touch_half")
		if absf(local.x) <= half.x and absf(local.y) <= half.y and local.z > -0.045 and local.z < 0.10:
			near = button
			var id: int = button.get_instance_id()
			var state: Dictionary = _states.get(side, {})
			var armed: bool = state.get("id",0) == id and state.get("armed",false)
			var held: bool = state.get("id",0) == id and state.get("held",false)
			if local.z > 0.055:
				armed = true
				held = false
			if armed and not held and local.z <= 0.025:
				var now := Time.get_ticks_msec()
				if now - int(_last_press.get(id,-1000)) > 450:
					_last_press[id] = now
					button.set_meta("direct_touch_until", now + 500)
					button.on_click()
				held = true
				armed = false
			_states[side] = {"id":id,"armed":armed,"held":held}
			if button.has_method("set_touch_depth"): button.set_touch_depth(clampf((0.055 - local.z) / 0.04,0,1))
			break
	if near == null: _states.erase(side)
func _unhandled_input(event: InputEvent) -> void:
	if get_viewport().use_xr: return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_camera.rotation.y -= event.relative.x * 0.004
		_camera.rotation.x = clampf(_camera.rotation.x - event.relative.y * 0.004,-1.1,0.8)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q: _camera.rotation = Vector3(-0.45,1.0,0)
		if event.keycode == KEY_E: _camera.rotation = Vector3(-0.45,-1.0,0)
		if event.keycode == KEY_R: _camera.rotation = Vector3.ZERO
