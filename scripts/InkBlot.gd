extends Sprite3D
## Ink placed in camera space so an octopus can obscure a random part of either view.

var lifetime := 3.0
var age := 0.0


func _ready() -> void:
	# Repeated hits replace the previous patch instead of filling the entire visor.
	for other in get_parent().get_children():
		if other != self and other.get_script() == get_script():
			other.hide()
			other.queue_free()
	texture = load(["res://assets/art/tinta 1.png", "res://assets/art/tinta2.png", "res://assets/art/tinta3.png", "res://assets/art/tinta 4.png"].pick_random())
	billboard = BaseMaterial3D.BILLBOARD_DISABLED
	no_depth_test = true
	# Comfortable stereo distance with a bounded angular size (~20 degrees).
	position = Vector3((-1.0 if randf() < 0.5 else 1.0) * randf_range(0.20, 0.29), randf_range(-0.14, 0.14), -0.9)
	rotation.z = randf_range(-PI, PI)
	var bounds := texture.get_image().get_used_rect()
	region_enabled = true
	region_rect = Rect2(bounds)
	# Normalize by the cropped image diagonal; rotation cannot enlarge the patch.
	pixel_size = 0.55 / maxf(1.0, Vector2(bounds.size).length())
	scale = Vector3.ONE * 0.7


func _process(delta: float) -> void:
	age += delta
	var fade := clampf((lifetime - age) / 0.45, 0.0, 1.0)
	modulate.a = fade * smoothstep(0,.25,age)
	scale = Vector3.ONE * lerpf(0.7, 1.0, minf(age / 0.18, 1.0))
	if age >= lifetime:
		queue_free()
