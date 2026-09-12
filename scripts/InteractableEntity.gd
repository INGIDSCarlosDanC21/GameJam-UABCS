extends Area3D
enum Kind { FISH, TRASH, SEAL }
const FISH_ART := ["pez azul", "pez naranja", "anginla", "pez dorado millonario"]
const TRASH_ART := ["botella rota inferiror", "botella rota superior", "lata", "monton de basura", "soporte de cerveza"]
const INK = preload("res://shaders/sprite_ink.gdshader")
static var art_cache: Dictionary = {}
@export var kind: Kind = Kind.FISH
@export var speed := 0.25
@export var lifetime := 22.0
@export var noapto_texture: Texture2D
var direction := 1.0
var rarity := 0
var size_factor := 1.0
var aura := 0
var _halo: MeshInstance3D
var species := ""
var capture_time := 0.18
var unsuitable := false
var angry := false
var _clicked := false
var _age := 0.0
var _sink_age := 0.0
var _base_y := 0.0
var _base_z := 0.0
var _phase := randf() * TAU
var _rage_timer := 0.0
var _local_light: OmniLight3D
var _exit_age := -1.0
var _exit_start := Vector3.ZERO
var _notifier: VisibleOnScreenNotifier3D
var _material: ShaderMaterial
@export_range(0.0, 0.12) var body_bend := 0.045
var _turn_wait := randf_range(4.0, 8.0)
var _oracle_badge: Sprite3D
@onready var _sprite: Sprite3D = $Sprite3D

func setup(value: Kind, dir: float) -> void:
	kind = value
	direction = dir

func _ready() -> void:
	add_to_group("entities")
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	if kind == Kind.FISH:
		add_to_group("fish")
		if species.is_empty():
			var r := randf()
			species = "pez oracles" if GameManager.depth > 0 and r < 0.03 else ("pez azul" if r < 0.45 else ("pez naranja" if r < 0.8 else ("anginla" if r < 0.995 else "pez dorado millonario")))
			if GameManager.depth > 0 and randf() < 0.15: species = "pez linterna"
		rarity = 3 if "dorado" in species else (1 if "anginla" in species or "linterna" in species else 0)
		size_factor = [0.9, 1.1, 1.4].pick_random() * minf(1.55, 1.0 + GameManager.depth * 0.10)
		aura = randi_range(1, 3) if randf() < minf(0.65, 0.18 + GameManager.depth * 0.08) else 0
		speed = (0.32 if "anginla" in species else 0.23) * GameManager.difficulty()
	elif kind == Kind.TRASH:
		add_to_group("trash")
		if species.is_empty(): species = TRASH_ART.pick_random()
		speed = 0.18
		# Each discarded object keeps a distinct silhouette as it crosses the viewport.
		_sprite.rotation.z = randf_range(-PI, PI)
	else:
		species = "foca"
		speed = 0.2
	capture_time = 0.22 + rarity * 0.035 + aura * 0.17 + maxf(0, size_factor - 1) * 0.1
	_base_y = position.y
	_base_z = position.z
	lifetime = 12.0 if kind == Kind.TRASH else 6.3 / maxf(speed, 0.1)
	_material = ShaderMaterial.new()
	_material.shader = INK
	_sprite.material_override = _material
	_apply_art(_texture_path(species))
	if "oracles" in species:
		_oracle_badge = Sprite3D.new()
		_oracle_badge.texture = preload("res://assets/ui/slow_clock.svg")
		_oracle_badge.pixel_size = 0.0011
		_oracle_badge.position = Vector3(0, 0.20, 0.04)
		add_child(_oracle_badge)
	if kind != Kind.TRASH: _sprite.rotation.y = 0.0 if direction > 0 else PI
	if aura > 0:
		_halo = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * 0.48 * size_factor
		_halo.mesh = quad
		var halo_mat := ShaderMaterial.new()
		halo_mat.shader = preload("res://shaders/aura.gdshader")
		halo_mat.set_shader_parameter("gold", float(aura) / 3.0)
		_halo.material_override = halo_mat
		_halo.position.z = -0.03
		add_child(_halo)
	_notifier = VisibleOnScreenNotifier3D.new()
	add_child(_notifier)
	if "linterna" in species or "anginla" in species:
		var light := OmniLight3D.new()
		_local_light = light
		light.visible = "linterna" in species
		light.light_color = Color("fff0a6")
		light.light_energy = 2.8
		light.omni_range = 2.2
		light.position = Vector3(0.16, 0.1, 0.2)
		add_child(light)

