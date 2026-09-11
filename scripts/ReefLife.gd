extends Node3D
## Downloaded decorative fauna/flora. No collision nodes or gameplay timers.
const KELP = preload("res://assets/models/reef/kelp_google.glb")
const CORALS = [preload("res://assets/models/reef/coral_minipoly.glb"), preload("res://assets/models/reef/coral_fan_minipoly.glb"), preload("res://assets/models/reef/coral_branch_minipoly.glb"), preload("res://assets/models/reef/orange_coral_device.glb")]
const FISH = [preload("res://assets/models/reef/fish/Fish1.fbx"), preload("res://assets/models/reef/fish/Fish2.fbx"), preload("res://assets/models/reef/fish/Fish3.fbx")]
const MANTA = preload("res://assets/models/reef/fish/Manta ray.fbx")
const DOLPHIN = preload("res://assets/models/reef/fish/Dolphin.fbx")
var _swimmers: Array[Dictionary] = []
var _materials: Array[ShaderMaterial] = []
var _clock := 0.0
var _rng := RandomNumberGenerator.new()
var _mobile := OS.has_feature("android")

func _ready() -> void:
	name = "ReefLife"
	_rng.seed = 42019
	_plant_model(KELP, true)
	for coral in CORALS: _plant_model(coral, false)
	# Three loose schools, each at its own depth. Keep all paths behind z=-7.
	for school in 3:
		for member in (5 if _mobile else 9):
			var center := Vector3(-2.5 + school * 2.5, 1.2 + school * 1.35, -12.0 - school * 4.0)
			center += Vector3(_rng.randf_range(-0.7, 0.7), _rng.randf_range(-0.65, 0.65), _rng.randf_range(-0.6, 0.6))
			_swimmer(FISH[school], _rng.randf_range(0.38, 0.68), center, Vector2(6.0 + school, 2.3), school * 1.7 + member * 0.12, 0.095 + school * 0.015)
	_swimmer(MANTA, 3.8, Vector3(0, 5.2, -22), Vector2(11, 4.0), 0.4, 0.062)
	for index in (1 if _mobile else 2):
		_swimmer(DOLPHIN, 2.6, Vector3(-2, 3.5 + index * 0.7, -29), Vector2(13, 4), 2.0 + index * 0.2, 0.073)
	_update_swimmers(0.0)

