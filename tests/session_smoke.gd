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
	root.get_node("GameManager").select_mode(0)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/cabin-preview.png")
	main.get_node("Spawner").set_process(false)
	for e in get_nodes_in_group("entities"): e.queue_free()
	await process_frame
	var gm = root.get_node("GameManager")
	check(main.get_node("Cabin/ShopFilter").get_parent() == main.get_node("Cabin"), "shop remains fixed in cabin")
	var session = main.get_node("OceanSession")
	var glass_checked := false
	for mesh in main.get_node("Sketchfab_Scene").find_children("*", "MeshInstance3D", true, false):
		for index in mesh.mesh.get_surface_count():
			var material = mesh.get_active_material(index)
			if material is StandardMaterial3D and material.resource_name == "Glass":
				glass_checked = material.albedo_color.a < 0.08
	check(glass_checked, "cabin glass preserves visibility of ocean and HUD")
	check(main.has_node("WindowWaterLight") and main.get_node("WindowWaterLight") in session._lights, "window light follows ocean lighting lifecycle")
	var left = main.get_node("XROrigin3D/LeftController")
	var right = main.get_node("XROrigin3D/RightController")
	if not main.get_viewport().use_xr:
		var desktop = main.get_node_or_null("DesktopPlayer")
		check(desktop != null and desktop._enabled, "desktop mode creates first-person controller")
	check(left.has_method("activate_target") and not left.desktop_enabled, "left pointer is independent and does not duplicate mouse")
	var shared_fish = entity(main, 0, "pez azul", Vector3(0, 1.5, -3))
	var before_catches: int = gm.fish_caught
	left.activate_target(shared_fish)
	right.activate_target(shared_fish)
	check(gm.fish_caught == before_catches + 1, "two pointers cannot collect one fish twice")
	var shop = main.get_node("Cabin/ShopBait")
	left._set_hover(shop, true)
	right._set_hover(shop, true)
	left._set_hover(shop, false)
	check(shop._hover, "hover persists while the other pointer remains")
	right._set_hover(shop, false)
	var ocean = main.get_node("OceanWorld")
	check(ocean.has_node("ReefRocks") and ocean.has_node("ReefLife/Kelp0"), "ocean has batched reef geometry")
	check(ocean.has_node("ReefLife"), "downloaded reef flora and fauna are present")
	right._held = true
	right._progress = 0.5
	right._grip_ratio = 0.5
	right._process(0.01)
	check(right._capture_ring.visible_instance_count == 12, "capture ring displays partial progress")
	right._clear_target()
	right._held = false
	right._process(0.01)
	check(right._capture_ring.visible_instance_count == 0 and not right._grip_bar.visible, "interrupted capture clears visual progress")
	session._depth_announcement(1)
	session._update_descent(0.4)
	check(session._descent_left > 0 and session._rumble.playing, "descent starts timed movement and sound")
	session._update_descent(4.0)
	check(session._camera.h_offset == 0 and session._camera.v_offset == 0, "descent restores camera offsets")
	check(gm.fish_stats(0,1,3).reward > gm.fish_stats(0,1,0).reward, "gold aura raises reward")
	seed(70)
	var shallow = entity(main,0,"pez azul",Vector3(0,1.5,-3))
	shallow._animate_swimming(0.1)
	check(shallow._material.get_shader_parameter("bend_strength") > 0, "living fish bend their body")
	shallow.direction *= -1
	var old_yaw: float = shallow._sprite.rotation.y
	shallow._animate_swimming(0.05)
	check(absf(angle_difference(old_yaw, shallow._sprite.rotation.y)) > 0.05 and absf(angle_difference(old_yaw, shallow._sprite.rotation.y)) < 1.0, "fish turn visually over time")
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
	check(gm.level == 5 and gm.depth == 1, "level five automatically descends")
	check(not gm.descend() and gm.cleaner_quality() == 1, "first robot quality remains until level ten")
	var fish = entity(main, 0, "pez azul", Vector3(0,1.5,-3.5))
	var trash = entity(main, 1, "lata", fish.position)
	session._contamination()
	check(fish.unsuitable and fish.collision_layer == 0, "trash contact disables fish")
	fish._animate_swimming(0.1)
	check(fish._material.get_shader_parameter("bend_strength") == 0.0, "unsuitable fish stop swimming deformation")
	check(fish.get_node("Sprite3D").texture.resource_path.ends_with("pez azul noapto.png"), "matching unsuitable sprite")
	var oracle = entity(main, 0, "pez oracles", Vector3(1, 1.5, -3.5))
	oracle.on_click()
	check(gm.slow_time_left == 5.0, "Oracle starts five second slow time")
	gm._process(5.1)
	check(gm.world_time_scale() == 1.0, "Oracle restores world speed")
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
	robot._animate_heading(Vector3.LEFT, 0.05)
	check(absf(robot._sprite.rotation.y) > 0.05 and absf(robot._sprite.rotation.y) < 1.0, "robot turns gradually instead of flipping instantly")
	trash = entity(main, 1, "lata", robot.position)
	var coins: int = gm.coins
	robot._physics_process(0.01)
	check(trash._clicked and gm.coins == coins, "robot cleans without money farming")
	robot.age = 60.1
	robot._physics_process(0.02)
	check(is_instance_valid(robot) and gm.active_cleaners == 1, "robot remains active after sixty seconds")
	var lantern = entity(main, 0, "pez linterna", Vector3(0,1.5,-3))
	lantern.make_unsuitable()
	check(not lantern._local_light.visible, "unsuitable lantern switches off")
	check(lantern.find_children("*","OmniLight3D",false,false).size() == 1, "lantern has real local light")
	var puff := Area3D.new()
	puff.set_script(load("res://scripts/Hostile.gd"))
	main.add_child(puff)
	puff.on_click()
	check(gm.stun_left == 2.5 and puff.triggered, "puffer stun lasts 2.5 seconds")
	gm._process(2.6)
	puff._physics_process(5.1)
	check(gm.stun_left == 0 and puff.leaving, "puffer leaves after stun")
	gm._set_health(100)
	gm.depth = 2
	var jelly := Area3D.new()
	jelly.set_script(load("res://scripts/Hostile.gd"))
	jelly.jellyfish = true
	main.add_child(jelly)
	var cleaner := Node3D.new()
	cleaner.set_script(load("res://scripts/ReefCleaner.gd"))
	main.add_child(cleaner)
	cleaner.global_position = Vector3(8, 1.0, -8)
	jelly.on_click()
	check(jelly.triggered and jelly.collision_layer == 0, "jellyfish discharges once touched")
	check(cleaner.paralyzed_left >= 5.0 and cleaner.get_child_count() > 1, "jellyfish electrifies nearby cleaners for five seconds")
	jelly._physics_process(1.1)
	check(jelly.leaving, "jellyfish leaves after discharge")
	var octopus = entity(main, 0, "pulpo", Vector3(0, 1.5, -3))
	octopus.on_click()
	check(main.get_node("XROrigin3D/XRCamera3D").get_children().any(func(child): return child.get_script() == load("res://scripts/InkBlot.gd")), "octopus adds a three second ink blot to camera")
	var leaving_octopus = entity(main, 0, "pulpo", Vector3(0, 1.5, -3))
	leaving_octopus._age = leaving_octopus.lifetime + 0.1
	leaving_octopus._physics_process(0.01)
	check(leaving_octopus._exit_age == 0.0, "octopus enters the standard despawn path")
	gm.stun_left = 0.0
	gm.depth = 0
	var arrivals: Array[Node3D] = []
	var spaced := true
	for index in 10:
		var arrival := Area3D.new()
		arrival.set_script(load("res://scripts/Hostile.gd"))
		arrival.snail = true
		main.add_child(arrival)
		arrival.set_physics_process(false)
		for other in arrivals:
			if arrival._settle_target.distance_to(other._settle_target) < 0.16: spaced = false
		arrivals.append(arrival)
	check(spaced, "ten snails reserve distinct destinations")
	check(arrivals[0]._offset.y < -0.6, "snails enter below the view")
	var entry_y: float = arrivals[0]._offset.y
	arrivals[0]._physics_process(0.1)
	check(arrivals[0]._offset.y > entry_y and arrivals[0]._offset.y < entry_y + 0.03, "snail arrival crawls rather than teleporting")
	for arrival in arrivals:
		arrival._physics_process(15.0)
		check(arrival._offset.distance_to(arrival._settle_target) < 0.003, "snail settles at reserved position")
		arrival.queue_free()
	await process_frame
	var snail := Area3D.new()
	snail.set_script(load("res://scripts/Hostile.gd"))
	snail.snail = true
	main.add_child(snail)
	left.activate_target(snail)
	check(snail.grabbed and snail.collision_layer == 0, "snail grabbed")
	check(snail._pointer == left and left.held_snail == snail, "snail follows capturing left hand")
	right.activate_target(snail)
	check(snail._pointer == left, "second hand cannot steal a held snail")
	snail.global_position = snail._camera.to_global(Vector3(0.6,0,-0.9))
	snail.release()
	check(snail.leaving, "snail thrown outside view radius")
	var shaken_snail := Area3D.new()
	shaken_snail.set_script(load("res://scripts/Hostile.gd"))
	shaken_snail.snail = true
	main.add_child(shaken_snail)
	shaken_snail.shake_off()
	check(shaken_snail.leaving, "camera shake releases snails")
	gm.coins = 10000
	var price: int = gm.filter_cost()
	gm.depth += 1
	check(gm.filter_cost() == price + 10, "depth increases robot price by ten")
	for i in range(4): gm.buy_filter()
	check(gm.active_cleaners == 5 and not gm.buy_filter(), "starting robot limit is five")
	gm.level = 10
	gm.coins = 10000
	check(gm.cleaner_limit() == 10 and gm.cleaner_quality() == 2 and gm.buy_filter(), "level ten adds five robot slots and upgrades quality")
	gm.bait_level = 3
	check(gm.bait_cost() == 40 and gm.fish_stats(0,1,0).reward == 6, "bait price and fish reward scale by level")
	gm.net_level = 0
	check(gm.net_cost() == 50, "net starts at a fair multiple-of-ten price")
	gm._set_health(20)
	await create_timer(0.3).timeout
	check(session._env.background_energy_multiplier < 1, "low health darkens background")
	gm._set_health(0)
	gm.clean_trash()
	check(gm.defeated and gm.ocean_health == 0 and session._restart.visible, "terminal defeat and restart menu")
	check(not main.get_node("Cabin/ShopBait").visible, "gameplay shop replaced")
	check(session._restart.get_node("Label3D").text.contains("residuos retirados"), "educational debrief shows expedition impact")
	await create_timer(2).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/defeat-preview.png")
	gm.restart()
	await create_timer(1).timeout
	check(is_instance_valid(current_scene) and current_scene != main and gm.level == 1 and gm.depth == 0 and gm.ocean_health == 100 and not gm.defeated, "restart resets run")
	current_scene.get_node("Spawner").set_process(false)
	check(gm.robots_deployed == 0 and not gm.expedition_finished and gm.expedition_left > 298, "restart resets expedition")
	gm.waste_removed = gm.WASTE_GOAL
	gm.advance_expedition(31)
	check(not gm.expedition_finished and gm.conservation_time == 0, "cleanup alone cannot complete mission")
	gm.coins = 100
	gm.buy_filter()
	gm.advance_expedition(15)
	check(gm.conservation_time == 15, "healthy reef starts conservation objective")
	gm._set_health(69)
	gm.advance_expedition(1)
	check(gm.conservation_time == 0, "low health breaks conservation streak")
	gm._set_health(80)
	gm.advance_expedition(30)
	check(gm.expedition_finished and gm.expedition_success and not gm.defeated, "all three objectives win the expedition")
	coins = gm.coins
	gm.catch_fish()
	gm.clean_trash()
	check(gm.coins == coins and not gm.buy_filter(), "completed expedition blocks economy changes")
	check(current_scene.get_node("OceanSession")._restart.get_node("Label3D").text.contains("MISIÓN CUMPLIDA"), "victory has a positive debrief")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/mission-preview.png")
	gm.restart()
	await create_timer(0.5).timeout
	gm.advance_expedition(300)
	check(gm.expedition_finished and not gm.expedition_success and not gm.defeated, "time limit ends incomplete mission without ecological defeat")
	print("FAILURES: ", failures)
	quit(failures)
