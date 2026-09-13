extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures += 1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	create_timer(45).timeout.connect(func(): quit(99))
	var gm = root.get_node("GameManager")
	var journal = root.get_node("PlayerJournal")
	journal.save_path = "user://research_test.cfg"
	journal.species.clear()
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("Spawner").set_process(false)
	await create_timer(.2).timeout
	main.get_node("OceanWorld/ReefLife").set_process(false)
	for animal in get_nodes_in_group("photographic_fauna"): animal.hide()
	var photo = main.get_node("ResearchCamera")
	photo.photo_folder = "user://test_photos"
	var pointer = main.get_node("XROrigin3D/RightController")
	var camera = root.get_camera_3d()
	var fish = load("res://scenes/InteractableEntity.tscn").instantiate()
	fish.species = "pez payaso"
	fish.position = camera.to_global(Vector3(0,0,-3))
	main.add_child(fish)
	fish.set_physics_process(false)
	fish.collision_layer = 2
	fish._material.set_shader_parameter("fade",1.0)
	await physics_frame
	check(photo.centered_species(camera.global_transform)=="pez payaso","camera identifies centered fish")
	fish.position.x += 3
	check(photo.centered_species(camera.global_transform).is_empty(),"off-center fish does not register")
	fish.position.x -= 3
	photo.on_pointer_click(pointer)
	check(photo.holder==pointer and photo.collision_layer==0,"camera equipped by either pointer interface")
	await photo.photograph()
	if DisplayServer.get_name()!="headless":
		check(FileAccess.file_exists(photo.last_photo),"camera saves an actual PNG photograph")
		check(photo._view.world_3d==main.get_world_3d() and not photo._view.transparent_bg,"photo includes real surroundings")
		check(photo._lens.projection==Camera3D.PROJECTION_PERSPECTIVE and photo._lens.fov<65,"photo zooms to the centered subject")
	check("pez payaso" in journal.species and photo.successful_shots==1,"photograph discovers fish without capturing it")
	check(not fish._clicked,"photography leaves animal alive")
	fish.make_unsuitable()
	check(fish._sprite.texture.resource_path=="res://assets/art/pes payaso muerto.png","clownfish uses supplied death sprite")
	var flashlight=main.get_node("Cabin/ShopFlashlight")
	check(flashlight._art.texture.resource_path=="res://assets/art/linterna.png","flashlight shop uses new artwork")
	check(maxf(flashlight._art.region_rect.size.x,flashlight._art.region_rect.size.y)*flashlight._art.pixel_size <= .116,"flashlight artwork fits button")
	photo.release()
	check(photo.holder==null and photo.collision_layer==2,"camera returns to cabin")
	var extras = main.get_node("ExpeditionExtras")
	extras.open_menu()
	photo.on_pointer_click(pointer)
	check(not photo.handle_press(pointer),"held camera does not steal menu clicks")
	photo.release()
	extras._selected = 17
	extras._catalog_page = 2
	extras._page = "Almanaque"
	extras._render_page()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/almanac-preview.png")
	extras._show_model()
	check(is_instance_valid(extras._preview) and extras._preview.get_child_count()>0,"almanac creates imported species hologram")
	for index in 18:
		var model = load("res://scripts/SpeciesCatalog.gd").model(index)
		check(model == null if index == 6 else is_instance_valid(model) and model.get_child_count()>0,"downloaded model or explicit missing oracle "+str(index))
		if model != null: model.free()
	var catalog: Array = load("res://scripts/SpeciesCatalog.gd").entries()
	check(catalog.size()==18 and catalog.all(func(entry): return not entry.photo.is_empty() and ResourceLoader.exists(entry.photo) and not entry.license.is_empty()),"all species have licensed real reference images")
	extras._page="Ajustes"
	extras._settings_page=0
	extras._render_page()
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/settings-marine.png")
	var slider: Node3D
	for control in extras._controls.get_children():
		if control.has_method("drag_at") and control.key=="effects": slider=control
	slider.drag_at(slider.to_global(Vector3(-.26,0,0)))
	check(journal.effects==0,"slider reaches mute")
	slider.drag_at(slider.to_global(Vector3(.26,0,0)))
	check(journal.effects==1,"slider reaches full volume")
	journal.render_scale=.75
	journal.detail=0
	journal.particles=false
	journal.apply_settings()
	check(is_equal_approx(root.scaling_3d_scale,.75) and root.mesh_lod_threshold==4,"graphics settings affect viewport")
	journal.save_progress()
	journal.render_scale=1
	journal.load_progress()
	check(is_equal_approx(journal.render_scale,.75),"graphics settings persist")
	journal.render_scale=1
	journal.particles=true
	journal.apply_settings()
	extras.close_menu()
	paused=false
	var session=main.get_node("OceanSession")
	gm.fever_left=10
	session._process(.1)
	check(session._fever_blend>0 and session._fever_blend<1,"gold effect fades in gradually")
	gm.fever_left=0
	gm.stun_left=2.5
	session._process(.1)
	check(session._stun_blend>0 and session._stun_blend<1,"puffer effect fades in gradually")
	gm.stun_left=0
	gm.slow_time_left=5
	check(is_equal_approx(gm.world_time_scale(),1),"oracle starts smoothly")
	gm.slow_time_left=4.5
	check(gm.world_time_scale()<.5,"oracle reaches slow motion")
	gm.slow_time_left=0
	gm.select_mode(0)
	var tutorial=main.get_node("ExpeditionTutorial")
	tutorial._process(.1)
	gm.advance_expedition(30)
	check(gm.expedition_left==300,"tutorial protects five minute expedition time")
	gm.waste_removed=1
	tutorial._process(.1)
	check(tutorial.step==1,"tutorial advances after actual cleanup")
	gm.robots_deployed=1
	tutorial._process(.1)
	check(tutorial.step==2 and not gm.tutorial_active,"two practical actions start the expedition immediately")
	var money_before: int = gm.coins
	tutorial._context(main.get_node("Cabin/ShopFlashlight"))
	check("LINTERNA" in tutorial._label.text,"flashlight hint describes the actual control")
	if DisplayServer.get_name() != "headless":
		tutorial._process(.1)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/tutorial-context.png")
	var disposable = Node3D.new()
	main.add_child(disposable)
	tutorial._hint("temporary", "test", disposable)
	disposable.free()
	tutorial._process(.1)
	check(not tutorial._ring.visible,"freed hint target safely removes highlight")
	check(gm.coins==money_before,"context hints never purchase upgrades")
	paused=true
	tutorial._process(.1)
	check(not tutorial.visible,"tutorial hides during pause")
	paused=false
	gm.waste_removed=gm.WASTE_GOAL
	for depth in [5,10,15,25]:
		gm.advance_expedition(60)
		check(gm.depth==depth and not gm.expedition_finished,"educational ecosystem "+str(depth))
	gm.advance_expedition(60)
	check(gm.expedition_finished and gm.expedition_success,"five minute journey ends after every ecosystem")
	print("RESEARCH FAILURES: ",failures)
	quit(failures)
