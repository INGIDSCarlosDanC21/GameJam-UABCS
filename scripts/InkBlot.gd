extends Sprite3D
## Ink placed in camera space so an octopus can obscure a random part of either view.

var lifetime := 3.0
var age := 0.0


func _ready() -> void:
	texture = load(["res://assets/art/tinta 1.png", "res://assets/art/tinta2.png", "res://assets/art/tinta3.png", "res://assets/art/tinta 4.png"].pick_random())
	pixel_size = 0.0012
	billboard = BaseMaterial3D.BILLBOARD_DISABLED
	no_depth_test = true
	position = Vector3(randf_range(-0.52, 0.52), randf_range(-0.30, 0.30), -0.12)
	rotation.z = randf_range(-PI, PI)
	var bounds := texture.get_image().get_used_rect()
	region_enabled = true
	region_rect = Rect2(bounds)
	pixel_size = randf_range(0.00075, 0.00105)


func _process(delta: float) -> void:
	age += delta
	var fade := clampf((lifetime - age) / 0.45, 0.0, 1.0)
	modulate.a = fade
	scale = Vector3.ONE * lerpf(0.7, 1.0, minf(age / 0.18, 1.0))
	if age >= lifetime:
		queue_free()
