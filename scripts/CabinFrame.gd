extends Node3D
## Fixed observation-window trim gives the player a stable spatial reference.
func _ready() -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("24363e")
	steel.metallic = 0.35
	steel.roughness = 0.7
	var accent := StandardMaterial3D.new()
	accent.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	accent.albedo_color = Color("479eaf")
	for side in [-1.0, 1.0]:
		_beam(Vector3(side * 1.58, 0.58, -1.8), Vector3(side * 1.95, 2.65, -1.8), 0.09, steel)
		_beam(Vector3(side * 1.51, 0.65, -1.78), Vector3(side * 1.86, 2.58, -1.78), 0.012, accent)
	_beam(Vector3(-1.58, 0.58, -1.8), Vector3(1.58, 0.58, -1.8), 0.11, steel)
	_beam(Vector3(-1.95, 2.65, -1.8), Vector3(1.95, 2.65, -1.8), 0.09, steel)

func _beam(start: Vector3, end: Vector3, width: float, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, start.distance_to(end), width)
	part.mesh = mesh
	part.material_override = material
	part.position = (start + end) * 0.5
	part.rotation.z = -atan2(end.x - start.x, end.y - start.y)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(part)
