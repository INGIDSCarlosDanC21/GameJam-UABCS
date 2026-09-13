extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(30).timeout.connect(func(): quit(99))
	root.get_node("GameManager").select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("Spawner").set_process(false)
	await create_timer(0.2).timeout
	for item in get_nodes_in_group("entities"): item.queue_free()
	var fish: Array[Node] = []
	for index in 8:
		var entity = load("res://scenes/InteractableEntity.tscn").instantiate()
		entity.species = "pez azul" if index < 4 else "pez naranja"
		entity.color_pattern = index % 4
		entity.position = Vector3(-1.2 + (index % 4) * 0.8,1.9 - (index / 4) * 0.55,-2.7)
		main.add_child(entity)
		entity.set_physics_process(false)
		fish.append(entity)
		check(entity._material.get_shader_parameter("pattern_style") == index % 4,"pattern assigned " + str(index))
	check(fish[0]._material != fish[1]._material,"fish materials are independent")
	var before: float = fish[0].capture_time
	fish[0].color_variety = 0.4
	fish[0]._setup_color_pattern()
	check(fish[0].capture_time == before,"cosmetic patterns do not change capture stats")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/fish-patterns.png")
	for entity in fish:
		var palette: Dictionary = {}
		for parameter in ["pattern_strength", "pattern_style", "pattern_seed", "pattern_color", "body_color"]:
			palette[parameter] = entity._material.get_shader_parameter(parameter)
		entity.make_unsuitable()
		for parameter in palette:
			check(entity._material.get_shader_parameter(parameter) == palette[parameter], "dead fish retains " + parameter)
		check(entity.find_children("*", "Label3D", true, false).is_empty(), "dead fish has no floating text")
	root.get_node("GameManager").depth = 20
	for species in ["pez oracles","pez linterna","anginla","pez dorado millonario"]:
		var entity = load("res://scenes/InteractableEntity.tscn").instantiate()
		entity.species = species
		main.add_child(entity)
		check(entity.species == species and entity._material.get_shader_parameter("pattern_strength") >= 0.0,"special species retains identity " + species)
	print("PATTERN FAILURES: ",failures)
	quit(failures)
