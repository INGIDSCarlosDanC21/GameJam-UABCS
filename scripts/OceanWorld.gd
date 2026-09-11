extends Node3D
## Real geometry behind the gameplay lanes; no screen-space water effects.
var _materials: Array[ShaderMaterial] = []
var _depth := 0.0
var _surface: MeshInstance3D

func _ready() -> void:
	name = "OceanWorld"
	var sand := _material(preload("res://shaders/ocean_floor.gdshader"))
	var terrain := SurfaceTool.new()
	terrain.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := 36 if OS.has_feature("android") else 64
	for z in cells:
		for x in cells:
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = -24.0 + (x + corner.x) * 48.0 / cells
				var pz: float = -38.0 + (z + corner.y) * 42.0 / cells
				terrain.add_vertex(Vector3(px, _height(px, pz), pz))
	terrain.generate_normals()
	_mesh(terrain.commit(), sand, Vector3.ZERO)
	var surface := PlaneMesh.new()
	surface.size = Vector2(64, 64)
	surface.subdivide_width = 32
	surface.subdivide_depth = 32
	_surface = _mesh(surface, _material(preload("res://shaders/water_surface.gdshader")), Vector3(0, 7, -16))
	var random := RandomNumberGenerator.new()
	random.seed = 718
	var stone := _material(preload("res://shaders/reef_rock.gdshader"))
	var rock := SphereMesh.new()
	rock.radial_segments = 12
	rock.rings = 6
	var rocks := _batch("ReefRocks", rock, stone, 48)
	for index in 48:
		var at := Vector3(random.randf_range(-18, 18), 0, random.randf_range(-30, -7))
		at.y = _height(at.x, at.z)
		var size := Vector3(random.randf_range(1, 3), random.randf_range(0.5, 2), random.randf_range(1, 2.5))
		var basis := Basis.from_euler(Vector3(random.randf(), random.randf() * TAU, random.randf())).scaled(size)
		rocks.set_instance_transform(index, Transform3D(basis, at))
	var kelp := _material(preload("res://shaders/kelp.gdshader"))
	var blade := PlaneMesh.new()
	blade.orientation = PlaneMesh.FACE_Z
	blade.size = Vector2(0.32, 2.0)
	blade.subdivide_depth = 8
	var plant_count := 100 if OS.has_feature("android") else 220
	var plants := _batch("KelpGarden", blade, kelp, plant_count)
	for index in plant_count:
		var at := Vector3(random.randf_range(-12, 12), 0, random.randf_range(-24, -7))
		var height := random.randf_range(0.5, 1.6)
		at.y = _height(at.x, at.z) + height
		var basis := Basis(Vector3.UP, random.randf() * TAU).scaled(Vector3(1, height, 1))
		plants.set_instance_transform(index, Transform3D(basis, at))
	# Low silhouettes frame the seabed, leaving the gameplay lanes unobstructed.
	var coral := CylinderMesh.new()
	coral.top_radius = 0.04
	coral.bottom_radius = 0.12
	coral.height = 0.65
	coral.radial_segments = 6
	var coral_material := _material(preload("res://shaders/reef_coral.gdshader"))
	var branches := _batch("CoralGarden", coral, coral_material, 90)
	for index in 90:
		var cluster := index / 9
		var x := sin(float(cluster) * 7.0) * 11.0 + random.randf_range(-0.5, 0.5)
		var z := -8.0 - float(cluster) * 1.7 + random.randf_range(-0.5, 0.5)
		var at := Vector3(x, _height(x, z) + 0.25, z)
		var basis := Basis.from_euler(Vector3(random.randf_range(-0.6, 0.6), random.randf() * TAU, random.randf_range(-0.6, 0.6)))
		branches.set_instance_transform(index, Transform3D(basis, at))

func _batch(label: String, mesh: Mesh, material: Material, count: int) -> MultiMesh:
	var data := MultiMesh.new()
	data.transform_format = MultiMesh.TRANSFORM_3D
	data.mesh = mesh
	data.instance_count = count
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = data
	instance.material_override = material
	instance.extra_cull_margin = 0.5
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return data

func _height(x: float, z: float) -> float:
	return -1.4 + sin(x * 0.24) * 0.45 + cos(z * 0.32 + x * 0.11) * 0.35

func _material(shader: Shader) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	_materials.append(material)
	return material

func _mesh(mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func _process(delta: float) -> void:
	_depth = lerpf(_depth, float(GameManager.depth), 1.0 - exp(-delta))
	_surface.position.y = 7.0 + _depth * 4.0
	for material in _materials:
		material.set_shader_parameter("depth_level", _depth)
		material.set_shader_parameter("ecosystem_light", maxf(0.02, pow(GameManager.ocean_health / 100.0, 2.0)))
