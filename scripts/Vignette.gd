extends MeshInstance3D
## Quad invertido frente a la cámara: viñeta negra + alarma roja según ocean_health.

var _mat: StandardMaterial3D


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = Color(0, 0, 0, 0)
	_mat.no_depth_test = true
	_mat.render_priority = 16
	set_surface_override_material(0, _mat)
	GameManager.ocean_health_changed.connect(_on_health)
	_on_health(GameManager.ocean_health)


func _on_health(value: float) -> void:
	var t := 1.0 - value / GameManager.MAX_HEALTH
	# Negro (agotamiento) + rojo (alarma) hacia derrota.
	var col := Color(lerpf(0.0, 0.85, t * t), 0.0, 0.0, t * 0.12)
	_mat.albedo_color = col
