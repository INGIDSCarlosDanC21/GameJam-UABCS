extends Area3D
enum Item { BAIT, FILTER }
@export var item: Item = Item.BAIT
@onready var _label: Label3D = $Label3D
var _panel: StandardMaterial3D
var _hover := false
var _feedback := 0.0
var _accepted := false

func _ready() -> void:
	position = Vector3(-0.5 if item == Item.BAIT else 0.5, 1.95, -1.5)
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
	box.size = Vector3(0.66, 0.3, 0.035)
	backing.mesh = box
	backing.material_override = _panel
	backing.position = _label.position + Vector3(0, 0, -0.03)
	add_child(backing)
	var border := MeshInstance3D.new()
	var outer := BoxMesh.new()
	outer.size = Vector3(0.69, 0.33, 0.03)
	border.mesh = outer
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("07121e")
	border.material_override = ink
	border.position = backing.position + Vector3(0, 0, -0.024)
	add_child(border)
	_label.font_size = 28
	_label.pixel_size = 0.001
	_label.outline_size = 3
	_label.modulate = Color("f2f8ff")
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.66, 0.3, 0.07)
	$CollisionShape3D.shape = shape
	GameManager.coins_changed.connect(_refresh)
	_refresh(GameManager.coins)

func set_hovered(value: bool) -> void:
	_hover = value
	_refresh(GameManager.coins)

func _process(delta: float) -> void:
	if _feedback > 0:
		_feedback -= delta
		if _feedback <= 0:
			_refresh(GameManager.coins)

func on_click() -> void:
	_accepted = GameManager.buy_bait() if item == Item.BAIT else GameManager.buy_filter()
	_feedback = 0.8
	_refresh(GameManager.coins)

func _refresh(coins: int) -> void:
	var price := GameManager.BAIT_COST if item == Item.BAIT else GameManager.FILTER_COST
	var title := "CEBO" if item == Item.BAIT else "FILTRO"
	var level := GameManager.bait_level if item == Item.BAIT else GameManager.filter_level
	var description := "+ Peces y recompensa" if item == Item.BAIT else "Reduce contaminación"
	_label.text = "%s  /  NIVEL %d\n%s\n%d MONEDAS" % [title, level, description, price]
	_panel.albedo_color = Color("14576c") if _hover else Color("102d43")
	if coins < price:
		_panel.albedo_color = Color("39404d")
	if _feedback > 0:
		_panel.albedo_color = Color("24795f") if _accepted else Color("8d3344")
		_label.text = "COMPRA REALIZADA" if _accepted else "FALTAN MONEDAS"
