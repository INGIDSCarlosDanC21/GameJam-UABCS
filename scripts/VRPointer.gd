extends XRController3D
## Puntero láser: RayCast3D + trigger llama on_click() en el grupo interactable.

@onready var _ray: RayCast3D = $RayCast3D
@onready var _beam: MeshInstance3D = $LaserBeam

const TRIGGER := "trigger_click"
const MAX_LEN := 8.0


func _ready() -> void:
	button_pressed.connect(_on_button_pressed)


func _process(_delta: float) -> void:
	var hit_len := MAX_LEN
	if _ray.is_colliding():
		hit_len = global_position.distance_to(_ray.get_collision_point())
	# CylinderMesh crece en Y local; el nodo está rotado -90° en X hacia -Z.
	_beam.scale = Vector3(1.0, hit_len, 1.0)
	_beam.position.z = -hit_len * 0.5


func _on_button_pressed(button: String) -> void:
	if button != TRIGGER and button != "trigger" and button != "ax_button":
		return
	if not _ray.is_colliding():
		return
	var collider := _ray.get_collider()
	if collider is Node and (collider as Node).is_in_group("interactable"):
		if collider.has_method("on_click"):
			collider.on_click()
