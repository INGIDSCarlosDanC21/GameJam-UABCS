extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var journal = root.get_node("PlayerJournal")
	var gm = root.get_node("GameManager")
	journal.save_path = "user://release_persistence_test.cfg"
	gm.select_mode(1)
	gm.practice_mode = false
	if "--verify" in OS.get_cmdline_user_args():
		journal.load_progress()
		assert("pez payaso" in journal.species)
		assert(is_equal_approx(journal.effects,.35))
		assert(is_equal_approx(journal.render_scale,.75))
		assert(not journal.particles)
		assert(FileAccess.file_exists(journal.photo_for("pez payaso")))
		var image := Image.load_from_file(journal.photo_for("pez payaso"))
		assert(image.get_size() == Vector2i(16,16))
		print("PASS: settings, discovery and photo survive a new process")
	else:
		journal.species.clear()
		journal.photos.clear()
		journal.effects = .35
		journal.render_scale = .75
		journal.particles = false
		var image := Image.create(16,16,false,Image.FORMAT_RGBA8)
		image.fill(Color.BLUE)
		assert(image.save_png("user://release_photo_test.png") == OK)
		journal.discover("pez payaso")
		journal.record_photo("pez payaso","user://release_photo_test.png")
		journal.save_progress()
		print("PASS: persistence fixture saved")
	quit()
