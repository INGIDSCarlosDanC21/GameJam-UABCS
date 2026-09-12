extends Node3D
## Contextual hologram shown while the player looks at a shop control.

var _label: Label3D
var _panel: MeshInstance3D
var _shown := false
var _material: StandardMaterial3D
var _anchor_position := Vector3.ZERO
var _transition: Tween
var _linger := 0.0
var _last_shop: Node3D


func _ready() -> void:
	name = "WalletPanel"
	position = Vector3(0.0, 1.32, -0.56)
	_panel = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.34, 0.105, 0.008)
	_panel.mesh = box
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color("39dfff", 0.16)
	_material.emission_enabled = true
	_material.emission = Color("39dfff")
	_material.emission_energy_multiplier = 1.4
	_panel.material_override = _material
	add_child(_panel)
	_label = Label3D.new()
	_label.font_size = 22
	_label.pixel_size = 0.00085
	_label.outline_size = 3
	_label.modulate = Color("bffaff")
	_label.position.z = 0.018
	add_child(_label)
	GameManager.coins_changed.connect(_refresh)
	_refresh(GameManager.coins)
	visible = false


func _process(delta: float) -> void:
	var target_shop: Node3D = null
	var camera := get_viewport().get_camera_3d()
	for shop in get_tree().get_nodes_in_group("shop_items"):
		if not shop.is_visible_in_tree(): continue
		var looking := false
		if is_instance_valid(camera):
			var to_shop: Vector3 = shop.global_position - camera.global_position
			looking = to_shop.normalized().dot(-camera.global_basis.z) > 0.975
		if bool(shop.get("_hover")) or looking or float(shop.get("_touch_depth")) > 0.05:
			target_shop = shop
			break
	if is_instance_valid(target_shop):
		_last_shop = target_shop
		_linger = 0.22
	else:
		_linger = maxf(0.0, _linger - delta)
		if _linger > 0.0 and is_instance_valid(_last_shop) and _last_shop.is_visible_in_tree():
			target_shop = _last_shop
	if is_instance_valid(target_shop):
		# The net button has a different tilt; keep one stable hologram anchor above bait.
		# Resolve from Cabin explicitly so the shared wallet also works for Filtrobot.
		var cabin := get_tree().current_scene.get_node_or_null("Cabin") as Node3D
		var bait_button: Node3D = cabin.get_node_or_null("ShopBait") as Node3D if is_instance_valid(cabin) else null
		var anchor: Node3D = target_shop
		if target_shop.name == "ShopNet" and is_instance_valid(bait_button): anchor = bait_button
		var current_scale := scale
		global_basis = anchor.global_basis.orthonormalized()
		scale = current_scale
		_anchor_position = anchor.global_position + anchor.global_basis.y * 0.20
		global_position = _anchor_position
	if (target_shop != null) != _shown:
		_shown = target_shop != null
		visible = true
		if is_instance_valid(_transition): _transition.kill()
		_transition = create_tween()
		if _shown:
			scale = Vector3.ONE * 0.72
			_transition.tween_property(self, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_transition.tween_property(self, "scale", Vector3.ONE * 0.72, 0.14)
			_transition.tween_callback(func(): visible = false)
	if _shown:
		global_position = _anchor_position + global_basis.y * sin(Time.get_ticks_msec() * 0.003) * 0.008


func _refresh(coins: int) -> void:
	_label.text = "BILLETERA  ·  $%d" % coins
