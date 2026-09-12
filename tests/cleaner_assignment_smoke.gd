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
	var robots: Array[Node3D] = []
	for index in 3:
		var robot := Node3D.new()
		robot.set_script(load("res://scripts/ReefCleaner.gd"))
		main.add_child(robot)
		robot.set_physics_process(false)
		robots.append(robot)
	var trash = load("res://scenes/InteractableEntity.tscn").instantiate()
	trash.kind = 1
	trash.species = "lata"
	trash.position = Vector3(0, 1.5, -4)
	main.add_child(trash)
	trash.set_physics_process(false)
	for robot in robots: robot._find_target()
	check(robots[0]._target == trash and robots[1]._target == null and robots[2]._target == null, "one residue has exactly one assigned robot")
	check(robots[0]._patrol_phase != robots[1]._patrol_phase and robots[0]._patrol_direction != robots[1]._patrol_direction, "idle patrols have distinct phase and direction")
	robots[0].paralyze(5.0)
	robots[1]._find_target()
	check(robots[0]._target == null and robots[1]._target == trash, "paralysis releases assignment for another robot")
	robots[1].free()
	robots[2]._find_target()
	check(robots[2]._target == trash, "deleted robot leaves no stale reservation")
	trash.queue_free()
	robots[2]._physics_process(0.016)
	check(robots[2]._target == null, "player removal invalidates robot target")
	print("ASSIGNMENT FAILURES: ", failures)
	quit(failures)
