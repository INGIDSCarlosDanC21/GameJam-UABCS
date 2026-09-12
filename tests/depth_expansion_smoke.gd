extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(25).timeout.connect(func(): quit(99))
	var gm = root.get_node("GameManager")
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("Spawner").set_process(false)
	var fauna = main.get_node("OceanWorld/DepthFauna")
	for depth in [5, 10, 12, 15, 20, 25, 30]:
		gm.depth = depth
		fauna._process(0.1)
		await process_frame
		check(fauna._stage == mini(6, int(depth / 5)), "milestone " + str(depth))
		check(fauna._special.get_child_count() > 0, "special animal exists " + str(depth))
		check(fauna._lanterns[0].visible == (depth >= 12), "lantern depth gate " + str(depth))
		check(fauna._colonies.size() <= 7, "luminous colony stays bounded")
	gm.coins = 20000
	for level in 5: check(gm.buy_flashlight(), "flashlight upgrade")
	check(not gm.buy_flashlight(), "flashlight cap")
	check(gm.net_cost() == 150, "new net base cost")
	gm.storm_wait = 0
	gm._process(0.1)
	check(gm.storm_left > 0, "storm triggers")
	var trash = load("res://scenes/InteractableEntity.tscn").instantiate()
	trash.kind = 1
	trash.species = "lata"
	trash.position = Vector3(0, 1.5, -3)
	main.add_child(trash)
	trash._physics_process(0.2)
	check(trash.position.is_finite() and trash.position.y >= 0.3, "storm trash stays bounded")
	for path in ["underwater_theme.ogg", "abyss_pad.ogg"]:
		check(load("res://assets/audio/depth/" + path).get_length() > 5, "underwater track decodes")
	print("EXPANSION FAILURES: ", failures)
	quit(failures)
