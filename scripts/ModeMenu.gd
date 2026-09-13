extends Node3D
var _buttons: Array[Area3D] = []
var _credits: Node3D
var _title: Label3D
var _fade := 1.0
var _hologram: ShaderMaterial
func _ready() -> void:
	name = "ModeMenu"
	for shop in get_tree().get_nodes_in_group("shop_items"):
		shop.hide()
		shop.collision_layer = 0
	var title := Label3D.new()
	_title = title
	title.text = "OCEAN VR\nELIGE TU EXPEDICIÓN"
	title.position = Vector3(0, 2.0, -1.7)
	title.font_size = 32
	title.pixel_size = 0.0015
	title.modulate = Color("77eddf")
	title.outline_modulate = Color("125d79")
	title.outline_size = 12
	add_child(title)
	var glass := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.65,.48)
	glass.mesh = quad
	glass.position = Vector3(0,2,-1.73)
	_hologram = ShaderMaterial.new()
	_hologram.shader = preload("res://shaders/title_hologram.gdshader")
	glass.material_override = _hologram
	add_child(glass)
	for mode in 3:
		var button := Area3D.new()
		button.set_script(preload("res://scripts/ModeButton.gd"))
		button.mode = mode
		button.position = Vector3(-0.55 if mode == 0 else 0.55, 1.23, -0.42)
		if mode == 2: button.position = Vector3(0.58,0.96,-0.20)
		button.basis = Basis.looking_at(button.position - Vector3(0,1.45,0),Vector3.UP)
		add_child(button)
		_buttons.append(button)
	_credits = Node3D.new()
	_credits.position = Vector3(0, 1.51, -1.69)
	add_child(_credits)
	var panel := MeshInstance3D.new()
	var credit_quad := QuadMesh.new()
	credit_quad.size = Vector2(1.65, 0.61)
	panel.mesh = credit_quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("102d43")
	panel.material_override = material
	_credits.add_child(panel)
	var credit_text := Label3D.new()
	credit_text.text = "MODELOS DEL ARRECIFE\nAnimated Fish · Quaternius · CC0 1.0\nquaternius.com/packs/animatedfish.html\nCoral Reef Set2, Set3, Set6 · MiniPoly · CC BY 3.0\npoly.pizza/m/HdrPoAyuCJ · /m/UyswwdHFiL · /m/hOBkCGKjlo\nKelp · Poly by Google · poly.pizza/m/4cFllH6Iazk\nOrange Coral · Device Lab · poly.pizza/m/3HEc6LvqCJd\nCC BY 3.0: creativecommons.org/licenses/by/3.0\nAdaptaciones: escala, materiales y movimiento ambiental."
	credit_text.font_size = 18
	credit_text.text += "\nMÚSICA: Atlantean Twilight · Continue Life · Dream Culture\nDarkest Child · Anxiety · Apprehension\nKevin MacLeod (incompetech.com) · CC BY 4.0\ncreativecommons.org/licenses/by/4.0/"
	credit_quad.size.y = 0.85
	credit_text.font_size = 15
	credit_text.text += "\nAmbiente submarino: Cleyton Kauffman · isaiah658 · CC0\nShark / Whale: Quaternius · CC0 · poly.pizza"
	credit_text.pixel_size = 0.0013
	credit_text.position.z = 0.015
	_credits.add_child(credit_text)
	_credits.hide()

func toggle_credits() -> void:
	_credits.visible = not _credits.visible
	for index in 2:
		_buttons[index].visible = not _credits.visible
		_buttons[index].collision_layer = 0 if _credits.visible else 2
	_buttons[2]._label.text = "Volver" if _credits.visible else "Créditos 3D"
	GameManager.sound_requested.emit("touch")

func choose(mode: int) -> void:
	if GameManager.mode_selected: return
	GameManager.select_mode(mode)
	for button in _buttons: button.collision_layer = 0
	for shop in get_tree().get_nodes_in_group("shop_items"):
		shop.show()
		shop.collision_layer = 2
	GameManager.sound_requested.emit("success")
	for button in _buttons: button.hide()
	_credits.hide()
func _process(delta: float) -> void:
	if GameManager.mode_selected:
		_fade = maxf(0,_fade-delta*.6)
		_title.modulate.a = _fade
		_hologram.set_shader_parameter("opacity",_fade)
		_title.outline_modulate.a = _fade
		if _fade == 0: queue_free()
	else:
		_title.position.y = 2.0 + sin(Time.get_ticks_msec()*.0015)*.018
