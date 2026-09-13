extends Area3D
enum Kind { FISH, TRASH, SEAL }
const FISH_ART := ["pez azul", "pez naranja", "pez payaso", "anginla", "pez dorado millonario", "pulpo"]
const TRASH_ART := ["botella rota inferiror", "botella rota superior", "botella", "lata", "monton de basura", "soporte de cerveza"]
const INK = preload("res://shaders/sprite_ink.gdshader")
static var art_cache: Dictionary = {}
static var texture_cache: Dictionary = {}
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
var entry_target_z := INF
var _entry_start_z := 0.0
var _phase := randf() * TAU
var _rage_timer := 0.0
var _local_light: OmniLight3D
var _exit_age := -1.0
var _exit_start := Vector3.ZERO
var _notifier: VisibleOnScreenNotifier3D
var _material: ShaderMaterial
@export_range(0.0, 0.12) var body_bend := 0.045
@export_range(0.0, 1.0) var color_variety := 0.7
@export_enum("Aleatorio:-1", "Rayas:0", "Puntos:1", "Degradado:2", "Manchas:3") var color_pattern := -1
var _turn_wait := randf_range(4.0, 8.0)
var _oracle_badge: Sprite3D
var _octopus_frame := 0
const ENTRY_DURATION := 4.5
var _entry_clock := 0.0
var _swim_blend := 1.0
@onready var _sprite: Sprite3D = $Sprite3D

func _setup_color_pattern() -> void:
	# Special species keep their visual identity; color never changes reward/rarity.
	_material.set_shader_parameter("pattern_strength", 0.0)
	if kind != Kind.FISH: return
	var palette := [Color("3b9acf"), Color("60c9b0"), Color("9b8ad5"), Color("dd7795"), Color("e98764"), Color("77a9d9")]
	var index := randi_range(0, palette.size() - 1)
	_material.set_shader_parameter("body_color", palette[index])
	_material.set_shader_parameter("pattern_color", palette[(index + 2) % palette.size()].lightened(0.18))
	_material.set_shader_parameter("pattern_style", randi_range(0,3) if color_pattern < 0 else color_pattern)
	_material.set_shader_parameter("pattern_seed", randf() * 10.0)
	_material.set_shader_parameter("pattern_strength", color_variety)

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
			var bait_bias := minf(0.22, GameManager.bait_level * 0.022)
			species = "pez oracles" if GameManager.depth > 0 and r < 0.03 else ("pez azul" if r < 0.40 - bait_bias else ("pez naranja" if r < 0.72 - bait_bias * 0.45 else ("pulpo" if r < 0.82 else ("anginla" if r < 0.995 - bait_bias else "pez dorado millonario"))))
			if GameManager.depth >= 12 and randf() < 0.25: species = "pez linterna"
			if species == "pez oracles" and GameManager.depth < 5: species = "pez azul"
			if species == "anginla" and GameManager.depth < 3: species = "pez naranja"
			if species == "pez naranja" and randf() < .4: species = "pez payaso"
		if species == "pez linterna" and GameManager.depth < 12: species = "pez azul"
		rarity = 3 if "dorado" in species else (1 if "anginla" in species or "linterna" in species else 0)
		size_factor = [0.9, 1.1, 1.4].pick_random() * minf(1.55, 1.0 + GameManager.depth * 0.10)
		aura = 0
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
		size_factor = 1.85
	capture_time = 0.22 + rarity * 0.035 + aura * 0.17 + maxf(0, size_factor - 1) * 0.1
	_base_y = position.y
	_entry_start_z = position.z
	_base_z = entry_target_z if is_finite(entry_target_z) else position.z
	lifetime = 12.0 if kind == Kind.TRASH else 6.3 / maxf(speed, 0.1)
	_material = ShaderMaterial.new()
	_material.shader = INK
	_setup_color_pattern()
	_sprite.material_override = _material
	if is_finite(entry_target_z):
		_material.set_shader_parameter("fade", 0.0)
		collision_layer = 0
	_apply_art(_texture_path(species))
	if "pulpo" in species:
		_apply_art(_texture_path("pulpo nadando 1"))
	if "oracles" in species:
		_oracle_badge = Sprite3D.new()
		_oracle_badge.texture = preload("res://assets/ui/slow_clock.svg")
		_oracle_badge.pixel_size = 0.0011
		_oracle_badge.position = Vector3(0, 0.20, 0.04)
		add_child(_oracle_badge)
		_oracle_badge.visible = not is_finite(entry_target_z)
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
		_halo.visible = not is_finite(entry_target_z)
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
	if not replacement and not texture_cache.has(path): texture_cache[path] = load(path)
	var texture: Texture2D = replacement if replacement else texture_cache[path]
	if not texture: return
	var key := texture.get_instance_id()
	if not art_cache.has(key): art_cache[key] = texture.get_image().get_used_rect()
	var bounds: Rect2i = art_cache[key]
	_sprite.texture = texture
	_sprite.region_enabled = true
	var padding := maxi(5, ceili(bounds.size.y * 0.12)) if kind == Kind.FISH else 5
	_sprite.region_rect = Rect2(bounds.grow(padding).intersection(Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))))
	var width := (0.4 if "anginla" in species else (0.34 if "pulpo" in species else 0.25)) * size_factor
	_sprite.pixel_size = width / maxi(1, bounds.size.x)
	# Both drawings use the same canvas/head scale; the impulse spreads its arms.
	if species == "pulpo" and path.contains("pulpo nadando"):
		_sprite.pixel_size = width / 603.0
	_sprite.flip_h = false
	_material.set_shader_parameter("art_rect", Vector4(float(bounds.position.x) / texture.get_width(), float(bounds.position.y) / texture.get_height(), float(bounds.size.x) / texture.get_width(), float(bounds.size.y) / texture.get_height()))
	_material.set_shader_parameter("art", texture)
	_material.set_shader_parameter("texel", Vector2.ONE / texture.get_size())
	_material.set_shader_parameter("glow_color", Color(1, 0.7, 0.15, 0.2) if rarity == 3 else Color(0, 0, 0, 0))
	# Animated art must not rebuild a physics shape on every frame change.
	if species == "pulpo" and $CollisionShape3D.shape is BoxShape3D: return
	if not $CollisionShape3D.shape is BoxShape3D:
		$CollisionShape3D.shape = BoxShape3D.new()
	var box := $CollisionShape3D.shape as BoxShape3D
	box.size = Vector3(width + 0.08, bounds.size.y * _sprite.pixel_size + 0.08, 0.14)

