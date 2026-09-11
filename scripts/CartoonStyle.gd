extends Node
## Local materials preserve the imported submarine resource.
const OUTLINE = preload("res://shaders/ink_outline.gdshader")

func _ready() -> void:
	await get_tree().process_frame
	var main := get_parent()
	var env: Environment = main.get_node("WorldEnvironment").environment
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8bbacb")
	env.ambient_light_energy = 0.45
	var sun: DirectionalLight3D = main.get_node("DirectionalLight3D")
	sun.light_color = Color("c4edff")
	sun.light_energy = 1.1
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
			if source is StandardMaterial3D and source.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				var mat := ShaderMaterial.new()
				mat.shader = preload("res://shaders/submarine_gray.gdshader")
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
