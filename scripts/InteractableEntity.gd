extends Area3D
## Entidad fantasma: no colisiona con otras entidades, solo es detectable por el RayCast.

enum Kind { FISH, TRASH }

const LAYER_INTERACTABLE := 2

@export var kind: Kind = Kind.FISH
@export var speed: float = 0.55
@export var lifetime: float = 9.0

var direction: float = 1.0
var _age: float = 0.0
var _clicked: bool = false

@onready var _sprite: Sprite3D = $Sprite3D


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true
	_apply_placeholder()


func setup(p_kind: Kind, p_dir: float) -> void:
	kind = p_kind
	direction = p_dir
	if is_node_ready():
		_apply_placeholder()


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	position.y += sin(Time.get_ticks_msec() * 0.004 + position.z) * 0.12 * delta
	_age += delta
	if _age >= lifetime:
		_expire()


func on_click() -> void:
	if _clicked:
		return
	_clicked = true
	match kind:
		Kind.FISH:
			GameManager.catch_fish()
		Kind.TRASH:
			GameManager.clean_trash()
	queue_free()


func _expire() -> void:
	if _clicked:
		return
	match kind:
		Kind.FISH:
			GameManager.let_fish_go()
		Kind.TRASH:
			GameManager.ignore_trash()
	queue_free()


func _apply_placeholder() -> void:
	if _sprite == null:
		return
	var color := Color(0.25, 0.75, 1.0) if kind == Kind.FISH else Color(0.82, 0.38, 0.12)
	_sprite.texture = _make_block_texture(color, kind == Kind.FISH)
	_sprite.pixel_size = 0.004
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED


func _make_block_texture(color: Color, is_fish: bool) -> Texture2D:
	var w := 64 if is_fish else 48
	var h := 32 if is_fish else 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var edge := x > 2 and x < w - 3 and y > 2 and y < h - 3
			if edge:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