func _physics_process(delta: float) -> void:
	if GameManager.is_run_over(): return
	delta *= GameManager.world_time_scale()
	_age += delta
	_animate_swimming(delta)
	# Approach before gameplay motion: bottles do not sink and fever fish do not
	# leave the lane while still arriving. This path is shared by every species.
	_entry_clock += delta * (4.0 if GameManager.fever_left > 0 else 1.0)
	if is_finite(entry_target_z) and _entry_clock < ENTRY_DURATION and not unsuitable and _exit_age < 0:
		var entry: float = _entry_clock / ENTRY_DURATION
		position.z = lerpf(_entry_start_z, _base_z, sin(entry * PI * 0.5))
		_material.set_shader_parameter("fade", smoothstep(0.0, 0.45, entry))
		if is_instance_valid(_halo): _halo.visible = entry > 0.65
		if is_instance_valid(_oracle_badge): _oracle_badge.visible = entry > 0.65
		return
	if is_finite(entry_target_z):
		entry_target_z = INF
		_entry_start_z = _base_z
		_swim_blend = 0.0
		collision_layer = 2
		_material.set_shader_parameter("fade", 1.0)
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
	rotation.y = 0
	_material.set_shader_parameter("fade", 1.0)
	var fever := GameManager.fever_left > 0 and kind == Kind.FISH
	if kind == Kind.TRASH and GameManager.storm_left > 0:
		position += Vector3(sin(_age * 8.0 + _phase), cos(_age * 6.0 + _phase), sin(_age * 5.0)) * delta * 1.1
		position.x = clampf(position.x, -2.9, 2.9)
		position.y = clampf(position.y, 0.3, 2.8)
		_sprite.rotation.z += delta * sin(_age * 3.0 + _phase) * 3.0
		if _age > lifetime: _expire()
		return
	_swim_blend = minf(1.0, _swim_blend + delta * 1.8)
	var movement_blend := smoothstep(0.0, 1.0, _swim_blend)
	if kind == Kind.TRASH and species.begins_with("botella"):
		position.y -= (0.4 + GameManager.depth * 0.06) * delta
		position.z = lerpf(_entry_start_z, _base_z, smoothstep(0.0, 1.0, minf(_age / ENTRY_DURATION, 1.0)))
		if position.y < -0.5: _expire()
		return
	if kind == Kind.TRASH:
		position.y = maxf(.5,position.y-delta*.22)
		position.x += direction*speed*delta*movement_blend
		if _age > lifetime: _expire()
		return
	position.x += direction * speed * (8.0 if fever else 1.0) * delta * movement_blend
	if "pulpo" in species:
		var hop := fmod(_age + _phase * 0.12, 1.35)
		var impulse := hop < 0.24
		position.y += (0.95 if impulse else -0.25) * delta
		position.y = clampf(position.y, _base_y - 0.30, _base_y + 0.52)
		var octopus_arrival := smoothstep(0.0, 1.0, minf(_age / ENTRY_DURATION, 1.0))
		position.z = lerpf(_entry_start_z, _base_z, octopus_arrival) + sin(_age * 1.4 + _phase) * 0.18
		var frame := 1 if impulse else 0
		if frame != _octopus_frame:
			_octopus_frame = frame
			_apply_art(_texture_path("pulpo nadando %d" % (_octopus_frame + 1)))
		if _age > lifetime or absf(position.x) > 3.1:
			_exit_age = 0.0
			_exit_start = position
		return
	position.y = _base_y + (2.0 / PI) * asin(sin(_age * (2.8 + GameManager.depth * 0.25) + _phase)) * (0.22 if kind == Kind.FISH else 0.04) * movement_blend
	var arrival := smoothstep(0.0, 1.0, minf(_age / ENTRY_DURATION, 1.0))
	position.z = lerpf(_entry_start_z, _base_z, arrival) + sin(_age * 1.5 + _phase) * (0.2 if kind == Kind.FISH else 0.04) * movement_blend
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
	var frequency := 3.2 if "linterna" in species else (8.0 if "anginla" in species else (6.5 if species == "pez naranja" else 4.5))
	_material.set_shader_parameter("swim_time", _age * (9.0 if angry else frequency) + _phase)
	_material.set_shader_parameter("bend_strength", body_bend * (1.65 if "anginla" in species else 1.0) if swimming and "pulpo" not in species else 0.0)
	var tilt := sin(_age * 2.8 + _phase) * 0.12 if not unsuitable else -0.25 * direction
	if unsuitable: tilt = PI
	elif species == "pez naranja": tilt += sin(_age * 4.0 + _phase) * 0.10
	elif "linterna" in species: tilt *= 0.35
	_sprite.rotation.z = lerp_angle(_sprite.rotation.z, tilt, 1.0 - exp(-delta * (2.0 if unsuitable else 5.0)))
	_sprite.rotation.y = lerp_angle(_sprite.rotation.y, 0.0 if direction > 0 else PI, 1.0 - exp(-delta * 5.0))
	if not swimming or _exit_age >= 0 or GameManager.fever_left > 0: return
	_turn_wait -= delta
	if _turn_wait <= 0:
		_turn_wait = randf_range(4.0, 8.0)
		if absf(position.x) < 2.5 and randf() < 0.6: direction *= -1.0

