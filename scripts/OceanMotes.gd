extends MultiMeshInstance3D
## Bounded, single-draw ambient particles outside the cabin.
func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.009
	mesh.height = 0.018
	mesh.radial_segments = 4
	mesh.rings = 2
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/ocean_motes.gdshader")
	mesh.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = 70 if OS.has_feature("android") else 150
	custom_aabb = AABB(Vector3(-23, -2, -23), Vector3(46, 9, 46))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var random := RandomNumberGenerator.new()
	random.seed = 2306
	for index in multimesh.instance_count:
		var angle := PI + random.randf() * PI
		var radius := random.randf_range(8.0, 21.0)
		var at := Vector3(cos(angle) * radius, random.randf_range(-1, 5), sin(angle) * radius)
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * random.randf_range(0.5, 1.4)), at))
