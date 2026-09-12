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
	var gm = root.get_node("GameManager")
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.5).timeout
	main.get_node("Spawner").set_process(false)
	var touch = main.get_node("HandTouchButtons")
	var net = main.get_node("OceanSession/ShopNet")
	check(net.position.x < -0.5 and main.get_node("Cabin/ShopFilter").position.x > 0.5,"shop sits on both sides, clear of alarm")
	check(net.has_node("ConsoleTrim"),"buttons have physical console trim")
	gm.coins = 500
	var start: int = gm.net_level
	touch.feed_tip("left",net.to_global(Vector3(0,0,0.02)))
	check(gm.net_level == start,"tracking appearing inside button cannot purchase")
	touch.feed_tip("left",net.to_global(Vector3(0,0,0.08)))
	touch.feed_tip("left",net.to_global(Vector3(0,0,0.02)))
	check(gm.net_level == start + 1,"front approach and index contact purchase once")
	for index in 10: touch.feed_tip("left",net.to_global(Vector3(0,0,0.01)))
	check(gm.net_level == start + 1,"held fingertip does not repeat purchase")
	touch.feed_tip("right",net.to_global(Vector3(0,0,0.08)))
	touch.feed_tip("right",net.to_global(Vector3(0,0,0.02)))
	main.get_node("XROrigin3D/RightController").activate_target(net)
	check(gm.net_level == start + 1,"two hands and ray cannot duplicate contact purchase")
	await create_timer(0.55).timeout
	touch.feed_tip("left",net.to_global(Vector3(0,0,0.08)))
	touch.feed_tip("left",net.to_global(Vector3(0,0,0.02)))
	check(gm.net_level == start + 2,"withdrawal rearms next intentional purchase")
	net.hide()
	touch.feed_tip("left",net.to_global(Vector3(0,0,0.08)))
	touch.feed_tip("left",net.to_global(Vector3(0,0,0.02)))
	check(gm.net_level == start + 2,"hidden buttons reject contact")
	net.show()
	var camera = main.get_node("XROrigin3D/XRCamera3D")
	camera.look_at(net.global_position,Vector3.UP)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/side-buttons.png")
	print("BUTTON FAILURES: ",failures)
	quit(failures)
