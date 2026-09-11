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
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("637e78")
	stone.roughness = 0.95
	for index in 30:
		var at := Vector3(random.randf_range(-18, 18), 0, random.randf_range(-30, -7))
		at.y = _height(at.x, at.z)
		var rock := SphereMesh.new()
		rock.radial_segments = 10
		rock.rings = 5
		var instance := _mesh(rock, stone, at)
		instance.scale = Vector3(random.randf_range(1, 3), random.randf_range(0.5, 2), random.randf_range(1, 2.5))
		instance.rotation = Vector3(random.randf(), random.randf() * TAU, random.randf())
	var kelp := _material(preload("res://shaders/kelp.gdshader"))
	var blade := PlaneMesh.new()
	blade.orientation = PlaneMesh.FACE_Z
	blade.size = Vector2(0.32, 2.0)
	blade.subdivide_depth = 8
	for index in (35 if OS.has_feature("android") else 70):
		var at := Vector3(random.randf_range(-12, 12), 0, random.randf_range(-24, -7))
		at.y = _height(at.x, at.z) + 0.9
		var plant := _mesh(blade, kelp, at)
		plant.rotation.y = random.randf() * PI

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
