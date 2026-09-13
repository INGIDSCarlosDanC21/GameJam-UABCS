extends Area3D
var key := "music"
var title := ""
var low := 0.0
var high := 1.0
var step := .05
var value_source: Object
var changed: Callable
var _fill: MeshInstance3D
var _text: Label3D
func _ready() -> void:
	if value_source == null: value_source = PlayerJournal
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("interactable")
	add_to_group("pause_controls")
	collision_layer = 4
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.52,.08,.035)
	shape.shape = box
	add_child(shape)
	bar(Color("264b5a"),.52)
	_fill = bar(Color("78d7c5"),.52)
	_fill.material_override.render_priority = 25
	_fill.position.z = .01
	_text = Label3D.new()
	_text.font_size = 22
	_text.pixel_size = .0012
	_text.position = Vector3(0,.045,.03)
	_text.no_depth_test = true
	_text.render_priority = 26
	add_child(_text)
	refresh()
func bar(color: Color, width: float) -> MeshInstance3D:
	var face := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width,.018,.012)
	face.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.no_depth_test = true
	mat.render_priority = 24
	face.material_override = mat
	add_child(face)
	return face
func refresh() -> void:
	var value := float(value_source.get(key))
	var ratio := (value-low)/(high-low)
	_fill.scale.x = maxf(.001,ratio)
	_fill.position.x = -.26 + .26*ratio
	_text.text = title + "  " + ("%d%%" % roundi(value*100) if high <= 1 else "%.1f" % value)
func drag_at(point: Vector3) -> void:
	var ratio := clampf((to_local(point).x+.26)/.52,0,1)
	value_source.set(key, snappedf(lerpf(low,high,ratio),step))
	if value_source == PlayerJournal: PlayerJournal.apply_settings()
	if changed.is_valid(): changed.call()
	refresh()
func on_click() -> void: pass
func _process(_delta: float) -> void:
	collision_layer = 4 if is_visible_in_tree() else 0
