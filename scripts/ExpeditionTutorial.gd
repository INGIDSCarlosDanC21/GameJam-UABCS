extends Node3D
var step := 0
var _label: Label3D
var _arrow: Label3D
var _baseline := 0
var _ready_run := false
func _ready() -> void:
	name = "ExpeditionTutorial"
	_label = Label3D.new()
	_label.font_size = 26
	_label.pixel_size = .001
	_label.outline_size = 5
	_label.position = Vector3(0,1.92,-1.45)
	add_child(_label)
	_arrow = Label3D.new()
	_arrow.text = "▼"
	_arrow.font_size = 50
	_arrow.pixel_size = .0015
	_arrow.modulate = Color("ffe3a1")
	add_child(_arrow)
func _process(_delta: float) -> void:
	var active := GameManager.mode_selected and GameManager.play_mode == GameManager.PlayMode.EDUCATIONAL and not GameManager.is_run_over()
	visible = active and step < 4
	if not active: return
	if not _ready_run:
		_ready_run = true
		GameManager.tutorial_active = true
		_baseline = GameManager.waste_removed
	var target: Node3D
	var photo := get_parent().get_node("ResearchCamera")
	match step:
		0:
			_label.text = "1/4 · LIMPIA EL MAR\nApunta a un residuo y mantén clic / gatillo.\nEl cronómetro comienza al terminar el tutorial."
			for trash in get_tree().get_nodes_in_group("trash"):
				if trash.collision_layer != 0: target = trash; break
			if GameManager.waste_removed > _baseline: step = 1
		1:
			_label.text = "2/4 · TU AYUDANTE\nCompra un filtrobot: apunta y mantén clic / gatillo.\nEn VR también puedes pulsar el botón con el dedo."
			target = get_parent().get_node("Cabin/ShopFilter")
			if GameManager.robots_deployed > 0: step = 2
		2:
			_label.text = "3/4 · INVESTIGA\nApunta a la cámara y mantén clic / gatillo para agarrarla."
			target = photo
			if is_instance_valid(photo.holder): step = 3
		3:
			_label.text = "4/4 · TU PRIMERA FOTO\nCentra un pez; pulsa otra vez clic / gatillo.\nSoltar cámara: clic derecho / grip. P: pausa en PC."
			if photo.successful_shots > 0:
				step = 4
				GameManager.tutorial_active = false
				GameManager.sound_requested.emit("objective")
	_arrow.visible = is_instance_valid(target)
	if is_instance_valid(target): _arrow.global_position = target.global_position + Vector3(0,.25,0)
