extends Node3D
@export var explosion_frames: SpriteFrames
@export var explosion_texture: Texture2D
var _check := 0.0
var _alarm_clock := 0.0
var _env: Environment
var _lights: Array[Light3D] = []
var _alarm_light: OmniLight3D
var _alarm_mat: StandardMaterial3D
var _descend: Area3D
var _restart: Area3D
var _status: Label3D
var _pulse := 0.0
var _hostile_timer := 18.0
var _screen_mat: ShaderMaterial
var _screen: MeshInstance3D
func _ready() -> void:
	GameManager.cleaner_bought.connect(_buy_cleaner)
	GameManager.bubbles_requested.connect(_bubbles)
	GameManager.defeat_changed.connect(_defeat)
	GameManager.fever_changed.connect(_fever)
	GameManager.coin_requested.connect(_coin_fly)
	GameManager.depth_changed.connect(_depth_announcement)
	GameManager.level_changed.connect(_upgrade_cleaners)
	var camera := get_parent().get_node("XROrigin3D/XRCamera3D")
	_screen = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2,2)
	_screen.mesh = quad
	_screen.position.z = -0.11
	_screen_mat = ShaderMaterial.new()
	_screen_mat.shader = preload("res://shaders/event_screen.gdshader")
	_screen_mat.render_priority = -100
	_screen.material_override = _screen_mat
	camera.add_child.call_deferred(_screen)
	_descend = _button(2)
	_descend.hide()
	_descend.collision_layer = 0
	_restart = _button(3)
	_restart.hide()
	_restart.collision_layer = 0
	_status = get_parent().get_node("Cabin/StatusLabel")
	_status.pixel_size = 0.0013
	_status.position = Vector3(0, 2.35, -1.6)
	var lamp := MeshInstance3D.new()
	var bulb := SphereMesh.new()
	bulb.radius = 0.07
	bulb.height = 0.14
	lamp.mesh = bulb
	_alarm_mat = StandardMaterial3D.new()
	_alarm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lamp.material_override = _alarm_mat
	lamp.position = Vector3(0, 0.9, -1.6)
	add_child(lamp)
	_alarm_light = OmniLight3D.new()
	_alarm_light.position = lamp.position
	_alarm_light.omni_range = 2.0
	_alarm_light.light_color = Color.RED
	add_child(_alarm_light)
	await get_tree().process_frame
	_env = get_parent().get_node("WorldEnvironment").environment
	for node in get_parent().find_children("*", "Light3D", true, false):
		if node != _alarm_light:
			_lights.append(node)
	for node in get_parent().get_children():
		if node is Light3D and not node in _lights: _lights.append(node)
	if GameManager.tutorial_active:
		var tutorial := Node3D.new()
		tutorial.set_script(preload("res://scripts/TutorialOverlay.gd"))
		get_parent().get_node("XROrigin3D/XRCamera3D").add_child(tutorial)

func _button(type: int) -> Area3D:
	var button := Area3D.new()
	button.set_script(preload("res://scripts/ShopItem.gd"))
	button.item = type
	var label := Label3D.new()
	label.name = "Label3D"
	button.add_child(label)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	button.add_child(shape)
	add_child(button)
	return button

func _process(delta: float) -> void:
	_pulse += delta
	_screen.visible = not GameManager.defeated and (GameManager.fever_left > 0 or GameManager.stun_left > 0)
	_screen_mat.set_shader_parameter("fever", 1.0 if GameManager.fever_left > 0 else 0.0)
	_screen_mat.set_shader_parameter("stun", 1.0 if GameManager.stun_left > 0 else 0.0)
	_hostile_timer -= delta
	if _hostile_timer <= 0 and not GameManager.defeated and not GameManager.tutorial_active:
		_hostile_timer = maxf(3.5, 16.0 - GameManager.depth * 2.2)
		if get_tree().get_nodes_in_group("hostiles").size() < mini(10, 2 + GameManager.depth * 2):
			var hostile := Area3D.new()
			hostile.set_script(preload("res://scripts/Hostile.gd"))
			hostile.snail = randf() < minf(0.92, 0.42 + GameManager.depth * 0.12)
			add_child(hostile)
	var alive := not GameManager.defeated
	var fever := GameManager.fever_left > 0 and alive
	var health := GameManager.ocean_health / 100.0
	var illumination := maxf(0.018, health * health) * pow(0.75, GameManager.depth)
	if fever: illumination = maxf(0.9, illumination)
	if GameManager.stun_left > 0: illumination = 0.025
	if _env:
		_env.background_energy_multiplier = lerpf(_env.background_energy_multiplier, illumination, 1.0 - exp(-2 * delta))
		_env.ambient_light_energy = 0.45 * illumination
	for light in _lights:
		if not is_instance_valid(light): continue
		light.light_energy = (1.4 if fever else 0.9) * illumination
		light.light_color = Color("ffd064") if fever else Color("b9d9e0")
	var alarm_on := alive and health < 0.3
	var flash := (0.5 + 0.5 * sin(_pulse * TAU)) if alarm_on else 0.0
	_alarm_mat.albedo_color = Color(0.2 + flash * 0.8, 0.01, 0.01)
	_alarm_light.light_energy = flash * 2.0
	_alarm_clock -= delta
	if alarm_on and _alarm_clock <= 0:
		_alarm_clock = 1.2
		GameManager.sound_requested.emit("alarm")
	if alive:
		_status.text = "NIVEL %d  /  %d MONEDAS\nOCÉANO %d%%  |  PROFUNDIDAD %d\n%s" % [GameManager.level, GameManager.coins, int(GameManager.ocean_health), GameManager.depth, ("¡FIEBRE DE PECES! x2  %.1f s" % GameManager.fever_left) if fever else ("Progreso %d/6" % GameManager.experience)]
	_check -= delta
	if alive and _check <= 0:
		_check = 0.2
		_contamination()

