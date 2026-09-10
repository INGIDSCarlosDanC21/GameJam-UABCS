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
			GameManager.catch_fish(rarity, size_factor)
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


const FISH_ART := ["pez azul", "pez naranja", "anginla", "anginla enojada", "pez dorado millonario"]
const FISH_WEIGHTS := [40, 30, 18, 10, 2]
const TRASH_ART := ["botella rota inferiror", "botella rota superior", "lata", "monton de basura", "soporte de cerveza"]
const INK = preload("res://shaders/sprite_ink.gdshader")
static var art_cache: Dictionary = {}
var rarity: int = 0
var size_factor: float = 1.0
var species: String = ""

func _apply_placeholder() -> void:
	if species.is_empty():
		if kind == Kind.FISH:
			var roll := randi_range(1, 100)
			var index := 0
			while roll > FISH_WEIGHTS[index]:
				roll -= FISH_WEIGHTS[index]
				index += 1
			species = FISH_ART[index]
			rarity = [0, 0, 1, 2, 3][index]
			speed = [0.55, 0.6, 0.7, 0.9, 0.4][index]
			size_factor = [0.75, 1.0, 1.5].pick_random()
		else:
			species = TRASH_ART.pick_random()
			speed = 0.35
			add_to_group("trash")
	var path := "res://assets/art/" + species + ".png"
	if not art_cache.has(path):
		var texture := load(path) as Texture2D
		var bounds := texture.get_image().get_used_rect()
		art_cache[path] = [texture, bounds]
	var texture: Texture2D = art_cache[path][0]
	var bounds: Rect2i = art_cache[path][1]
	_sprite.texture = texture
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(bounds.grow(5).intersection(Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))))
	var width := (0.65 if species.begins_with("anginla") else 0.38) * size_factor
	if species == "monton de basura":
		width = 0.6
	_sprite.pixel_size = width / float(maxi(bounds.size.x, 1))
	_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sprite.flip_h = kind == Kind.FISH and direction < 0.0
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	var mat := ShaderMaterial.new()
	mat.shader = INK
	mat.set_shader_parameter("art", texture)
	mat.set_shader_parameter("texel", Vector2.ONE / texture.get_size())
	var colors := [Color(0, 0, 0, 0), Color(0.2, 0.8, 1, 0.15), Color(0.8, 0.3, 1, 0.25), Color(1, 0.75, 0.1, 0.4)]
	mat.set_shader_parameter("glow_color", colors[rarity])
	_sprite.material_override = mat
	var box := BoxShape3D.new()
	box.size = Vector3(width, bounds.size.y * _sprite.pixel_size, 0.08)
	$CollisionShape3D.shape = box