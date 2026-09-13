extends Node3D
## Fixed cabin instruments: geometry only, no additional viewport or lights.
var _fill: MeshInstance3D
var _fill_material: StandardMaterial3D
var _health := 1.0
var _caption: Label3D
var _numbers: Label3D
var _footer: Label3D
var _clock_icon: Sprite3D
var _progress_lamps: Array[MeshInstance3D] = []

func _ready() -> void:
	_panel(Vector3(.11,.50,.005),Vector3.ZERO,Color("102e3b"))
	get_child(0).material_override.render_priority = 13
	_panel(Vector3(.034,.30,.006),Vector3(-.015,0,.008),Color("244854"))
	_fill = _panel(Vector3(.026,.30,.006),Vector3(-.015,0,.014),Color("5de0b1"))
	_fill_material = _fill.material_override
	_fill_material.render_priority = 16
	_clock_icon = Sprite3D.new()
	_clock_icon.texture=preload("res://assets/ui/health-normal.svg")
	_clock_icon.pixel_size=.00006
	_clock_icon.position=Vector3(-.015,.175,.02)
	_clock_icon.layers=2
	_clock_icon.modulate=Color("8ff5d8")
	_clock_icon.no_depth_test=true
	_clock_icon.render_priority=18
	add_child(_clock_icon)
	for index in 6:
		_progress_lamps.append(_panel(Vector3(.009,.041,.006),Vector3(.022,-.125+index*.05,.015),Color("244854")))
	for index in 11:
		_panel(Vector3(.008,.002,.004),Vector3(.043,-.15+index*.03,.016),Color("7696a5"))
	_caption=_label(Vector3(0,.217,.02))
	_numbers=_label(Vector3(0,-.177,.02))
	_footer=_label(Vector3(0,-.222,.02))
func _label(at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.font_size=36 if OS.has_feature("android") else 28
	label.pixel_size=.00065
	label.outline_size=2
	label.layers=2
	label.no_depth_test=true
	label.render_priority=18
	label.position=at
	add_child(label)
	return label

func _panel(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.layers = 2
	var material := StandardMaterial3D.new()
	material.no_depth_test = true
	# Explicit overlay ordering: shrinking the fill must not sort it behind its track.
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.disable_fog = true
	material.render_priority = 15
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = at
	add_child(instance)
	return instance

func _process(delta: float) -> void:
	for index in 6:
		_progress_lamps[index].material_override.albedo_color=Color("e4bf79") if index<GameManager.experience else Color("244854")
	_health=lerpf(_health,GameManager.ocean_health/100.0,1.0-exp(-delta*5))
	_fill.scale.y=maxf(.001,_health)
	_fill.position.y=-.15*(1.0-_health)
	_fill_material.albedo_color=Color("ff697f") if _health<.3 else (Color("ffd080") if _health<.5 else Color("5de0b1"))
	_caption.text="NV %d" % GameManager.level
	_numbers.text="%d%%" % roundi(GameManager.ocean_health)
	_footer.text="%d km" % GameManager.depth
