extends Node
## Index-tip contact in button-local coordinates. Requires approach, press, release.
var _states: Dictionary = {}
var _last_press: Dictionary = {}
var _tips: Dictionary = {}
var _hands: Dictionary = {}
var _origin: XROrigin3D
var _sources: Dictionary = {}
var _grips: Dictionary = {}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "HandTouchButtons"
	_origin = get_parent().get_node("XROrigin3D")
	for side in ["left", "right"]:
		var hand := _make_hand(Color("ff9c78") if side == "left" else Color("78dfff"))
		hand.name = "VisibleHand_" + side
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
			var controller := _origin.get_node("LeftController" if side == "left" else "RightController") as XRController3D
			if controller.get_is_active():
				if _sources.get(side, "") != "controller": _states.erase(side)
				_sources[side] = "controller"
				_hands[side].show()
				_hands[side].global_transform = controller.global_transform
				_grips[side] = lerpf(float(_grips.get(side, 0.0)), controller.get_float("grip"), 1.0 - exp(-12.0 * _delta))
				_update_controller_fingers(_hands[side], side, _grips[side])
				feed_tip(side, controller.to_global(Vector3(0, 0, -0.11)))
			else:
				_states.erase(side)
				_sources.erase(side)
			continue
		if _sources.get(side, "") != "hand": _states.erase(side)
		_sources[side] = "hand"
		var tip: Vector3 = _origin.global_transform * hand.get_hand_joint_transform(XRHandTracker.HAND_JOINT_INDEX_FINGER_TIP).origin
		_tips[side].global_position = tip
		var palm := _origin.global_transform * hand.get_hand_joint_transform(XRHandTracker.HAND_JOINT_PALM)
		_hands[side].global_transform = palm
		_update_tracked_fingers(_hands[side], hand)
		feed_tip(side, tip)

func _update_controller_fingers(model: Node3D, side: String, grip: float) -> void:
	for index in 5:
		var finger := model.get_child(index + 1) as MeshInstance3D
		finger.show()
		finger.scale = Vector3.ONE
		var mirror := -1.0 if side == "left" else 1.0
		finger.position = Vector3((-0.03 + index * 0.016) * mirror, 0.0, -0.055)
		finger.rotation = Vector3(PI / 2.0 + clampf(grip, 0, 1) * 0.9, 0, 0)
		if index == 0:
			finger.position = Vector3(-0.048 * mirror, 0, -0.015)
			finger.rotation.z = mirror * 0.55

func _update_tracked_fingers(model: Node3D, tracker: XRHandTracker) -> void:
	var starts := [XRHandTracker.HAND_JOINT_THUMB_PHALANX_PROXIMAL, XRHandTracker.HAND_JOINT_INDEX_FINGER_PHALANX_PROXIMAL, XRHandTracker.HAND_JOINT_MIDDLE_FINGER_PHALANX_PROXIMAL, XRHandTracker.HAND_JOINT_RING_FINGER_PHALANX_PROXIMAL, XRHandTracker.HAND_JOINT_PINKY_FINGER_PHALANX_PROXIMAL]
	var tips := [XRHandTracker.HAND_JOINT_THUMB_TIP, XRHandTracker.HAND_JOINT_INDEX_FINGER_TIP, XRHandTracker.HAND_JOINT_MIDDLE_FINGER_TIP, XRHandTracker.HAND_JOINT_RING_FINGER_TIP, XRHandTracker.HAND_JOINT_PINKY_FINGER_TIP]
	for index in 5:
		var finger := model.get_child(index + 1) as MeshInstance3D
		var flags: int = tracker.get_hand_joint_flags(tips[index])
		finger.visible = (flags & XRHandTracker.HAND_JOINT_FLAG_POSITION_VALID) != 0
		if not finger.visible: continue
		var start: Vector3 = _origin.global_transform * tracker.get_hand_joint_transform(starts[index]).origin
		var end: Vector3 = _origin.global_transform * tracker.get_hand_joint_transform(tips[index]).origin
		var length := start.distance_to(end)
		if length < 0.001: continue
		var axis := (end - start) / length
		var reference := Vector3.RIGHT if absf(axis.dot(Vector3.UP)) > 0.95 else Vector3.UP
		var right := reference.cross(axis).normalized()
		finger.global_transform = Transform3D(Basis(right, axis, right.cross(axis)).scaled(Vector3(1, length / 0.055, 1)), (start + end) * 0.5)

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
	var journal := get_tree().get_first_node_in_group("journal_panels") as Node3D
	if journal and journal.is_visible_in_tree():
		for slider in get_tree().get_nodes_in_group("interactable"):
			if slider.has_method("drag_at") and slider.is_visible_in_tree():
				var local: Vector3 = slider.to_local(tip)
				if absf(local.x)<.27 and absf(local.y)<.04 and absf(local.z)<.04:
					slider.drag_at(tip)
					return
	var near: Node3D
	for button in get_tree().get_nodes_in_group("touch_buttons"):
		if get_tree().paused and not button.is_in_group("pause_controls"): continue
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
