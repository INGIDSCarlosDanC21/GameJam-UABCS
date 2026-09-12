extends Node3D
## Shared machined bezel: geometry, no viewport, no extra lights.
static func build(parent: Node3D, size: Vector2, accent: Color) -> Node3D:
	var trim := Node3D.new()
	trim.name = "ConsoleTrim"
	parent.add_child(trim)
	box(trim, Vector3(size.x + 0.045, size.y + 0.045, 0.065), Vector3(0,0,-0.065), Color("17222d"))
	box(trim, Vector3(size.x + 0.015, size.y + 0.015, 0.018), Vector3(0,0,-0.022), Color("69808c"))
	box(trim, Vector3(size.x * 0.64, 0.012, 0.012), Vector3(0,size.y * 0.5 + 0.015,0.008), accent)
	for x in [-1,1]:
		for y in [-1,1]:
			var screw := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.008
			cylinder.bottom_radius = 0.008
			cylinder.height = 0.005
			cylinder.radial_segments = 8
			screw.mesh = cylinder
			screw.rotation.x = PI / 2
			screw.position = Vector3(x * size.x * 0.48,y * size.y * 0.48,0.01)
			screw.material_override = material(Color("a8b8bc"))
			trim.add_child(screw)
	for index in 4:
		box(trim, Vector3(0.026,0.005,0.005), Vector3(size.x * 0.5 - 0.026,-0.025 + index * 0.016,0.012), Color("08131b"))
	return trim
static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.25
	mat.emission_enabled = true
	mat.emission = color * 0.12
	return mat
static func box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = at
	part.material_override = material(color)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part
