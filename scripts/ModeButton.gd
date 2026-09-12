extends Area3D
var mode := 0
var _material: StandardMaterial3D
var _label: Label3D
var _face: MeshInstance3D
var _touch_depth := 0.0
func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.24, 0.10, 0.06) if mode == 2 else Vector3(0.34, 0.23, 0.06)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
	var panel := MeshInstance3D.new()
	_face = panel
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	panel.mesh = mesh
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	panel.material_override = _material
	add_child(panel)
	var label := Label3D.new()
	_label = label
	label.text = "EDUCATIVO\n5 min · 3 objetivos" if mode == 0 else "ARCADE\nSin límite de tiempo"
	if mode == 2: label.text = "Créditos 3D"
	label.font_size = 23
	label.pixel_size = 0.00085
	label.position.z = 0.04
	add_child(label)
	preload("res://scripts/ConsoleButtonTrim.gd").build(self,Vector2(shape.size.x,shape.size.y),Color("d0adff") if mode == 1 else Color("76f4d3"))
	add_to_group("touch_buttons")
	set_meta("touch_half",Vector2(shape.size.x,shape.size.y) * 0.5)
	set_hovered(false)
func set_hovered(active: bool) -> void:
	_material.albedo_color = Color("207c86") if active else Color("102d43")
func on_click() -> void:
	if mode == 2:
		get_parent().toggle_credits()
	else:
		get_parent().choose(mode)

func set_touch_depth(value: float) -> void:
	_touch_depth = value

func _process(delta: float) -> void:
	_touch_depth = move_toward(_touch_depth,0.0,delta * 4.0)
	_face.position.z = lerpf(_face.position.z,-0.014 * _touch_depth,1.0 - exp(-18.0 * delta))
	_label.position.z = _face.position.z + 0.04
