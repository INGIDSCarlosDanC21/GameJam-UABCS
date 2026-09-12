extends Node3D
## Low-poly ruins and vent bubbles that fill the distant water without blocking play.
var _clock := 0.0
var _vents: Array[MeshInstance3D] = []
var _batches: Dictionary = {}

func _ready() -> void:
	name = "DistantOceanDetails"
	var stone: StandardMaterial3D = StandardMaterial3D.new()
	stone.albedo_color = Color("315f70")
	stone.roughness = 0.88
	stone.metallic = 0.05
	var arch_column: CylinderMesh = CylinderMesh.new()
	arch_column.top_radius = 0.26
	arch_column.bottom_radius = 0.42
	arch_column.height = 3.6
	arch_column.radial_segments = 7
	var arch_top := BoxMesh.new()
	arch_top.size = Vector3(0.52, 0.35, 0.6)
	for side_value in [-1.0, 1.0]:
		var side: float = side_value
		for index in 4:
			var z: float = -12.0 - index * 4.4
			var x: float = side * (7.0 + (index % 2) * 2.1)
			_add(arch_column, stone, Vector3(x - 1.25, 0.15, z), Vector3(1.0, 1.0, 1.0), index * 0.18)
			_add(arch_column, stone, Vector3(x + 1.25, 0.15, z), Vector3(1.0, 1.0, 1.0), -index * 0.16)
			# A real vertical semicircle, rather than a horizontal torus floating above columns.
			for segment in 9:
				var angle: float = PI * float(segment) / 8.0
				var at := Vector3(x + cos(angle) * 1.25, 1.95 + sin(angle) * 1.25, z)
				_add(arch_top, stone, at, Vector3.ONE, 0.0, angle - PI * 0.5)
	var shell: SphereMesh = SphereMesh.new()
	shell.radial_segments = 10
	shell.rings = 6
	var shell_material: StandardMaterial3D = StandardMaterial3D.new()
	shell_material.albedo_color = Color("6995a0")
	shell_material.roughness = 0.72
	for index in 18:
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var at: Vector3 = Vector3(side * (4.8 + (index % 4) * 1.5), -0.65, -9.0 - (index % 9) * 2.8)
		_add(shell, shell_material, at, Vector3(0.35 + (index % 3) * 0.12, 0.22, 0.42), index * 0.6)
	_make_vents()
	for batch in _batches.values():
		var data := MultiMesh.new()
		data.transform_format = MultiMesh.TRANSFORM_3D
		data.mesh = batch.mesh
		data.instance_count = batch.poses.size()
		for index in data.instance_count: data.set_instance_transform(index, batch.poses[index])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = data
		instance.material_override = batch.material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
	_batches.clear()

func _add(mesh: Mesh, material: Material, at: Vector3, size: Vector3, yaw: float, roll: float = 0.0) -> void:
	var key := mesh.get_instance_id()
	if not _batches.has(key): _batches[key] = {"mesh": mesh, "material": material, "poses": []}
	# Match the uneven seabed, avoiding levitating props.
	at.y += get_parent()._height(at.x, at.z) + 1.4
	_batches[key].poses.append(Transform3D(Basis.from_euler(Vector3(0, yaw, roll)).scaled(size), at))

func _make_vents() -> void:
	var bubble: SphereMesh = SphereMesh.new()
	bubble.radius = 0.055
	bubble.height = 0.11
	bubble.radial_segments = 8
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.42, 0.88, 1.0, 0.38)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	for vent in 16:
		var item: MeshInstance3D = MeshInstance3D.new()
		item.mesh = bubble
		item.material_override = material
		item.position = Vector3(-9.0 + (vent % 4) * 6.0, -0.9 - (vent / 4) * 0.1, -13.0 - (vent % 5) * 3.2)
		item.set_meta("base", item.position)
		item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(item)
		_vents.append(item)

func _process(delta: float) -> void:
	_clock += delta * GameManager.world_time_scale()
	for index in _vents.size():
		var bubble := _vents[index]
		var base: Vector3 = bubble.get_meta("base")
		var cycle: float = fmod(_clock * (0.42 + (index % 3) * 0.08) + index * 0.31, 1.0)
		bubble.position = base + Vector3(sin(_clock * 1.7 + index) * 0.16, cycle * 2.7, cos(_clock + index) * 0.12)
		bubble.scale = Vector3.ONE * (0.45 + cycle * 0.85)
