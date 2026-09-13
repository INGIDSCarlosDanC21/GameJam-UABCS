extends SceneTree
var failures := 0
func check(ok: bool,message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok: failures+=1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var gm = root.get_node("GameManager")
	gm.select_mode(1)
	var main=load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	# Hidden test windows must keep simulating after the OS removes focus.
	var desktop = main.get_node_or_null("DesktopPlayer")
	if desktop:
		desktop._enabled = false
		desktop._focus_paused = false
		desktop._pause_label.hide()
	paused = false
	main.get_node("XROrigin3D/XRCamera3D").rotation = Vector3.ZERO
	var spawner=main.get_node("Spawner")
	spawner.set_process(false)
	await process_frame
	var octopus=load("res://scenes/InteractableEntity.tscn").instantiate()
	octopus.species="pulpo"
	main.add_child(octopus)
	var scale_before: float=octopus._sprite.pixel_size
	var shape=octopus.get_node("CollisionShape3D").shape
	octopus._apply_art("res://assets/art/pulpo nadando 2.png")
	check(is_equal_approx(scale_before,octopus._sprite.pixel_size),"octopus frames retain drawing scale")
	check(shape==octopus.get_node("CollisionShape3D").shape,"octopus animation reuses collision shape")
	check(octopus._material.get_shader_parameter("pattern_strength")>0,"octopus has procedural coloration")
	var jelly:=Area3D.new()
	jelly.set_script(load("res://scripts/Hostile.gd"))
	jelly.jellyfish=true
	main.add_child(jelly)
	check(jelly._sprite.material_override is ShaderMaterial,"jellyfish uses procedural coloration")
	spawner._spawn(true)
	var trash=spawner.get_child(spawner.get_child_count()-1)
	check(trash.entry_target_z in spawner.ENTRY_DEPTHS and trash.position.y>2,"trash enters above fish in shared depth lanes")
	gm.depth=20
	gm.level=101
	gm.practice_mode=true
	for index in 100: spawner._spawn(index%2==0)
	check(get_nodes_in_group("entities").size()<=42 and get_nodes_in_group("trash").size()<=14,"late game population remains bounded")
	if DisplayServer.get_name()!="headless":
		# Separate the deliberate mass-instantiation frame from steady-state load.
		await process_frame
		await process_frame
		var samples: Array[float]=[]
		for index in 180:
			var start:=Time.get_ticks_usec()
			await process_frame
			samples.append((Time.get_ticks_usec()-start)/1000.0)
		samples.sort()
		print("20 km stress frame ms median=",samples[90]," p95=",samples[171]," max=",samples[-1])
		check(not paused and octopus._age > 0, "stress measurement includes active simulation")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/performance-preview.png")
	print("PERFORMANCE ART FAILURES: ",failures)
	quit(failures)
