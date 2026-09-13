extends Node
## Opt-in device QA. Only launched by Main in debug builds with a local flag.
var elapsed := 0.0
var report_left := 5.0
var stage := -1
var report: FileAccess
func log_line(message: String) -> void:
	print(message)
	if report:
		report.store_line(message)
		report.flush()
func _ready() -> void:
	report = FileAccess.open("user://qa_soak.log",FileAccess.WRITE)
	DirAccess.remove_absolute("user://qa_soak.flag")
	PlayerJournal.save_path = "user://qa_soak_journal.cfg"
	GameManager.practice_mode = true
	GameManager.select_mode(GameManager.PlayMode.ARCADE)
	GameManager.level = 201
	var menu := get_parent().get_node_or_null("ModeMenu")
	if menu: menu.queue_free()
	for index in 30:
		var robot := Node3D.new()
		robot.set_script(preload("res://scripts/ReefCleaner.gd"))
		robot.quality = 3
		get_parent().add_child(robot)
	log_line("QA_SOAK START duration=300 fleet=30 practice=true")
func _process(delta: float) -> void:
	elapsed += delta
	var next_stage := mini(4,int(elapsed/60.0))
	if next_stage != stage:
		stage = next_stage
		GameManager.depth = [0,15,30,35,40][stage]
		GameManager.depth_changed.emit(GameManager.depth)
	GameManager.storm_left = 12.0 if fposmod(elapsed,60.0)>30.0 else 0.0
	report_left -= delta
	if report_left <= 0:
		report_left = 5.0
		log_line("QA_SOAK t=%d depth=%d fps=%d nodes=%d memory=%d entities=%d" % [int(elapsed),GameManager.depth,Engine.get_frames_per_second(),get_tree().get_node_count(),OS.get_static_memory_usage(),get_tree().get_nodes_in_group("entities").size()])
	if elapsed >= 300:
		log_line("QA_SOAK COMPLETE")
		get_tree().quit()
