extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	create_timer(60).timeout.connect(func(): quit(99))
	var gm = root.get_node("GameManager")
	var journal = root.get_node("PlayerJournal")
	journal.save_path = "user://marine_qol_test.cfg"
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("Spawner").set_process(false)
	await process_frame
	var fauna = main.get_node("OceanWorld/DepthFauna")
	fauna.set_process(false)
	check(fauna._lanterns.all(func(fish): return not fish.visible),"no shallow 3D lanterns on initial frame")
	var reef=main.get_node("OceanWorld/ReefLife")
	check(reef._swimmers.filter(func(swimmer): return swimmer.node.get_meta("photo_species", "")=="pez linterna").all(func(swimmer): return not swimmer.node.visible and swimmer.min_depth==12),"imported anglerfish schools locked until depth 12")
	var fish = load("res://scenes/InteractableEntity.tscn").instantiate()
	fish.species = "pez linterna"
	main.add_child(fish)
	check(fish.species == "pez azul", "explicit shallow lantern spawn rejected")
	fish.free()
	gm.depth=12
	fauna._process(.016)
	check(fauna._lanterns.all(func(animal): return animal.visible),"lanterns unlock at depth 12")
	for depth in [5,10,15,20,25,30]:
		gm.depth=depth
		fauna._process(0)
		fauna._encounter_time=11.5
		fauna._process(0)
		check(fauna._special.position.z+fauna._special_half_depth<=-4.19,"encounter keeps hull clearance "+str(depth))
	gm.level=999
	check(gm.cleaner_limit()==30,"fleet capped at 30")
	for quality in [1,2,3]:
		var robot = Node3D.new()
		robot.set_script(load("res://scripts/ReefCleaner.gd"))
		robot.quality=quality
		main.add_child(robot)
		robot.set_physics_process(false)
		robot._physics_process(.016)
		check(robot._sprite.modulate.a<.5,"idle robot translucent")
		var trash = load("res://scenes/InteractableEntity.tscn").instantiate()
		trash.kind=1
		trash.species="lata"
		main.add_child(trash)
		trash.set_physics_process(false)
		trash.collision_layer=2
		trash.position=robot.position
		robot._find_target()
		robot._physics_process(.016)
		check(robot._eating_left==[5.0,3.5,2.0][quality-1],"quality processing time "+str(quality))
		robot._physics_process(.1)
		robot._process(.1)
		check(robot._sprite.modulate.a==1 and robot._sprite.position.y!=0,"eating is opaque and animated")
		check(robot._sprite.alpha_cut==SpriteBase3D.ALPHA_CUT_DISCARD,"working robot writes opaque cutout for glass refraction")
		var before: float=robot._eating_left
		robot.paralyze(1)
		robot._physics_process(.1)
		check(robot._eating_left==before,"paralysis suspends processing")
		robot.free()
		await process_frame
	var puffer := Area3D.new()
	puffer.set_script(load("res://scripts/Hostile.gd"))
	main.add_child(puffer)
	puffer.set_physics_process(false)
	check(puffer._sprite.alpha_cut==SpriteBase3D.ALPHA_CUT_DISCARD,"puffer uses opaque cutout")
	var pointer = main.get_node("XROrigin3D/RightController")
	pointer._aim=Vector3(0,0,-1)
	var puffer_start: Vector3 = puffer.position
	for tick in 30: puffer._physics_process(1.0/60.0)
	check(is_equal_approx(puffer.position.z,-2.05),"puffer stays on exterior near-window plane")
	check(puffer.position.distance_to(puffer_start)<=.141,"puffer gives player reaction time with bounded speed")
	puffer.free()
	gm.select_mode(0)
	var picture := Image.create(32,24,false,Image.FORMAT_RGB8)
	picture.fill(Color.CORAL)
	picture.save_png("user://marine_test_photo.png")
	journal.species.assign(["pez payaso"])
	journal.record_photo("pez payaso","user://marine_test_photo.png")
	check(journal.photo_for("pez payaso")=="user://marine_test_photo.png","known species photo appears in education")
	journal.save_progress()
	journal.photos.clear()
	journal.load_progress()
	check(journal.photos.has("pez payaso"),"photographs persist")
	gm.select_mode(0)
	check(journal.photo_for("pez payaso").is_empty() and journal.photos.has("pez payaso"),"new educational expedition has its own album without deleting archive")
	var extras = main.get_node("ExpeditionExtras")
	extras.open_menu()
	extras._page="Práctica"
	extras._render_page()
	await process_frame
	for control in extras._controls.get_children():
		if control.has_method("drag_at"):
			control.drag_at(control.to_global(Vector3(.26,0,0)))
	check(extras._practice_depth==30,"practice slider reaches maximum depth")
	extras._page="Almanaque"
	extras._render_page()
	extras._choose_species()
	await process_frame
	check(extras._controls.get_child_count()==19,"species dropdown has 18 choices and cancel")
	paused=false
	print("MARINE QOL FAILURES: ", failures)
	quit(failures)
