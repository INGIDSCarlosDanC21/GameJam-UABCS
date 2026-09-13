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
	root.get_node("GameManager").select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("Spawner").set_process(false)
	for pointer in get_nodes_in_group("xr_pointers"): pointer.set_physics_process(false)
	var camera = main.get_node("XROrigin3D/XRCamera3D")
	var filter = main.get_node("Cabin/ShopFilter")
	var wallet = main.get_node("Cabin/WalletPanel")
	camera.look_at(filter.global_position, Vector3.UP)
	await create_timer(0.3).timeout
	check(wallet.visible and wallet.global_position.x > 0.3, "gaze shows wallet beside Filtrobot on right")
	camera.rotation = Vector3.ZERO
	await create_timer(0.26).timeout
	camera.look_at(filter.global_position, Vector3.UP)
	await create_timer(0.3).timeout
	check(wallet.visible, "returning gaze cancels pending hide")
	var jelly = Area3D.new()
	jelly.set_script(load("res://scripts/Hostile.gd"))
	jelly.jellyfish = true
	main.add_child(jelly)
	jelly.set_physics_process(false)
	jelly._physics_process(0.0)
	var before: Vector3 = jelly.global_position
	camera.rotation.y += 1.0
	jelly._physics_process(0.0)
	check(jelly.global_position.is_equal_approx(before), "jellyfish position independent of head rotation")
	for species in ["pez azul", "pulpo", "botella"]:
		var entity = load("res://scenes/InteractableEntity.tscn").instantiate()
		entity.species = species
		entity.kind = 1 if species == "botella" else 0
		entity.position = Vector3(-2.8, 1.5, -15)
		entity.entry_target_z = -3.6
		main.add_child(entity)
		entity.set_physics_process(false)
		check(entity.collision_layer == 0, species + " arrives without invisible collider")
		entity._physics_process(2.0)
		check(entity.position.z < -3.6 and is_equal_approx(entity.position.y, 1.5), species + " shares gradual entry")
		entity._physics_process(2.6)
		check(entity.collision_layer == 2 and absf(entity.position.z + 3.6) < 0.3, species + " becomes playable in lane")
		entity.queue_free()
	print("QOL FAILURES: ", failures)
	quit(failures)
