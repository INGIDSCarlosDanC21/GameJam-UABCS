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
	create_timer(30).timeout.connect(func(): quit(99))
	var gm = root.get_node("GameManager")
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.5).timeout
	gm.set_process(false)
	main.get_node("Spawner").set_process(false)
	gm.coins = 0
	check(not gm.buy_net() and gm.net_level == 0, "net cannot be bought without funds")
	gm.coins = 50000
	var price: int = gm.net_cost()
	var base: float = gm.capture_duration(0.8, true)
	main.get_node("OceanSession/ShopNet").on_click()
	check(gm.net_level == 1 and gm.coins == 50000 - price and gm.capture_duration(0.8, true) < base, "net button buys faster capture")
	for index in 4: gm.buy_net()
	check(gm.net_level == 5 and not gm.buy_net() and gm.capture_duration(0.8, true) < 0.25, "net caps at five effective upgrades")
	check(gm.capture_duration(0.5, false) == 0.5, "net preserves trash capture time")
	gm.experience = 5
	gm.level = 4
	var waste: int = gm.waste_removed
	gm.clean_trash(false)
	check(gm.level == 5 and gm.depth == 1 and gm.waste_removed == waste + 1, "robot collection advances level and descent once")
	var curtain = main.get_node("OceanSession/DescentCurtain")
	check(curtain.visible and curtain.remaining > 0, "descent starts exterior bubble curtain")
	await create_timer(1.0).timeout
	check(main.get_node("OceanWorld").position.z > 0, "descent moves map toward cabin")
	gm.start_slow_time()
	await process_frame
	var oracle = load("res://scenes/InteractableEntity.tscn").instantiate()
	oracle.species = "pez oracles"
	oracle.position = Vector3(0, 1.6, -3)
	main.add_child(oracle)
	check(oracle._oracle_badge.visible, "Oracle carries visible clock badge")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/net-descent.png")
	oracle.make_unsuitable()
	check(not oracle._oracle_badge.visible, "unsuitable Oracle no longer advertises power")
	await create_timer(3.0).timeout
	check(not curtain.visible, "bubble curtain stops after descent")
	gm.restart()
	await create_timer(0.5).timeout
	check(gm.net_level == 0, "restart resets net")
	print("NET FAILURES: ", failures)
	quit(failures)
