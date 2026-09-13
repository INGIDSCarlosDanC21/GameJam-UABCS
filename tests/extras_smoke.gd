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
	var journal = root.get_node("PlayerJournal")
	journal.save_path = "user://extras_smoke.cfg"
	journal.species.clear()
	journal.best_depth = 0
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("Spawner").set_process(false)
	var extras = main.get_node("ExpeditionExtras")
	check(journal.discover("pez azul") and not journal.discover("pez azul"), "discovery is unique")
	gm.depth = 4
	journal.update_records()
	journal.music = 0.4
	journal.save_progress()
	journal.music = 1.0
	journal.load_progress()
	check(is_equal_approx(journal.music, 0.4) and journal.best_depth == 4 and "pez azul" in journal.species, "records and settings survive reload")
	gm.waste_removed = 5
	var coins: int = gm.coins
	extras._update_objective(0.1)
	extras._update_objective(0.1)
	check(gm.coins == coins + 50, "objective reward paid only once")
	var pointer = main.get_node("XROrigin3D/RightController")
	extras.open_menu()
	check(paused and extras._panel.visible, "journal opens in pause")
	journal.effects = 0.8
	journal.apply_settings()
	var sound = main.get_node("SoundHub")
	sound.play_event("success")
	check(sound._ui_voices[0].playing and not sound._ui_voices[0].stream_paused, "menu effects play while paused")
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) > -3.0, "effects bus audible at eighty percent")
	var camera = root.get_camera_3d()
	check(extras._panel.global_position.distance_to(camera.to_global(Vector3(0, 0, -1.4))) < 0.001, "menu centered in front of camera")
	var tab: Node3D
	for child in extras._panel.get_children():
		if child is Area3D: tab = child; break
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, tab.global_position, 4)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	await physics_frame
	var hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider == tab, "menu buttons reachable on dedicated pointer layer")
	pointer._process(0.01)
	check(pointer._cursor_material.no_depth_test and pointer._cursor_material.render_priority > 23, "cursor renders above menu")
	for page in ["Almanaque", "Récords", "Ajustes", "Práctica"]:
		extras._page = page
		extras._render_page()
		check(not extras._content.text.is_empty(), "page renders " + page)
	if DisplayServer.get_name() != "headless":
		extras._page = "Ajustes"
		extras._render_page()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/extras-settings.png")
	extras._practice_depth = 20
	extras._start_practice()
	check(gm.practice_mode and gm.depth == 20 and not paused, "practice applies selected depth")
	gm._set_health(10)
	check(gm.ocean_health == 100, "practice protects health")
	check(not journal.discover("ballena"), "practice cannot unlock permanent species")
	journal.update_records()
	check(journal.best_depth == 4, "practice cannot overwrite records")
	extras._event("storm")
	check(gm.storm_left == 12, "practice can trigger storm")
	print("EXTRAS FAILURES: ", failures)
	quit(failures)
