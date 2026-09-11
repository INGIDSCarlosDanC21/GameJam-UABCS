extends Node3D
var _buttons: Array[Area3D] = []
func _ready() -> void:
	name = "ModeMenu"
	for shop in get_tree().get_nodes_in_group("shop_items"):
		shop.hide()
		shop.collision_layer = 0
	var title := Label3D.new()
	title.text = "OCEAN VR\nELIGE TU EXPEDICIÓN"
	title.position = Vector3(0, 2.0, -1.7)
	title.font_size = 32
	title.pixel_size = 0.0015
	add_child(title)
	for mode in 2:
		var button := Area3D.new()
		button.set_script(preload("res://scripts/ModeButton.gd"))
		button.mode = mode
		button.position = Vector3(-0.43 if mode == 0 else 0.43, 1.5, -1.7)
		add_child(button)
		_buttons.append(button)

func choose(mode: int) -> void:
	if GameManager.mode_selected: return
	GameManager.select_mode(mode)
	for button in _buttons: button.collision_layer = 0
	for shop in get_tree().get_nodes_in_group("shop_items"):
		shop.show()
		shop.collision_layer = 2
	GameManager.sound_requested.emit("success")
	queue_free()
