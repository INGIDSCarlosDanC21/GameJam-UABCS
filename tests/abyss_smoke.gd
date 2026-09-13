extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var fauna = load("res://scripts/DepthFauna.gd")
 for pair in [[0,0],[5,1],[30,6],[34,6],[35,1],[40,2],[60,6],[65,1],[95,1]]:
  assert(fauna.stage_for_depth(pair[0]) == pair[1])
 print("PASS: special animals cycle every five depth steps beyond 30")
 quit()
