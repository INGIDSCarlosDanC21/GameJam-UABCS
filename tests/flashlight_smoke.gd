extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var gm = root.get_node("GameManager")
	gm.select_mode(1)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	gm.coins = 20000
	for level in 5:
		assert(gm.buy_flashlight())
		assert(gm.flashlight_level == level + 1)
	var coins: int = gm.coins
	assert(not gm.buy_flashlight() and gm.coins == coins)
	var shop = main.get_node("Cabin/ShopFlashlight")
	assert(shop.position.y < main.get_node("Cabin/ShopFilter").position.y - 0.2)
	var director = load("res://scripts/AudioDirector.gd")
	for title in director.SHALLOW + director.DEEP:
		var stream = load("res://assets/audio/depth/" + title + ".mp3")
		assert(stream.get_length() > 30.0)
	await process_frame
	print("PASS: five upgrades, price cap, button position and six decoded music tracks")
	quit()
