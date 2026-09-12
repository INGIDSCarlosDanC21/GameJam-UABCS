extends Node3D
var _buttons: Array[Area3D] = []
var _credits: Node3D
func _ready() -> void:
	name = "ModeMenu"
	for shop in get_tree().get_nodes_in_group("shop_items"):
		shop.hide()
		shop.collision_layer = 0
	var title := Label3D.new()
	title.text = "OCEAN VR\nELIGE TU EXPEDICIÓN"
	title.position = Vector3(0, 2.0, -1.7)
	title.font_size = 32
	title.pixel_size = 0.0015
	add_child(title)
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
	var quad := QuadMesh.new()
	quad.size = Vector2(1.65, 0.61)
	panel.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("102d43")
	panel.material_override = material
	_credits.add_child(panel)
	var credit_text := Label3D.new()
	credit_text.text = "MODELOS DEL ARRECIFE\nAnimated Fish · Quaternius · CC0 1.0\nquaternius.com/packs/animatedfish.html\nCoral Reef Set2, Set3, Set6 · MiniPoly · CC BY 3.0\npoly.pizza/m/HdrPoAyuCJ · /m/UyswwdHFiL · /m/hOBkCGKjlo\nKelp · Poly by Google · poly.pizza/m/4cFllH6Iazk\nOrange Coral · Device Lab · poly.pizza/m/3HEc6LvqCJd\nCC BY 3.0: creativecommons.org/licenses/by/3.0\nAdaptaciones: escala, materiales y movimiento ambiental."
	credit_text.font_size = 18
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
	queue_free()