func _contamination() -> void:
	var trash_list := get_tree().get_nodes_in_group("trash")
	for fish in get_tree().get_nodes_in_group("fish"):
		if fish.unsuitable or fish._clicked: continue
		for trash in trash_list:
			if trash._clicked: continue
			var a: Vector3 = fish.get_node("CollisionShape3D").shape.size * 0.5
			var b: Vector3 = trash.get_node("CollisionShape3D").shape.size * 0.5
			var difference: Vector3 = (fish.global_position - trash.global_position).abs()
			if difference.x < a.x + b.x and difference.y < a.y + b.y and difference.z < 0.22:
				fish.make_unsuitable()
				break

func _buy_cleaner(quality: int) -> void:
	var robot := Node3D.new()
	robot.set_script(preload("res://scripts/ReefCleaner.gd"))
	robot.quality = quality
	robot.position = Vector3(-1.7, 1.2, -3.5)
	add_child(robot)

func _upgrade_cleaners(value: int) -> void:
	var quality := GameManager.cleaner_quality()
	for cleaner in get_tree().get_nodes_in_group("cleaners"):
		cleaner.set_quality(quality)
	if value == 5 or value == 10:
		GameManager.sound_requested.emit("level")

func _coin_fly(at: Vector3, amount: int) -> void:
	var coin := Node3D.new()
	coin.set_script(preload("res://scripts/CoinFly.gd"))
	coin.amount = amount
	coin.target = _status.global_position
	add_child(coin)
	coin.global_position = at

func _depth_announcement(value: int) -> void:
	if not is_instance_valid(_descend): return
	_descend.show()
	_descend.collision_layer = 0
	_descend.get_node("Label3D").text = "PROFUNDIDAD %d\nDESCENSO AUTOMÁTICO" % value
	_descend._panel.albedo_color = Color("8d1924")
	var timer := get_tree().create_timer(2.6)
	timer.timeout.connect(func():
		if is_instance_valid(_descend): _descend.hide()
	)

func _fever(active: bool) -> void:
	if active:
		for trash in get_tree().get_nodes_in_group("trash"): trash.queue_free()

func _defeat(value: bool) -> void:
	if not value: return
	GameManager.sound_requested.emit("death")
	for entity in get_tree().get_nodes_in_group("entities"): entity.queue_free()
	for cleaner in get_tree().get_nodes_in_group("cleaners"): cleaner.queue_free()
	GameManager.active_cleaners = 0
	for hostile in get_tree().get_nodes_in_group("hostiles"): hostile.queue_free()
	_status.hide()
	for shop_name in ["ShopBait", "ShopFilter"]:
		var shop := get_parent().get_node("Cabin/" + shop_name)
		shop.hide()
		shop.collision_layer = 0
	get_parent().get_node("XROrigin3D/XRCamera3D/Vignette").hide()
	_restart.show()
	_restart.collision_layer = 2

func explode_at(at: Vector3) -> void:
	GameManager.sound_requested.emit("explosion")
	var effect: Node3D
	if explosion_frames:
		var animation := AnimatedSprite3D.new()
		animation.sprite_frames = explosion_frames
		animation.pixel_size = 0.005
		animation.play()
		effect = animation
	elif explosion_texture:
		var sprite := Sprite3D.new()
		sprite.texture = explosion_texture
		sprite.pixel_size = 0.8 / explosion_texture.get_width()
		effect = sprite
	else:
		var burst := Sprite3D.new()
		burst.set_script(preload("res://scripts/Explosion.gd"))
		add_child(burst)
		burst.global_position = at
		return
	add_child(effect)
	effect.global_position = at
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3.ONE * 3, 0.25)
	tween.tween_property(effect, "scale", Vector3.ZERO, 0.45)
	tween.tween_callback(effect.queue_free)
func _bubbles(at: Vector3) -> void:
	if get_tree().get_nodes_in_group("bubble_bursts").size() >= 12: return
	var burst := Node3D.new()
	burst.set_script(preload("res://scripts/ActionBubbles.gd"))
	burst.add_to_group("bubble_bursts")
	add_child(burst)
	burst.global_position = at
