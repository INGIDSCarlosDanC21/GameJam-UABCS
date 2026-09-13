extends Area3D
var capture_time := 0.12
var _label: Label3D
var _last_press := -1000
var _owns_pause := false
var _audio: AudioStreamPlayer
var _pause_sound: AudioStreamWAV
var _resume_sound: AudioStreamWAV
func _ready() -> void:
	name = "PauseButton"
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("interactable")
	add_to_group("pause_controls")
	add_to_group("touch_buttons")
	set_meta("touch_half", Vector2(0.13, 0.065))
	collision_layer = 2
	collision_mask = 0
	position = Vector3(0.0, 0.68, -0.55)
	basis = Basis.looking_at(position - Vector3(0, 1.6, 0), Vector3.UP)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.26, 0.13, 0.055)
	shape.shape = box
	add_child(shape)
	var face := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	face.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("173d56")
	face.material_override = material
	add_child(face)
	_label = Label3D.new()
	_label.position.z = 0.035
	_label.font_size = 22
	_label.pixel_size = 0.001
	add_child(_label)
	_audio = AudioStreamPlayer.new()
	_audio.bus = "UI"
	add_child(_audio)
	_pause_sound = preload("res://scripts/FeedbackTone.gd").make_tone(600, 260, 0.18)
	_resume_sound = preload("res://scripts/FeedbackTone.gd").make_tone(260, 600, 0.18)
func _process(_delta: float) -> void:
	_label.text = "CONTINUAR" if _owns_pause else "II  PAUSA"
func on_click() -> void:
	if Time.get_ticks_msec() - _last_press < 500: return
	if get_tree().paused and not _owns_pause: return
	_last_press = Time.get_ticks_msec()
	_owns_pause = not _owns_pause
	get_tree().paused = _owns_pause
	_audio.stream = _pause_sound if _owns_pause else _resume_sound
	_audio.play()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		on_click()
		get_viewport().set_input_as_handled()
func _exit_tree() -> void:
	if _owns_pause: get_tree().paused = false
