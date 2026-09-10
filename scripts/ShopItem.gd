extends Area3D
## Botón de tienda flotante (Cebo / Filtro). Misma capa fantasma que las entidades.

enum Item { BAIT, FILTER }

const LAYER_INTERACTABLE := 2

@export var item: Item = Item.BAIT

@onready var _label: Label3D = $Label3D


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true
	_refresh_label()
	GameManager.coins_changed.connect(_on_coins)


func on_click() -> void:
	var ok := false
	match item:
		Item.BAIT:
			ok = GameManager.buy_bait()
		Item.FILTER:
			ok = GameManager.buy_filter()
	_refresh_label()
	if ok and _label:
		_label.modulate = Color(0.5, 1.0, 0.55)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(_label):
			_label.modulate = Color.WHITE


func _on_coins(_v: int) -> void:
	_refresh_label()


func _refresh_label() -> void:
	if _label == null:
		return
	match item:
		Item.BAIT:
			_label.text = "Comprar Cebo\n%d c  |  nv %d" % [GameManager.BAIT_COST, GameManager.bait_level]
		Item.FILTER:
			_label.text = "Comprar Filtro\n%d c  |  nv %d" % [GameManager.FILTER_COST, GameManager.filter_level]