func _source_transform(node: Node3D, scene: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent is Node3D and node != scene:
		result = parent.transform * result
		if parent == scene: break
		parent = parent.get_parent()
	return result

func _plant_model(packed: PackedScene, kelp: bool) -> void:
	var source := packed.instantiate() as Node3D
	var meshes := source.find_children("*", "MeshInstance3D", true, false)
	if source is MeshInstance3D: meshes.push_front(source)
	for variant in meshes.size():
		var mesh := meshes[variant] as MeshInstance3D
		var source_basis := _source_transform(mesh, source).basis
		var box: AABB = Transform3D(source_basis, Vector3.ZERO) * mesh.get_aabb()
		var count := (20 if _mobile else 34) if kelp else (2 if _mobile else 3)
		var data := MultiMesh.new()
		data.transform_format = MultiMesh.TRANSFORM_3D
		data.use_colors = true
		data.use_custom_data = true
		data.mesh = mesh.mesh
		data.instance_count = count
		var batch := MultiMeshInstance3D.new()
		batch.name = ("Kelp" if kelp else "Coral") + str(get_child_count())
		batch.multimesh = data
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batch.extra_cull_margin = 0.35
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/reef_model.gdshader")
		var original := mesh.get_active_material(0) as StandardMaterial3D
		if original and original.albedo_texture:
			material.set_shader_parameter("color_texture", original.albedo_texture)
		material.set_shader_parameter("sway", 0.20 if kelp else 0.018)
		material.set_shader_parameter("tint_strength", 0.0 if kelp else 0.75)
		batch.material_override = material
		_materials.append(material)
		add_child(batch)
		for index in count:
			# An open sandy channel, edged by irregular reef shelves and tall kelp.
			var side := -1.0 if index % 2 == 0 else 1.0
			var z := _rng.randf_range(-29.0, -7.5)
			var x := side * _rng.randf_range(4.0, 11.0)
			if index % 5 == 0:
				z = _rng.randf_range(-27, -19)
				x = _rng.randf_range(-12, 12)
			var height := _rng.randf_range(2.0, 4.5) if kelp else _rng.randf_range(0.75, 1.8)
			if absf(x) < 4.0: height *= 0.55
			var factor := height / maxf(box.size.y, 0.001)
			var yaw := Basis(Vector3.UP, _rng.randf() * TAU)
			var base := Vector3(x, get_parent()._height(x, z) - 0.04, z)
			var pivot := Vector3(box.get_center().x, box.position.y, box.get_center().z)
			data.set_instance_transform(index, Transform3D(yaw.scaled(Vector3.ONE * factor) * source_basis, base - yaw * pivot * factor))
			data.set_instance_custom_data(index, Color(_rng.randf() * TAU, base.y, height, 1))
			var palette := [Color("ff8059"), Color("c393ee"), Color("efa4c9"), Color("e8be65"), Color("75cbb5")]
			var tint: Color = Color.from_hsv(0.10, 0.10, _rng.randf_range(0.85, 1.0)) if kelp else palette[(variant + index) % palette.size()]
			data.set_instance_color(index, tint)
	# Meshes and textures are retained by MultiMesh; the imported scene is temporary.
	source.free()

func _swimmer(packed: PackedScene, length: float, center: Vector3, radius: Vector2, phase: float, speed: float) -> void:
	var pivot := Node3D.new()
	pivot.name = "BackgroundAnimal"
	add_child(pivot)
	var model := packed.instantiate() as Node3D
	pivot.add_child(model)
	var bounds := AABB()
	var first := true
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = _source_transform(mesh, model) * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.extra_cull_margin = 1.0
	var factor := length / maxf(bounds.size.z, 0.001)
	model.scale = Vector3.ONE * factor
	model.position = -bounds.get_center() * factor
	for player in model.find_children("*", "AnimationPlayer", true, false):
		var clips: PackedStringArray = player.get_animation_list()
		for clip in clips:
			if "Swim" in clip:
				var animation: Animation = player.get_animation(clip)
				animation.loop_mode = Animation.LOOP_LINEAR
				player.play(clip)
				player.seek(_rng.randf() * animation.length, true)
				player.speed_scale = _rng.randf_range(0.8, 1.15)
				break
	_swimmers.append({"node": pivot, "center": center, "radius": radius, "phase": phase, "speed": speed})

func _process(delta: float) -> void:
	_clock += delta * GameManager.world_time_scale()
	_update_swimmers(_clock)
	var illumination := maxf(0.02, pow(GameManager.ocean_health / 100.0, 2.0))
	if GameManager.stun_left > 0: illumination *= 0.025
	for material in _materials:
		material.set_shader_parameter("depth_level", float(GameManager.depth))
		material.set_shader_parameter("ecosystem_light", illumination)
		material.set_shader_parameter("world_height", global_position.y)

func _update_swimmers(clock: float) -> void:
	for swimmer in _swimmers:
		var animal: Node3D = swimmer.node
		var t: float = clock * swimmer.speed + swimmer.phase
		var radius: Vector2 = swimmer.radius
		animal.position = swimmer.center + Vector3(cos(t) * radius.x, sin(t * 2.0) * 0.32, sin(t) * radius.y)
		var tangent := Vector3(-sin(t) * radius.x, cos(t * 2.0) * 0.64, cos(t) * radius.y).normalized()
		animal.basis = Basis.looking_at(tangent, Vector3.UP)
		animal.rotate_object_local(Vector3.FORWARD, sin(t) * 0.075)
