extends Node3D
## Stylized recovery indicator, not a simulation of real coral growth.
var _corals: Array[Node3D] = []
var _materials: Array[StandardMaterial3D] = []
var _recovery := 0.0

func _ready() -> void:
	for color in [Color("50cbb1"), Color("d883af"), Color("d8bd76")]:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		_materials.append(material)
	for index in range(9):
		var coral := Node3D.new()
		coral.position = Vector3(-2.4 + index * 0.6, 0.48, -3.7 - (index % 3) * 0.35)
		add_child(coral)
		_corals.append(coral)
		for branch in range(3):
			var part := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.035
			mesh.bottom_radius = 0.065
			mesh.height = 0.34 + (index % 3) * 0.08
			mesh.radial_segments = 6
			part.mesh = mesh
			part.material_override = _materials[index % 3]
			part.position = Vector3((branch - 1) * 0.09, mesh.height * 0.45, 0)
			part.rotation.z = (branch - 1) * -0.5
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			coral.add_child(part)

func _process(delta: float) -> void:
	var cleaned := minf(1.0, float(GameManager.waste_removed) / GameManager.WASTE_GOAL)
	var target := cleaned * clampf(GameManager.ocean_health / GameManager.HEALTH_GOAL, 0.0, 1.0)
	_recovery = lerpf(_recovery, target, 1.0 - exp(-1.2 * delta))
	var palette := [Color("50cbb1"), Color("d883af"), Color("d8bd76")]
	for index in _materials.size():
		_materials[index].albedo_color = Color("626c72").lerp(palette[index], _recovery)
	for coral in _corals:
		coral.scale.y = lerpf(0.38, 1.0, _recovery)
