extends "res://scripts/PauseButton.gd"
var _confirm_until := 0
var _confirm_started := 0
func _ready() -> void:
	super._ready()
	name = "PauseRestart"
	# Separate row above Pause: left is the camera, right is Journal / Settings.
	position = Vector3(0, 0.92, -0.70)
	basis = Basis.looking_at(position - Vector3(0, 1.6, 0), Vector3.UP)
	hide()
	collision_layer = 0
func _process(_delta: float) -> void:
	visible = get_tree().paused and get_parent().get_node("PauseButton")._owns_pause
	collision_layer = 2 if visible else 0
	if not visible: _confirm_until = 0
	_label.text = "¿CONFIRMAR?" if Time.get_ticks_msec() < _confirm_until else "REINICIAR"
func on_click() -> void:
	if not visible: return
	var now := Time.get_ticks_msec()
	if now >= _confirm_until:
		_confirm_started = now
		_confirm_until = now + 4000
		_audio.stream = _pause_sound
		_audio.play()
		return
	if now - _confirm_started < 500: return
	get_parent().get_node("PauseButton")._owns_pause = false
	get_tree().paused = false
	GameManager.mode_selected = false
	GameManager.restart.call_deferred()
