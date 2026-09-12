extends Node3D
## Fixed cabin instruments: geometry only, no additional viewport or lights.
var _fill: MeshInstance3D
var _fill_material: StandardMaterial3D
var _health := 1.0
var _clock_icon: Sprite3D
var _progress_lamps: Array[MeshInstance3D] = []

func _ready() -> void:
	_panel(Vector3(1.34, 0.32, 0.022), Vector3(0, 0, -0.045), Color("071923"))
	_panel(Vector3(1.37, 0.35, 0.014), Vector3(0, 0, -0.06), Color("245363"))
	_panel(Vector3(1.2, 0.022, 0.008), Vector3(0, -0.12, -0.015), Color("183541"))
	_fill = _panel(Vector3(1.2, 0.022, 0.009), Vector3(0, -0.12, -0.009), Color("5de0b1"))
	_fill_material = _fill.material_override as StandardMaterial3D
	_clock_icon = Sprite3D.new()
	_clock_icon.texture = preload("res://assets/ui/slow_clock.svg")
	_clock_icon.pixel_size = 0.0008
	_clock_icon.position = Vector3(0.57, 0.03, 0.025)
	add_child(_clock_icon)
	for index in 6:
		_progress_lamps.append(_panel(Vector3(0.055, 0.018, 0.01), Vector3(-0.20 + index * 0.08, -0.065, 0.01), Color("204556")))

func _panel(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = at
	add_child(instance)
	return instance

func _process(delta: float) -> void:
	_clock_icon.visible = GameManager.slow_time_left > 0.0
	_clock_icon.rotation.z = sin(Time.get_ticks_msec() * 0.004) * 0.12
	for index in 6:
		_progress_lamps[index].material_override.albedo_color = Color("85ffe0") if index < GameManager.experience else Color("204556")
	_health = lerpf(_health, GameManager.ocean_health / 100.0, 1.0 - exp(-5.0 * delta))
	_fill.scale.x = maxf(0.001, _health)
	_fill.position.x = -0.6 * (1.0 - _health)
	_fill_material.albedo_color = Color("ff6571") if _health < 0.3 else (Color("ffd080") if _health < 0.6 else Color("5de0b1"))
