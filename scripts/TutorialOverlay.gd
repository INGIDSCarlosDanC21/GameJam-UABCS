extends Node3D

var _page := 0
var _clock := 0.0
var _label: Label3D
var _skip: Area3D
const PAGES := [
	"BIENVENIDO A LA CABINA\n\nUsa el láser para apuntar. Mantén pulsado para agarrar objetivos.\nTambién puedes usar el ratón en PC.",
	"PECES Y MONEDAS\n\nLos peces raros y grandes pagan más, pero dañan más el océano.\nLas auras doradas dan más dinero y tardan más en capturarse.",
	"LIMPIA EL OCÉANO\n\nCaptura basura para recuperar salud. Compra filtros y robots limpiadores: cada calidad trabaja más rápido.",
	"PELIGROS\n\nLos caracoles se pegan a tu vista: arrástralos al borde y suelta.\nEvita al pez globo y no enfades a la anguila.",
	"PROFUNDIDAD\n\nCada seis capturas desciendes automáticamente. Habrá más basura y caracoles; los peces crecen y se vuelven más valiosos."
]

func _ready() -> void:
	position = Vector3(0, 0.03, -1.15)
	var panel := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.55, 0.78)
	panel.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.01, 0.07, 0.12, 0.82)
	panel.material_override = material
	panel.position.z = 0.02
	add_child(panel)
	_label = Label3D.new()
	_label.font_size = 38
	_label.pixel_size = 0.00155
	_label.outline_size = 5
	_label.width = 940
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector3(-0.70, 0.21, 0)
	add_child(_label)
	_skip = Area3D.new()
	_skip.set_script(preload("res://scripts/TutorialSkip.gd"))
	_skip.tutorial = self
	var skip_label := Label3D.new()
	skip_label.text = "OMITIR TUTORIAL"
	skip_label.font_size = 30
	skip_label.pixel_size = 0.0015
	skip_label.outline_size = 4
	skip_label.modulate = Color("a9e6ff")
	skip_label.position = Vector3(-0.22, -0.34, 0)
	_skip.add_child(skip_label)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.54, 0.11, 0.06)
	shape.shape = box
	shape.position = Vector3(0, -0.30, 0)
	_skip.add_child(shape)
	add_child(_skip)
	_show_page()

func _process(delta: float) -> void:
	_clock += delta
	if _clock >= 7.0:
		_clock = 0.0
		_page += 1
		if _page >= PAGES.size(): finish()
		else: _show_page()

func _show_page() -> void:
	_label.text = "%s\n\n%d / %d" % [PAGES[_page], _page + 1, PAGES.size()]

func finish() -> void:
	GameManager.tutorial_active = false
	GameManager.tutorial_completed = true
	GameManager.sound_requested.emit("success")
	queue_free()
