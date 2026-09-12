extends Area3D
enum Item { BAIT, FILTER, DESCEND, RESTART, NET }
@export var button_texture: Texture2D
@export var filter_icons: Array[Texture2D]
@export var item: Item = Item.BAIT
@onready var _label: Label3D = $Label3D
var _panel: StandardMaterial3D
var _hover := false
var _feedback := 0.0
var _accepted := false
var _art: Sprite3D
var _visual: MeshInstance3D

func _ready() -> void:
	position = Vector3(-0.42 if item == Item.BAIT else 0.42, 0.82, -1.45)
	if item == Item.NET:
		position.x = 0.0
		button_texture = preload("res://assets/ui/net.svg")
	if item == Item.DESCEND: position = Vector3(0, 1.05, -1.7)
	if item == Item.RESTART: position = Vector3(0, 1.75, -2.0)
	if item in [Item.BAIT, Item.FILTER, Item.NET]:
		add_to_group("shop_items")
	_label.position = Vector3.ZERO
	$CollisionShape3D.position = Vector3.ZERO
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	_panel = StandardMaterial3D.new()
	_panel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var backing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.25, 0.65, 0.035) if item == Item.RESTART else Vector3(0.34, 0.36, 0.035)
	backing.mesh = box
	backing.material_override = _panel
	_visual = backing
	backing.position = _label.position + Vector3(0, 0, -0.03)
	add_child(backing)
	if button_texture or not filter_icons.is_empty():
		_art = Sprite3D.new()
		_art.position = Vector3(0, 0.05, 0.002)
		add_child(_art)
		_label.position.y = -0.13
	var border := MeshInstance3D.new()
	var outer := BoxMesh.new()
	outer.size = Vector3(1.28, 0.68, 0.03) if item == Item.RESTART else Vector3(0.37, 0.39, 0.03)
	border.mesh = outer
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("07121e")
	border.material_override = ink
	border.position = backing.position + Vector3(0, 0, -0.024)
	add_child(border)
	_label.font_size = 17
	_label.pixel_size = 0.0012
	_label.outline_size = 3
	_label.modulate = Color("f2f8ff")
	if item == Item.DESCEND:
		_label.font_size = 76
		_label.pixel_size = 0.0018
	if item == Item.RESTART:
		_label.font_size = 26
		_label.pixel_size = 0.0012
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.25, 0.65, 0.07) if item == Item.RESTART else Vector3(0.34, 0.36, 0.07)
	$CollisionShape3D.shape = shape
	GameManager.coins_changed.connect(_refresh)
	GameManager.level_changed.connect(func(_value: int): _refresh(GameManager.coins))
	_refresh(GameManager.coins)

func set_hovered(value: bool) -> void:
	if value and not _hover: GameManager.sound_requested.emit("touch")
	_hover = value
	_refresh(GameManager.coins)

func _process(delta: float) -> void:
	_visual.position.z = lerpf(_visual.position.z, -0.019 if _hover else -0.03, 1.0 - exp(-14.0 * delta))
	if _feedback > 0:
		_feedback -= delta
		if _feedback <= 0:
			_refresh(GameManager.coins)

func on_click() -> void:
	if item == Item.RESTART:
		GameManager.restart.call_deferred()
		return
	if item == Item.DESCEND:
		GameManager.descend()
		return
	_accepted = GameManager.buy_net() if item == Item.NET else (GameManager.buy_bait() if item == Item.BAIT else GameManager.buy_filter())
	GameManager.sound_requested.emit("success" if _accepted else "error")
	_feedback = 0.8
	_refresh(GameManager.coins)

func _refresh(coins: int) -> void:
	if item in [Item.DESCEND, Item.RESTART]:
		if _label.text.is_empty():
			_label.text = "DESCENDER\nCada 5 niveles" if item == Item.DESCEND else "OCÉANO AGOTADO\nREINICIAR PARTIDA"
		_panel.albedo_color = Color("286d82") if _hover else Color("102d43")
		return
	var price := GameManager.BAIT_COST if item == Item.BAIT else GameManager.filter_cost()
	if item == Item.NET: price = GameManager.net_cost()
	var title := "CEBO" if item == Item.BAIT else "FILTROBOT"
	var level := GameManager.bait_level if item == Item.BAIT else GameManager.cleaner_quality()
	if item == Item.NET:
		title = "RED"
		level = GameManager.net_level
	_label.text = "%s %d · $%d" % [title, level, price]
	if item == Item.NET and level == GameManager.MAX_NET_LEVEL: _label.text = "RED 5 · MAX"
	if is_instance_valid(_art):
		var icon := button_texture
		if item == Item.FILTER and not filter_icons.is_empty():
			icon = filter_icons[mini(GameManager.cleaner_quality() - 1, filter_icons.size() - 1)]
		if icon:
			if _art.texture != icon:
				_art.texture = icon
				var bounds := icon.get_image().get_used_rect()
				_art.region_enabled = true
				_art.region_rect = Rect2(bounds)
				_art.pixel_size = 0.16 / maxi(1, maxi(bounds.size.x, bounds.size.y))
	_panel.albedo_color = Color("14576c") if _hover else Color("102d43")
	if coins < price:
		_panel.albedo_color = Color("39404d")
	if _feedback > 0:
		_panel.albedo_color = Color("24795f") if _accepted else Color("8d3344")