func _texture_path(name_text: String) -> String:
	var path := "res://assets/art/" + name_text + ".png"
	return path if ResourceLoader.exists(path) else "res://assets/art/pez azul.png"

func _apply_art(path: String, replacement: Texture2D = null) -> void:
	var texture: Texture2D = replacement if replacement else load(path) as Texture2D
	if not texture: return
	var key := texture.get_instance_id()
	if not art_cache.has(key): art_cache[key] = texture.get_image().get_used_rect()
	var bounds: Rect2i = art_cache[key]
	_sprite.texture = texture
	_sprite.region_enabled = true
	var padding := maxi(5, ceili(bounds.size.y * 0.12)) if kind == Kind.FISH else 5
	_sprite.region_rect = Rect2(bounds.grow(padding).intersection(Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))))
	var width := (0.4 if "anginla" in species else 0.25) * size_factor
	_sprite.pixel_size = width / maxi(1, bounds.size.x)
	_sprite.flip_h = false
	_material.set_shader_parameter("art_rect", Vector4(float(bounds.position.x) / texture.get_width(), float(bounds.position.y) / texture.get_height(), float(bounds.size.x) / texture.get_width(), float(bounds.size.y) / texture.get_height()))
	_material.set_shader_parameter("art", texture)
	_material.set_shader_parameter("texel", Vector2.ONE / texture.get_size())
	_material.set_shader_parameter("glow_color", Color(1, 0.7, 0.15, 0.2) if rarity == 3 else Color(0, 0, 0, 0))
	var box := BoxShape3D.new()
	box.size = Vector3(width + 0.08, bounds.size.y * _sprite.pixel_size + 0.08, 0.14)
	$CollisionShape3D.shape = box

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over(): return
	delta *= GameManager.world_time_scale()
	_age += delta
	_animate_swimming(delta)
	if _exit_age >= 0:
		_exit_age += delta
		var t := _exit_age
		position = _exit_start + Vector3(direction * sin(t) * 1.8, sin(t * 0.8) * 0.4, -t * t * 2.0)
		rotation.y = -direction * minf(t, PI * 0.45)
		_material.set_shader_parameter("fade", maxf(0, 1.0 - t / 2.5))
		if t > 2.5: _finish_exit()
		return
	if unsuitable:
		position.y -= 0.24 * delta
		position.x += direction * 0.04 * delta
		_sink_age += delta
		if (_sink_age > 1 and not _notifier.is_on_screen()) or _sink_age > 12: queue_free()
		return
	if kind != Kind.TRASH and _age < 0.8:
		rotation.y = direction * (1.0 - _age / 0.8) * 1.1
		_material.set_shader_parameter("fade", _age / 0.8)
	else:
		rotation.y = 0
		_material.set_shader_parameter("fade", 1.0)
	var fever := GameManager.fever_left > 0 and kind == Kind.FISH
	if kind == Kind.TRASH and species.begins_with("botella"):
		position.y -= (0.4 + GameManager.depth * 0.06) * delta
		if position.y < -0.5: _expire()
		return
	position.x += direction * speed * (5.5 if fever else 1.0) * delta
	position.y = _base_y + (2.0 / PI) * asin(sin(_age * (2.8 + GameManager.depth * 0.25) + _phase)) * (0.22 if kind == Kind.FISH else 0.04)
	position.z = _base_z + sin(_age * 1.5 + _phase) * (0.2 if kind == Kind.FISH else 0.04)
	if angry:
		_rage_timer -= delta
		if _rage_timer <= 0:
			_rage_timer = 0.3
			for fish in get_tree().get_nodes_in_group("fish"):
				if fish != self and is_instance_valid(fish) and global_position.distance_to(fish.global_position) < 0.85:
					fish.make_unsuitable()
	if _age > lifetime or absf(position.x) > 3.1:
		if kind == Kind.TRASH: _expire()
		else:
			_exit_age = 0
			_exit_start = position

