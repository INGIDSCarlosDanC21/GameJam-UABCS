extends Node3D

var _page := 0
var _clock := 0.0
var _label: Label3D
var _skip: Area3D
const PAGES := [
	"APUNTA Y MANTÉN\nLáser VR o ratón en PC.",
	"PECES = MONEDAS\nLos raros pagan más, pero dañan el océano.",
	"LIMPIA BASURA\nRecupera salud y compra Filtrobots.",
	"PELIGROS\nArroja caracoles; evita globo y anguila.",
	"DESCIENDE\nCada cinco niveles hay más riesgo y valor."
]

func _ready() -> void:
	position = Vector3(0, 0.16, -1.15)
	var panel := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.02, 0.48)
	panel.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.01, 0.07, 0.12, 0.82)
	panel.material_override = material
	panel.position.z = 0.02
	add_child(panel)
	_label = Label3D.new()
	_label.font_size = 26
	_label.pixel_size = 0.00135
	_label.outline_size = 4
	_label.width = 620
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector3(-0.42, 0.12, 0)
	add_child(_label)
	_skip = Area3D.new()
	_skip.set_script(preload("res://scripts/TutorialSkip.gd"))
	_skip.tutorial = self
	var skip_label := Label3D.new()
	skip_label.text = "OMITIR TUTORIAL"
	skip_label.font_size = 20
	skip_label.pixel_size = 0.00125
	skip_label.outline_size = 4
	skip_label.modulate = Color("a9e6ff")
	skip_label.position = Vector3(-0.16, -0.20, 0)
	_skip.add_child(skip_label)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.38, 0.08, 0.06)
	shape.shape = box
	shape.position = Vector3(0, -0.18, 0)
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
