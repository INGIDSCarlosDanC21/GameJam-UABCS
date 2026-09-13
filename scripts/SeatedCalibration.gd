extends Node
var _frames := 0
var _done := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_delta: float) -> void:
	if _done or not get_viewport().use_xr: return
	var tracker := XRServer.get_tracker("head") as XRPositionalTracker
	if tracker == null: return
	var pose: XRPose = tracker.get_pose("default")
	if pose == null or not pose.has_tracking_data: return
	_frames += 1
	if _frames < 30: return
	var origin := get_parent().get_node("XROrigin3D") as XROrigin3D
	var camera := origin.get_node("XRCamera3D") as XRCamera3D
	# Offset the tracking origin once; never overwrite tracked head movement.
	origin.position.y += 1.6 - camera.global_position.y
	_done = true
