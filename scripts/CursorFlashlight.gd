extends SpotLight3D
func _ready() -> void:
	add_to_group("self_lit")
	light_color = Color("fff1d0")
	shadow_enabled = false
	spot_angle = 24.0
	spot_angle_attenuation = 0.8
func _process(_delta: float) -> void:
	var pointer := get_parent()
	var level: int = GameManager.flashlight_level
	visible = level > 0 and (pointer.get_is_active() if get_viewport().use_xr else pointer.desktop_enabled)
	if not visible: return
	# Shadows are disabled, so the glass does not block the cabin-origin beam.
	global_position = pointer._ray.global_position + pointer._aim * .04
	global_basis = Basis.looking_at(pointer._aim, Vector3.UP)
	spot_range = 3.0 + level * 2.0
	light_energy = 0.4 + level * 0.7
	spot_angle = 7.0 + level * 2.0
