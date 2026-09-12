extends Node3D
## Real geometry behind the gameplay lanes; no screen-space water effects.
var _materials: Array[ShaderMaterial] = []
var _depth := 0.0

var _descent_left := 0.0
var _descent_travel := 0.0
var _settled_travel := 0.0
var _forward_start := 0.0
var _basalt: MultiMesh
var _basalt_poses: Array[Transform3D] = []

func _ready() -> void:
	name = "OceanWorld"
	GameManager.depth_changed.connect(func(_value: int):
		_descent_left = 3.5
		_settled_travel = position.y
		_forward_start = position.z
	)
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
	var distant_floor := PlaneMesh.new()
	distant_floor.size = Vector2(600, 500)
	_mesh(distant_floor, sand, Vector3(0, -2.4, -260))
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
		if index < 12:
			at.x = (-1.0 if index % 2 == 0 else 1.0) * random.randf_range(9.0, 18.0)
			at.z = random.randf_range(-34.0, -17.0)
			at.y = _height(at.x, at.z) - 0.5
			size = Vector3(random.randf_range(5, 10), random.randf_range(3, 6), random.randf_range(4, 7))
		var basis := Basis.from_euler(Vector3(random.randf(), random.randf() * TAU, random.randf())).scaled(size)
		rocks.set_instance_transform(index, Transform3D(basis, at))
	var column := CylinderMesh.new()
	column.top_radius = 0.45
	column.bottom_radius = 0.8
	column.height = 1.0
	column.radial_segments = 6
	_basalt = _batch("DeepBasalt", column, stone, 24)
	for index in 24:
		var x := (-1.0 if index % 2 == 0 else 1.0) * random.randf_range(6, 17)
		var z := random.randf_range(-26, -11)
		var size := Vector3(random.randf_range(0.7,1.5), random.randf_range(3,7), 1.0)
		_basalt_poses.append(Transform3D(Basis(Vector3.UP, random.randf() * TAU).scaled(size), Vector3(x, _height(x,z), z)))
		_basalt.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(x,-5,z)))
	var life := Node3D.new()
	life.set_script(preload("res://scripts/ReefLife.gd"))
	add_child(life)

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
	if _descent_left > 0:
		_descent_left = maxf(0.0, _descent_left - delta)
		var fraction := 1.0 - _descent_left / 3.5
		# Exterior rises past the stationary headset as the cabin descends.
		_descent_travel = lerpf(_settled_travel, minf(0.75, GameManager.depth * 0.15), smoothstep(0.0, 1.0, fraction))
		position.y = _descent_travel
		position.z = lerpf(_forward_start, minf(2.5, GameManager.depth * 0.4), smoothstep(0.0, 1.0, fraction))
	_depth = lerpf(_depth, float(GameManager.depth), 1.0 - exp(-delta))
	var emergence := smoothstep(1.0, 3.0, _depth)
	for index in _basalt_poses.size():
		var pose := _basalt_poses[index]
		pose.basis = pose.basis.scaled(Vector3(1, maxf(0.001, emergence), 1))
		pose.origin.y += pose.basis.y.length() * 0.5 - (1.0 - emergence)
		_basalt.set_instance_transform(index, pose)

	for material in _materials:
		material.set_shader_parameter("depth_level", _depth)
		material.set_shader_parameter("ecosystem_light", maxf(0.02, pow(GameManager.ocean_health / 100.0, 2.0)))