func _animate_swimming(delta: float) -> void:
	if kind == Kind.TRASH: return
	var swimming := kind == Kind.FISH and not unsuitable
	_material.set_shader_parameter("swim_time", _age * (9.0 if angry else 5.5) + _phase)
	_material.set_shader_parameter("bend_strength", body_bend * (1.65 if "anginla" in species else 1.0) if swimming else 0.0)
	var tilt := sin(_age * 2.8 + _phase) * 0.12 if not unsuitable else -0.25 * direction
	_sprite.rotation.z = lerp_angle(_sprite.rotation.z, tilt, 1.0 - exp(-delta * 5.0))
	_sprite.rotation.y = lerp_angle(_sprite.rotation.y, 0.0 if direction > 0 else PI, 1.0 - exp(-delta * 5.0))
	if not swimming or _exit_age >= 0 or GameManager.fever_left > 0: return
	_turn_wait -= delta
	if _turn_wait <= 0:
		_turn_wait = randf_range(4.0, 8.0)
		if absf(position.x) < 2.5 and randf() < 0.6: direction *= -1.0

func on_target_pressed() -> void:
	if "anginla" in species and not unsuitable and not GameManager.is_run_over():
		angry = true
		if _local_light: _local_light.show()
		_apply_art(_texture_path("anginla enojada"))

func on_click() -> void:
	if _clicked or unsuitable or GameManager.is_run_over(): return
	if "anginla" in species:
		on_target_pressed()
		return
	_clicked = true
	if kind == Kind.SEAL: GameManager.start_fever()
	elif "oracles" in species:
		GameManager.start_slow_time()
	elif kind == Kind.TRASH: GameManager.clean_trash()
	else:
		var reward := GameManager.fish_stats(rarity, size_factor, aura)
		GameManager.coin_requested.emit(global_position, reward.reward)
		GameManager.catch_fish(rarity, size_factor, aura)
	queue_free()

func make_unsuitable() -> void:
	if unsuitable or _clicked or kind != Kind.FISH: return
	unsuitable = true
	if is_instance_valid(_oracle_badge): _oracle_badge.hide()
	_exit_age = -1
	if _local_light: _local_light.hide()
	if "linterna" in species: GameManager.sound_requested.emit("lantern_out")
	if _halo: _halo.hide()
	collision_layer = 0
	remove_from_group("interactable")
	var found := false
	if species == "anginla": noapto_texture = load("res://assets/art/anginla noapta.png")
	if species == "pez dorado millonario": noapto_texture = load("res://assets/art/pez dorado noapto.png")
	if species == "pez oracles": noapto_texture = load("res://assets/art/oracles noapto.png")
	if noapto_texture:
		_apply_art("", noapto_texture)
		found = true
	else:
		for suffix in [" noapto", "noapto", "_noapto"]:
			var path: String = "res://assets/art/" + species + suffix + ".png"
			if ResourceLoader.exists(path):
				_apply_art(path)
				found = true
				break
	if not found: _material.set_shader_parameter("tint", Color(0.4, 0.48, 0.48))
	var tag := Label3D.new()
	tag.text = "NO APTO"
	tag.font_size = 24
	tag.pixel_size = 0.002
	tag.position.y = 0.25
	add_child(tag)

func collect_by_robot() -> bool:
	if kind != Kind.TRASH or _clicked or GameManager.is_run_over(): return false
	_clicked = true
	GameManager.clean_trash(false)
	queue_free()
	return true

func _expire() -> void:
	if _clicked: return
	_clicked = true
	if kind == Kind.TRASH: GameManager.ignore_trash()
	elif kind == Kind.FISH and not angry: GameManager.let_fish_go()
	queue_free()

func _finish_exit() -> void:
	_expire()

func get_stats_text() -> String:
	if kind == Kind.SEAL: return "FOCA / POWER UP\nFiebre de peces: 10 segundos"
	if kind == Kind.TRASH: return "%s / +5 monedas\nLimpia para proteger a los peces" % species.capitalize()
	if "oracles" in species: return "◷ 5 s"
	if "anginla" in species: return "ANGUILA / No molestar\nAl tocarla contamina peces cercanos"
	var stats := GameManager.fish_stats(rarity, size_factor, aura)
	return "+$%d  ·  −%.1f%%" % [stats.reward, stats.damage]
