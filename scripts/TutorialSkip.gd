extends Area3D

var tutorial: Node

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0
	monitoring = false

func on_click() -> void:
	if is_instance_valid(tutorial): tutorial.finish()
