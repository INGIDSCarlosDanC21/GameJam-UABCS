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
	multimesh.instance_count = 90
	custom_aabb = AABB(Vector3(-5, -2, -9), Vector3(10, 8, 8))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var random := RandomNumberGenerator.new()
	random.seed = 2306
	for index in multimesh.instance_count:
		var at := Vector3(random.randf_range(-4.5, 4.5), random.randf_range(-1, 5), random.randf_range(-8, -2.3))
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * random.randf_range(0.5, 1.4)), at))
