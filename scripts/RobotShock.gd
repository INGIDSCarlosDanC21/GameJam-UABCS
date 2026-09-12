extends Node3D
## Brief electricity marker attached to a disabled Filtrobot.

var left := 5.0
var _pulse := 0.0
var _material: StandardMaterial3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.emission_enabled = true
	_material.emission = Color("8ceaff")
	_material.emission_energy_multiplier = 3.0
	_material.albedo_color = Color("d5f8ff")
	for height in [-0.05, 0.08, 0.20]:
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.18
		mesh.outer_radius = 0.205
		ring.mesh = mesh
		ring.material_override = _material
		ring.position.y = height
		ring.rotation.x = PI / 2.0
		add_child(ring)
	var sparks := GPUParticles3D.new()
	sparks.name = "ElectricSparks"
	sparks.amount = 26
	sparks.lifetime = 0.32
	sparks.visibility_aabb = AABB(Vector3(-0.45, -0.25, -0.45), Vector3(0.9, 0.7, 0.9))
	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(0.009, 0.055, 0.009)
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = Color("e7fdff")
	spark_material.emission_enabled = true
	spark_material.emission = Color("54d8ff")
	spark_material.emission_energy_multiplier = 5.0
	spark_mesh.material = spark_material
	sparks.draw_pass_1 = spark_mesh
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.23
	process.direction = Vector3(0, 1, 0)
	process.spread = 180.0
	process.gravity = Vector3.ZERO
	process.initial_velocity_min = 0.45
	process.initial_velocity_max = 0.9
	process.scale_min = 0.6
	process.scale_max = 1.2
	process.color = Color("8ceaff")
	sparks.process_material = process
	add_child(sparks)
	var light := OmniLight3D.new()
	light.light_color = Color("6bdcff")
	light.light_energy = 1.8
	light.omni_range = 1.6
	add_child(light)


func _process(delta: float) -> void:
	left -= delta
	_pulse += delta
	_material.emission_energy_multiplier = 1.5 + absf(sin(_pulse * 16.0)) * 3.5
	rotation.y += delta * 2.2
	if left <= 0.0:
		queue_free()
