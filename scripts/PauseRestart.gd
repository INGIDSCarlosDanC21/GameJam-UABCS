extends "res://scripts/PauseButton.gd"
func _ready() -> void:
	super._ready()
	name = "PauseRestart"
	position.x = -0.34
	hide()
	collision_layer = 0
func _process(_delta: float) -> void:
	visible = get_tree().paused and get_parent().get_node("PauseButton")._owns_pause
	collision_layer = 2 if visible else 0
	_label.text = "REINICIAR"
func on_click() -> void:
	if not visible: return
	get_parent().get_node("PauseButton")._owns_pause = false
	get_tree().paused = false
	GameManager.mode_selected = false
	GameManager.restart.call_deferred()