func on_target_pressed() -> void:
	if "anginla" in species and not unsuitable and not GameManager.is_run_over():
		if not angry:
			var shock := Node3D.new()
			shock.set_script(preload("res://scripts/RobotShock.gd"))
			add_child(shock)
			GameManager.sound_requested.emit("electric")
		angry = true
		if _local_light: _local_light.show()
		_apply_art(_texture_path("anginla enojada"))

func on_click() -> void:
	if _clicked or unsuitable or GameManager.is_run_over(): return
	if "anginla" in species:
		on_target_pressed()
		return
	_clicked = true
	if species in ["pez azul", "pez naranja", "pez payaso", "pez linterna", "pez dorado millonario"]:
		GameManager.sound_requested.emit(species)
	if "pulpo" in species:
		_apply_art(_texture_path("pulpo asustado (click)"))
		var ink := Sprite3D.new()
		ink.set_script(preload("res://scripts/InkBlot.gd"))
		get_viewport().get_camera_3d().add_child(ink)
		GameManager.sound_requested.emit("ink")
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
	GameManager.sound_at_requested.emit("fish_hurt", global_position)
	GameManager.bubbles_requested.emit(global_position)
	# Keep this individual's palette and pattern when replacing its death pose.
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
	if species == "pez payaso": noapto_texture = preload("res://assets/art/pes payaso muerto.png")
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
	if kind == Kind.SEAL: return "FOCA GIGANTE / FIEBRE DE ORO\n10 s: x2 monedas, peces veloces y música frenética"
	if kind == Kind.TRASH: return "%s / +5 monedas\nLimpia para proteger a los peces" % ("Botella de agua" if species == "botella" else species.capitalize())
	if "oracles" in species: return "◷ 5 s"
	if "anginla" in species: return "ANGUILA / No molestar\nAl tocarla contamina peces cercanos"
	if "pulpo" in species: return "PULPO / Tinta defensiva\nAl capturarlo mancha el visor 3 s"
	var stats := GameManager.fish_stats(rarity, size_factor, aura)
	return "+$%d  ·  −%.1f%%" % [stats.reward, stats.damage]
