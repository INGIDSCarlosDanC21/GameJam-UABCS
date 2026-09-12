extends "res://scripts/ShopItem.gd"
func _ready() -> void:
	item = Item.FILTER
	button_texture = preload("res://assets/ui/flashlight.svg")
	super._ready()
	_art.texture = button_texture
	_art.pixel_size = 0.115 / 128.0
	name = "ShopFlashlight"
	position = Vector3(0.58, 0.73, -0.26)
	basis = Basis.looking_at(position - Vector3(0, 1.45, 0), Vector3.UP)
func _refresh(coins: int) -> void:
	_label.text = "LINTERNA %d/5\n$%d" % [GameManager.flashlight_level, GameManager.flashlight_cost()]
	if GameManager.flashlight_level == 5: _label.text = "LINTERNA 5/5\nMÁXIMO"
	_panel.albedo_color = Color("14576c") if _hover else Color("102d43")
	if coins < GameManager.flashlight_cost(): _panel.albedo_color = Color("39404d")
func on_click() -> void:
	if get_tree().paused or Time.get_ticks_msec() - _last_activation < 450: return
	_last_activation = Time.get_ticks_msec()
	_press = 1.0
	_accepted = GameManager.buy_flashlight()
	if not _accepted: GameManager.sound_requested.emit("error")
	_refresh(GameManager.coins)
