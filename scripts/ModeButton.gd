extends Area3D
var mode := 0
var _material: StandardMaterial3D
var _label: Label3D
func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.38, 0.10, 0.06) if mode == 2 else Vector3(0.78, 0.46, 0.06)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
	var panel := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	panel.mesh = mesh
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	panel.material_override = _material
	add_child(panel)
	var label := Label3D.new()
	_label = label
	label.text = "EDUCATIVO\n5 minutos · 3 objetivos\nConservación del océano" if mode == 0 else "ARCADE\nSin límite de tiempo\nExplora todas las mecánicas"
	if mode == 2: label.text = "Créditos 3D"
	label.font_size = 23
	label.pixel_size = 0.0011
	label.position.z = 0.04
	add_child(label)
	set_hovered(false)
func set_hovered(active: bool) -> void:
	_material.albedo_color = Color("207c86") if active else Color("102d43")
func on_click() -> void:
	if mode == 2:
		get_parent().toggle_credits()
	else:
		get_parent().choose(mode)
