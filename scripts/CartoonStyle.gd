extends Node
## Local materials preserve the imported submarine resource.
const OUTLINE = preload("res://shaders/ink_outline.gdshader")
var _water_materials: Array[ShaderMaterial] = []

func _ready() -> void:
	await get_tree().process_frame
	var main := get_parent()
	var env: Environment = main.get_node("WorldEnvironment").environment
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8bbacb")
	env.ambient_light_energy = 0.45
	var sun: DirectionalLight3D = main.get_node("DirectionalLight3D")
	sun.light_color = Color("c4edff")
	sun.light_energy = 0.55
	sun.rotation_degrees = Vector3(-45, -30, 0)
	for data in [[Vector3(0, 2.6, -0.3), Color("ffe3b5"), 1.4], [Vector3(0, 1.8, -3), Color("69cbff"), 0.8]]:
		var lamp := OmniLight3D.new()
		lamp.position = data[0]
		lamp.light_color = data[1]
		lamp.light_energy = data[2]
		lamp.omni_range = 5.0
		lamp.shadow_enabled = false
		main.add_child(lamp)
	var cabin := main.get_node_or_null("Sketchfab_Scene")
	if cabin:
		_style(cabin)
	var session := main.get_node_or_null("OceanSession")
	if session and is_instance_valid(session._cabin_frame):
		_style(session._cabin_frame)
	var window_light := SpotLight3D.new()
	window_light.name = "WindowWaterLight"
	window_light.position = Vector3(0, 2.1, -1.6)
	window_light.light_color = Color("8bdce5")
	window_light.light_energy = 1.25
	window_light.spot_range = 5.0
	window_light.spot_angle = 65.0
	window_light.spot_attenuation = 1.5
	window_light.shadow_enabled = false
	main.add_child(window_light)
	window_light.look_at(Vector3(0, 0.9, 1.5))

func _process(_delta: float) -> void:
	var strength := pow(GameManager.ocean_health / 100.0, 2.0) * exp(-float(GameManager.depth) * 0.4)
	if GameManager.stun_left > 0: strength = 0.0
	for material in _water_materials:
		material.set_shader_parameter("water_light", strength)

func _style(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var source: Material = node.get_active_material(i)
			if source is StandardMaterial3D and source.resource_name == "Glass":
				# Imported black glass had 88% opacity, hiding the ocean and HUD.
				var glass := source.duplicate() as StandardMaterial3D
				glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				glass.albedo_color = Color(0.22, 0.52, 0.60, 0.035)
				glass.albedo_texture = null
				glass.roughness = 0.18
				glass.metallic = 0.0
				glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				node.set_surface_override_material(i, glass)
				continue
			if source is StandardMaterial3D and source.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and source.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
				var mat := ShaderMaterial.new()
				mat.shader = preload("res://shaders/submarine_gray.gdshader")
				_water_materials.append(mat)
				mat.set_shader_parameter("base_color", source.albedo_color)
				if source.albedo_texture: mat.set_shader_parameter("paint", source.albedo_texture)
				var ink := ShaderMaterial.new()
				ink.shader = OUTLINE
				ink.set_shader_parameter("thickness", 0.006)
				if not OS.has_feature("android"):
					mat.next_pass = ink
				node.set_surface_override_material(i, mat)
	for child in node.get_children():
		_style(child)
