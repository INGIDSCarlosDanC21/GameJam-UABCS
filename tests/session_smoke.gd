extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)
	else: print("PASS: ", label)
func _initialize() -> void:
	call_deferred("run")
func entity(main: Node, kind: int, name_text: String, at: Vector3) -> Node3D:
	var e = load("res://scenes/InteractableEntity.tscn").instantiate()
	e.kind = kind
	e.species = name_text
	e.position = at
	main.add_child(e)
	e.set_physics_process(false)
	return e
func run() -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.5).timeout
	main.get_node("Spawner").set_process(false)
	for e in get_nodes_in_group("entities"): e.queue_free()
	await process_frame
	var gm = root.get_node("GameManager")
	var session = main.get_node("OceanSession")
	check(gm.fish_stats(0,1,3).reward > gm.fish_stats(0,1,0).reward, "gold aura raises reward")
	seed(70)
	var shallow = entity(main,0,"pez azul",Vector3(0,1.5,-3))
	gm.depth = 3
	seed(70)
	var deep = entity(main,0,"pez azul",Vector3(0,1.5,-3))
	check(deep.size_factor > shallow.size_factor and deep.capture_time > shallow.capture_time, "depth grows fish and capture time")
	var min_y := 100.0
	var max_y := -100.0
	for i in range(120):
		deep._physics_process(0.016)
		min_y = minf(min_y,deep.position.y)
		max_y = maxf(max_y,deep.position.y)
	check(max_y-min_y > 0.35, "fish zigzag has substantial travel")
	var bottle = entity(main,1,"botella rota superior",Vector3(0,3.2,-3))
	bottle._physics_process(1)
	check(bottle.position.y < 3.0 and bottle.position.x == 0, "glass falls vertically")
	shallow.queue_free()
	deep.queue_free()
	bottle.queue_free()
	gm.depth = 0
	await process_frame
	check(gm.fish_stats(0, 1.0).damage == 1.2, "easy starting damage")
	for i in range(24): gm.progress()
	check(gm.level == 5 and gm.can_descend(), "level five unlocks depth")
	check(gm.descend() and gm.depth == 1 and not gm.descend(), "one descent per milestone")
	var fish = entity(main, 0, "pez azul", Vector3(0,1.5,-3.5))
	var trash = entity(main, 1, "lata", fish.position)
	session._contamination()
	check(fish.unsuitable and fish.collision_layer == 0, "trash contact disables fish")
	check(fish.get_node("Sprite3D").texture.resource_path.ends_with("pez azul noapto.png"), "matching unsuitable sprite")
	trash.queue_free()
	fish.queue_free()
	await process_frame
	var eel = entity(main, 0, "anginla", Vector3(0,1.5,-3.5))
	fish = entity(main, 0, "pez naranja", Vector3(0.4,1.5,-3.5))
	eel.on_target_pressed()
	eel._physics_process(0.01)
	check(eel.angry and fish.unsuitable, "angry eel affects nearby fish")
	var seal = entity(main, 2, "foca", Vector3(0,1.5,-3))
	seal.on_click()
	check(gm.fever_left == 10 and gm.fish_stats(3,1.5).damage == 0, "seal starts protected fever")
	gm._process(10.1)
	check(gm.fever_left == 0, "fever expires")
	gm.coins = 200
	check(gm.buy_filter() and gm.active_cleaners == 1, "filter purchase creates cleaner")
	var robot = get_nodes_in_group("cleaners")[0]
	trash = entity(main, 1, "lata", robot.position)
	var coins: int = gm.coins
	robot._physics_process(0.01)
	check(trash._clicked and gm.coins == coins, "robot cleans without money farming")
	robot.age = 59.99
	robot._physics_process(0.02)
	check(gm.active_cleaners == 0, "robot explodes at sixty seconds")
	var lantern = entity(main, 0, "pez linterna", Vector3(0,1.5,-3))
	lantern.make_unsuitable()
	check(not lantern._local_light.visible, "unsuitable lantern switches off")
	check(lantern.find_children("*","OmniLight3D",false,false).size() == 1, "lantern has real local light")
	var puff := Area3D.new()
	puff.set_script(load("res://scripts/Hostile.gd"))
	main.add_child(puff)
	puff.on_click()
	check(gm.stun_left == 5 and puff.triggered, "puffer stun begins")
	gm._process(5.1)
	puff._physics_process(5.1)
	check(gm.stun_left == 0 and puff.leaving, "puffer leaves after stun")
	var snail := Area3D.new()
	snail.set_script(load("res://scripts/Hostile.gd"))
	snail.snail = true
	main.add_child(snail)
	snail.on_click()
	check(snail.grabbed and snail.collision_layer == 0, "snail grabbed")
	snail.global_position = snail._camera.to_global(Vector3(0.6,0,-0.9))
	snail.release()
	check(snail.leaving, "snail thrown outside view radius")
	gm.coins = 10000
	var price: int = gm.filter_cost()
	gm.depth += 1
	check(gm.filter_cost() == price + 10, "depth increases robot price by ten")
	for i in range(10): gm.buy_filter()
	check(gm.active_cleaners == 10 and not gm.buy_filter(), "ten robot limit")
	gm._set_health(20)
	await create_timer(0.3).timeout
	check(session._env.background_energy_multiplier < 1, "low health darkens background")
	gm._set_health(0)
	gm.clean_trash()
	check(gm.defeated and gm.ocean_health == 0 and session._restart.visible, "terminal defeat and restart menu")
	check(not main.get_node("Cabin/ShopBait").visible, "gameplay shop replaced")
	await create_timer(2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/defeat-preview.png")
	gm.restart()
	await create_timer(1).timeout
	check(is_instance_valid(current_scene) and current_scene != main and gm.level == 1 and gm.depth == 0 and gm.ocean_health == 100 and not gm.defeated, "restart resets run")
	print("FAILURES: ", failures)
	quit(failures)