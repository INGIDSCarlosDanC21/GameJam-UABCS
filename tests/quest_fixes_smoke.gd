extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures += 1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var holder := Node3D.new()
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var red := StandardMaterial3D.new()
	red.albedo_color = Color.RED
	var blue := StandardMaterial3D.new()
	blue.albedo_color = Color.BLUE
	var texture := GradientTexture1D.new()
	texture.gradient = Gradient.new()
	blue.albedo_texture = texture
	for material in [red, blue]:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count()-1, material)
	instance.mesh = mesh
	holder.add_child(instance)
	preload("res://scripts/MarineMaterials.gd").prepare(holder, true)
	check(instance.get_active_material(0).albedo_color == Color.RED, "first surface keeps its color")
	check(instance.get_active_material(1).albedo_texture == texture, "second surface keeps its texture")
	check(blue.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL, "preview does not mutate source material")
	root.add_child(holder)
	await process_frame
	holder.queue_free()
	await process_frame
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("Spawner").set_process(false)
	var gm = root.get_node("GameManager")
	gm.select_mode(1)
	gm.practice_mode = true
	var session = main.get_node("OceanSession")
	gm.ocean_health = 49
	session._process(.25)
	check(session._alarm_light.light_energy > 0, "red alarm active below half health")
	var energy: float = session._alarm_light.light_energy
	session._process(.25)
	check(not is_equal_approx(energy, session._alarm_light.light_energy), "alarm pulses")
	check(session._alarm_light.is_in_group("self_lit"), "alarm survives depth dimming")
	gm.ocean_health = 75
	session._process(.1)
	check(session._alarm_light.light_energy == 0, "alarm stops after recovery")
	var puffer := Area3D.new()
	puffer.set_script(load("res://scripts/Hostile.gd"))
	main.add_child(puffer)
	check(puffer._sprite.material_override == null, "puffer has original colors")
	puffer._set_art("pez goblo tranquilo")
	check(puffer._sprite.material_override == null, "puffer keeps original colors on art refresh")
	print("QUEST FIXES FAILURES: ", failures)
	quit(failures)
