extends Node3D

var amount := 1
var target := Vector3.ZERO

func _ready() -> void:
	var coin := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.055
	mesh.bottom_radius = 0.055
	mesh.height = 0.014
	coin.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffd35a")
	material.emission_enabled = true
	material.emission = Color("ffb52e")
	material.emission_energy_multiplier = 1.4
	coin.material_override = material
	coin.rotation.x = PI * 0.5
	add_child(coin)
	var text := Label3D.new()
	text.text = "+%d" % amount
	text.font_size = 40
	text.pixel_size = 0.0015
	text.outline_size = 5
	text.modulate = Color("ffe292")
	text.position.y = 0.09
	add_child(text)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", target, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector3.ONE * 0.25, 0.38)
	tween.tween_property(self, "rotation:y", TAU * 2.0, 0.38)
	tween.chain().tween_callback(queue_free)
