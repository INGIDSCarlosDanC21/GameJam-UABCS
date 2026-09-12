extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)
	else: print("PASS: ", label)
func _initialize() -> void:
	call_deferred("run")
func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/reef-" + label + ".png")
func run() -> void:
	create_timer(30.0).timeout.connect(func(): printerr("FAIL: reef test timeout"); quit(99))
	var gm = root.get_node("GameManager")
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("Spawner").set_process(false)
	var ocean = main.get_node("OceanWorld")
	var life = ocean.get_node("ReefLife")
	check(life._swimmers.size() == 41, "desktop includes depth-gated shark and whale")
	check(life.find_children("*", "CollisionObject3D", true, false).is_empty(), "scenery cannot intercept either controller or collide with gameplay")
	var planted := 0
	var plants: Array[Node] = life.find_children("*", "MultiMeshInstance3D", true, false)
	for plant in plants: planted += plant.multimesh.instance_count
	check(plants.size() > 10 and planted > 60, "multiple imported coral shapes and kelp are instanced")
	var players: Array[Node] = life.find_children("*", "AnimationPlayer", true, false)
	check(players.size() == 41, "all decorative animals have skeletal swimming")
	var looping := true
	for player in players:
		looping = looping and player.is_playing() and player.get_animation(player.current_animation).loop_mode == Animation.LOOP_LINEAR
	check(looping, "swimming clips play continuously")
	var first_player = players[0]
	var pose_time: float = first_player.current_animation_position
	await create_timer(1.5).timeout
	check(not is_equal_approx(pose_time, first_player.current_animation_position), "skeleton animation advances")
	await capture("shallow")
	# Exercise full circuits; nothing is destroyed, teleported or brought into the lanes.
	var node_count: int = life.get_child_count()
	var safe := true
	var smooth := true
	for tick in 1200:
		life._update_swimmers(tick * 0.25)
		var before: Vector3 = life._swimmers[0].node.position
		life._update_swimmers(tick * 0.25 + 0.016)
		smooth = smooth and before.distance_to(life._swimmers[0].node.position) < 0.03
		for swimmer in life._swimmers:
			if not swimmer.node.visible: continue
			var at: Vector3 = swimmer.node.position
			safe = safe and (at.z < -8.0 or absf(at.x) > 8.0) and swimmer.node.transform.is_finite()
	check(safe, "five minutes of paths stay finite and behind the gameplay lanes")
	check(smooth, "path positions and heading evolve without boundary teleports")
	check(node_count == life.get_child_count(), "population stays bounded across repeated circuits")
	var patterns := {}
	var facing := true
	for swimmer in life._swimmers:
		patterns[swimmer.pattern] = true
		var animal: Node3D = swimmer.node
		var start := animal.position
		life._update_swimmers(299.766 + 0.01)
		var velocity := animal.position - start
		if velocity.length() > 0.0001: facing = facing and (-animal.basis.z).dot(velocity.normalized()) > 0.98
		life._update_swimmers(299.766)
	check(patterns.size() == 3 and facing, "three trajectory patterns face along their travel")
	gm.depth = 4
	gm.depth_changed.emit(4)
	await create_timer(4.0).timeout
	await capture("deep")
	check(life._materials[0].get_shader_parameter("depth_level") == 4.0, "reef shading follows descent")
	# The headless dummy renderer returns identity from MultiMesh GPU readback.
	if DisplayServer.get_name() != "headless":
		check(ocean._basalt.get_instance_transform(0).basis.y.length() > 2.0, "deep scenario reveals basalt formations")
	else:
		check(ocean._depth > 3.0 and ocean._basalt_poses[0].basis.y.length() > 2.0, "deep scenario reaches basalt emergence with full-height source geometry")
	gm._set_health(15)
	await create_timer(1.5).timeout
	check(life._materials[0].get_shader_parameter("ecosystem_light") < 0.03, "plant emission fades with ecosystem failure")
	await capture("unhealthy")
	life.free()
	var mobile := Node3D.new()
	mobile.set_script(load("res://scripts/ReefLife.gd"))
	mobile._mobile = true
	ocean.add_child(mobile)
	var mobile_plants := 0
	for plant in mobile.find_children("*", "MultiMeshInstance3D", true, false): mobile_plants += plant.multimesh.instance_count
	check(mobile._swimmers.size() == 23 and mobile_plants < planted, "Quest profile reduces fauna and vegetation")
	print("REEF FAILURES: ", failures)
	quit(failures)
