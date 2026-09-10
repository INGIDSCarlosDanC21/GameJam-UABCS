extends Node3D
var age := 0.0
func _ready() -> void:
	for i in range(7):
		var bubble := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = randf_range(0.018, 0.04)
		sphere.height = sphere.radius * 2
		sphere.radial_segments = 8
		sphere.rings = 4
		bubble.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.6, 0.9, 1, 0.35)
		bubble.material_override = mat
		bubble.position = Vector3(randf_range(-0.12,0.12),randf_range(-0.05,0.05),randf_range(-0.05,0.05))
		add_child(bubble)
func _process(delta: float) -> void:
	age += delta
	for b in get_children(): b.position.y += delta * 0.35
	scale = Vector3.ONE * minf(1, (1.5-age)*2)
	if age >= 1.5: queue_free()