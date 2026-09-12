extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var gm = root.get_node("GameManager")
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var button = main.get_node("Cabin/PauseButton")
	var pointer = main.get_node("XROrigin3D/RightController")
	button.on_click()
	assert(paused)
	var coins: int = gm.coins
	pointer.activate_target(main.get_node("Cabin/ShopBait"))
	assert(gm.coins == coins)
	assert(button.can_process() and pointer.can_process())
	assert(button.position.distance_to(main.get_node("Cabin/ShopFilter").position) > 0.4)
	button._last_press = -1000
	pointer.activate_target(button)
	assert(not paused)
	print("PASS: pause blocks purchases, keeps resume responsive and clears filter button")
	quit()
