extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var gm=root.get_node("GameManager")
	gm.select_mode(1)
	var main=load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	main.get_node("Spawner").set_process(false)
	await process_frame
	gm.set_process(false)
	var fauna=main.get_node("OceanWorld/DepthFauna")
	fauna.set_process(false)
	gm.depth=20
	fauna._process(.1)
	check(fauna._encounter_voice.stream.resource_path.ends_with("whale_song.ogg"),"whale has whale song")
	gm.depth=5
	fauna._process(.1)
	check(fauna._encounter_voice.stream.resource_path.ends_with("dolphin_cry.ogg"),"dolphin has dolphin vocalization")
	gm.depth=15
	fauna._process(.1)
	fauna._encounter_time=11.5
	fauna._process(0)
	check(fauna._special.position.z+fauna._special_half_depth<=-15,"giant octopus stays in background")
	var glow: OmniLight3D=fauna._colonies[0].get_children().filter(func(child): return child is OmniLight3D)[0]
	check(glow.top_level and glow.global_basis.get_scale().is_equal_approx(Vector3.ONE),"jelly light range independent of small model scale")
	check(glow.global_position.is_equal_approx(fauna._colonies[0].global_position),"jelly light follows animal")
	check(fauna._lanterns[0].get_children().any(func(child): return child is OmniLight3D and child.light_energy>0),"lantern illuminates nearby environment")
	gm.depth=10
	for index in 6:
		var trash=load("res://scenes/InteractableEntity.tscn").instantiate()
		trash.kind=1
		main.add_child(trash)
		trash.set_physics_process(false)
		trash._age=10
		trash.collision_layer=2
	gm.ocean_health=100
	for index in 10: gm._process(2.0)
	check(gm.ocean_health<50,"neglecting six active residues creates danger in twenty seconds")
	var injured: float=gm.ocean_health
	gm.clean_trash(false)
	check(gm.ocean_health-injured<1.2,"robot recovery no longer cancels pollution")
	var before_manual: float=gm.ocean_health
	gm.clean_trash(true)
	check(gm.ocean_health-before_manual>=3.5,"manual cleanup offers meaningful recovery")
	gm.recovery_left=6.5
	var protected: float=gm.ocean_health
	gm._process(2.0)
	check(gm.ocean_health==protected,"paralysis recovery grace still protects player")
	var session=main.get_node("OceanSession")
	check(not glow in session._lights,"depth dimming does not extinguish bioluminescence")
	session._process(.1)
	var head=root.get_camera_3d()
	check(head.to_local(session._status.global_position).y<0,"telemetry is below eye level")
	if DisplayServer.get_name()!="headless":
		gm.ocean_health=100
		gm.depth=15
		gm.level=76
		gm.practice_mode=true
		fauna._process(.1)
		fauna._encounter_time=11.5
		fauna._process(0)
		await create_timer(1).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/ecology-hud.png")
	print("ECOLOGY FAILURES: ",failures)
	quit(failures)
