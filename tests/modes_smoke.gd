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
	var gm = root.get_node("GameManager")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.6).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/mode-menu.png")
	check(main.has_node("ModeMenu") and get_nodes_in_group("entities").is_empty(), "selection prevents gameplay spawning")
	check(gm.expedition_left == 300, "selection does not consume time")
	main.get_node("ModeMenu").choose(1)
	await process_frame
	gm.advance_expedition(1000)
	check(not gm.is_run_over() and gm.expedition_left == 300, "arcade runs beyond five minutes")
	gm.waste_removed = 15
	gm.robots_deployed = 1
	gm.advance_expedition(60)
	check(not gm.expedition_finished, "arcade does not end on educational objectives")
	var session = main.get_node("OceanSession")
	session._depth_announcement(1)
	session._update_descent(0.7)
	check(session._submarine.transform != session._submarine_rest, "descent moves submarine model")
	session._update_descent(4)
	check(session._submarine.transform.is_equal_approx(session._submarine_rest), "submarine returns to exact rest transform")
	gm._set_health(0)
	check(gm.defeated, "arcade retains ecological defeat")
	gm.restart()
	await create_timer(0.5).timeout
	check(gm.play_mode == 1 and not current_scene.has_node("ModeMenu"), "restart preserves chosen mode")
	gm.select_mode(0)
	gm.advance_expedition(301)
	check(gm.expedition_finished, "educational mode retains deadline")
	print("MODE FAILURES: ", failures)
	quit(failures)
