extends Node
## Index-tip contact in button-local coordinates. Requires approach, press, release.
var _states: Dictionary = {}
var _last_press: Dictionary = {}
var _tips: Dictionary = {}
var _hands: Dictionary = {}
var _origin: XROrigin3D
func _ready() -> void:
	name = "HandTouchButtons"
	_origin = get_parent().get_node("XROrigin3D")
	for side in ["left", "right"]:
		var hand := _make_hand(Color("ff9c78") if side == "left" else Color("78dfff"))
		get_parent().add_child(hand)
		hand.hide()
		_hands[side] = hand
		var tip := Marker3D.new()
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
		_hands[side].visible = valid
		if not valid:
			_states.erase(side)
			continue
		var tip: Vector3 = _origin.global_transform * hand.get_hand_joint_transform(XRHandTracker.HAND_JOINT_INDEX_FINGER_TIP).origin
		_tips[side].global_position = tip
		var palm := _origin.global_transform * hand.get_hand_joint_transform(XRHandTracker.HAND_JOINT_PALM)
		_hands[side].global_transform = palm
		feed_tip(side, tip)

func _make_hand(color: Color) -> Node3D:
	var hand := Node3D.new()
	var material := preload("res://scripts/ConsoleButtonTrim.gd").material(color)
	var palm := MeshInstance3D.new()
	var palm_mesh := SphereMesh.new()
	palm_mesh.radius = 0.042
	palm_mesh.height = 0.070
	palm.mesh = palm_mesh
	palm.scale = Vector3(1.25, 0.72, 0.62)
	palm.material_override = material
	hand.add_child(palm)
	for index in 5:
		var finger := MeshInstance3D.new()
		var finger_mesh := CapsuleMesh.new()
		finger_mesh.radius = 0.008
		finger_mesh.height = 0.055 if index < 4 else 0.042
		finger.mesh = finger_mesh
		finger.material_override = material
		finger.position = Vector3(-0.035 + index * 0.017, 0.035, -0.025)
		finger.rotation.x = PI / 2.0
		hand.add_child(finger)
	return hand
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
			var held: bool = state.get("id",0) == id and state.get("held",false)
			var armed: bool = state.get("id",0) == id and state.get("armed",false)
			if local.z > 0.045:
				held = false
				armed = true
			if armed and not held and local.z <= 0.025:
				var now := Time.get_ticks_msec()
				if now - int(_last_press.get(id,-1000)) > 450:
					_last_press[id] = now
					button.set_meta("direct_touch_until", now + 500)
					button.on_click()
				held = true
			_states[side] = {"id":id,"held":held,"armed":armed}
			if button.has_method("set_touch_depth"): button.set_touch_depth(clampf((0.055 - local.z) / 0.04,0,1))
			break
	if near == null: _states.erase(side)
