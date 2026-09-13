extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var gm=root.get_node("GameManager")
	gm.mode_selected=false
	var main=load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	main.get_node("Spawner").set_process(false)
	var session=main.get_node("OceanSession")
	check(not session._status.visible,"telemetry hidden immediately in mode selection")
	await process_frame
	check(not session._status.visible,"telemetry stays hidden before starting")
	gm.select_mode(1)
	gm.practice_mode=true
	await process_frame
	check(session._status.visible,"telemetry appears when game starts")
	var gauge=session._status.get_child(0)
	for value in [100,51,49,25,1,75]:
		gm.ocean_health=value
		gauge._process(2.0)
		check(absf(gauge._fill.scale.y-value/100.0)<.001,"fill tracks health "+str(value))
		check(absf(gauge._fill.position.y-.15*gauge._fill.scale.y+.15)<.001,"fill remains bottom anchored")
	check(gauge._fill_material.render_priority>gauge.get_child(1).material_override.render_priority,"fill always draws above track")
	if DisplayServer.get_name()!="headless":
		gm.ocean_health=25
		gauge._process(2)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/telemetry-low.png")
	print("TELEMETRY FAILURES: ",failures)
	quit(failures)
