extends MultiMeshInstance3D
## World-space bubbles outside the window; never displace the tracked headset.
var remaining := 0.0
var clock := 0.0
func _ready() -> void:
	name = "DescentCurtain"
	var sphere := SphereMesh.new()
	sphere.radius = 0.065
	sphere.height = 0.13
	sphere.radial_segments = 12
	sphere.rings = 6
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = sphere
	multimesh.instance_count = 100 if OS.has_feature("android") else 160
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/descent_bubble.gdshader")
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false
	GameManager.depth_changed.connect(func(_depth: int): remaining = 3.5; clock = 0.0; visible = true)
func _process(delta: float) -> void:
	if remaining <= 0.0: return
	remaining = maxf(0.0, remaining - delta)
	clock += delta
	visible = remaining > 0.0
	var envelope := sin(PI * remaining / 3.5)
	for index in multimesh.instance_count:
		var phase := float(index) * 2.39996
		var x := sin(phase) * 2.5 + sin(clock + phase) * 0.08
		var y := fposmod(index * 0.173 + clock * 2.2, 4.3) - 0.6
		var z := -2.2 - fposmod(index * 0.317 - clock * 0.65, 2.2)
		var size := (0.65 + fposmod(index * 0.71, 1.5)) * envelope
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), Vector3(x,y,z)))
