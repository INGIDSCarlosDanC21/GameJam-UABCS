extends Area3D
var title := ""
var action: Callable
var _label: Label3D
var _face: MeshInstance3D
var _material: StandardMaterial3D
var _touch_depth := 0.0
var _last := -1000
var _menu_button := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("interactable")
	add_to_group("pause_controls")
	add_to_group("touch_buttons")
	set_meta("touch_half", Vector2(0.145, 0.06))
	collision_layer = 2
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.29, 0.12, 0.045)
	collider.shape = box
	add_child(collider)
	_face = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	_face.mesh = mesh
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color("123c50")
	_face.material_override = _material
	add_child(_face)
	_label = Label3D.new()
	_label.text = title
	_label.position.z = 0.03
	_label.font_size = 24
	_label.pixel_size = 0.0012
	if get_parent().is_in_group("journal_panels") or get_parent().get_parent().is_in_group("journal_panels"):
		_menu_button = true
		collision_layer = 4
		_material.no_depth_test = true
		_material.render_priority = 22
		_label.no_depth_test = true
		_label.render_priority = 23
	add_child(_label)
func set_hovered(value: bool) -> void:
	_material.albedo_color = Color("27798a") if value else Color("123c50")
func set_touch_depth(value: float) -> void:
	_touch_depth = value
	_face.position.z = -value * 0.015
func _process(delta: float) -> void:
	_label.scale = Vector3(1.0 / scale.x,1.0 / scale.y,1.0 / scale.z)
	collision_layer = (4 if _menu_button else 2) if is_visible_in_tree() else 0
	_touch_depth = move_toward(_touch_depth, 0, delta * 5)
	_face.position.z = -_touch_depth * 0.015
func on_click() -> void:
	if not is_visible_in_tree() or Time.get_ticks_msec() - _last < 400: return
	_last = Time.get_ticks_msec()
	if action.is_valid(): action.call()
