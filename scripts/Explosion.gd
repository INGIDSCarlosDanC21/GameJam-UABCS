extends Sprite3D
var elapsed := 0.0
func _ready() -> void:
	texture = preload("res://assets/art/explosion_sheet.png")
	hframes = 8
	vframes = 8
	pixel_size = 0.008
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/explosion_key.gdshader")
	mat.set_shader_parameter("atlas", texture)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _process(delta: float) -> void:
	elapsed += delta
	frame = mini(30, int(elapsed * 16))
	if elapsed >= 1.95: queue_free()