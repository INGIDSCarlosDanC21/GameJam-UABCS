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
	_base_y = position.y
	_base_z = position.z
	capture_time = (0.35 + rarity * 0.14 + (size_factor - 0.75) * 0.2) if kind == Kind.FISH else 0.25
	lifetime = 6.0 / speed


func setup(p_kind: Kind, p_dir: float) -> void:
	kind = p_kind
	direction = p_dir
	if is_node_ready():
		_apply_placeholder()


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	position.y = _base_y + sin(_age * (2.0 + rarity * 0.5) + _phase) * (0.06 + rarity * 0.025)
	position.z = _base_z + sin(_age * 0.7 + _phase) * 0.16
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
var capture_time: float = 0.3
var _base_y: float
var _base_z: float
var _phase: float = randf() * TAU

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
func get_stats_text() -> String:
	if kind == Kind.TRASH:
		return "%s | +5 monedas\nLimpieza %.2f s" % [species.capitalize(), capture_time]
	var stats := GameManager.fish_stats(rarity, size_factor)
	return "%s | %s\n+%d monedas / -%.1f salud\n%.2f m/s | agarre %.2f s | %.1f m" % [species.capitalize(), ["Común", "Especial", "Raro", "Legendario"][rarity], stats.reward, stats.damage, speed, capture_time, absf(position.z)]