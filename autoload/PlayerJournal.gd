extends Node
## Versioned local progress; practice never contributes to records or discoveries.
var species: Array[String] = []
var photos: Dictionary = {}
var expedition_photos: Dictionary = {}
var best_depth := 0
var best_waste := 0
var best_fish := 0
var music := 0.8
var effects := 0.8
var vibration := 0.8
var sensitivity := 1.0
var render_scale := 1.0
var fps_limit := 0
var vsync := true
var detail := 2
var particles := true
var upscaler := 0
const GRAPHICS_KEYS := ["render_scale", "fps_limit", "vsync", "detail", "particles", "upscaler"]
var _save_left := 0.0
var _dirty := false
var save_path := "user://ocean_journal.cfg"
func _ready() -> void:
	if DisplayServer.get_name() == "headless": save_path = "user://ocean_journal_tests.cfg"
	load_progress()
	apply_settings()
func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK: return
	best_depth = maxi(0, int(config.get_value("records", "depth", 0)))
	best_waste = maxi(0, int(config.get_value("records", "waste", 0)))
	best_fish = maxi(0, int(config.get_value("records", "fish", 0)))
	var saved: Variant = config.get_value("records", "species", [])
	species.clear()
	if saved is Array:
		for entry in saved:
			if entry is String and not species.has(entry): species.append(entry)
	var saved_photos: Variant = config.get_value("records", "photos", {})
	photos = saved_photos if saved_photos is Dictionary else {}
	music = clampf(float(config.get_value("settings", "music", 0.8)), 0, 1)
	effects = clampf(float(config.get_value("settings", "effects", 0.8)), 0, 1)
	vibration = clampf(float(config.get_value("settings", "vibration", 0.8)), 0, 1)
	sensitivity = clampf(float(config.get_value("settings", "sensitivity", 1.0)), 0.5, 2)
	for key in GRAPHICS_KEYS: set(key, config.get_value("settings",key,get(key)))
	render_scale = clampf(render_scale,.5,1)
	detail = clampi(detail,0,2)
	fps_limit = maxi(0,fps_limit)
	upscaler = clampi(upscaler,0,2)
func discover(entry: String) -> bool:
	if GameManager.practice_mode or entry.is_empty() or species.has(entry): return false
	species.append(entry)
	species.sort()
	_dirty = true
	save_progress()
	return true
func record_photo(entry: String, path: String) -> void:
	if entry.is_empty() or not FileAccess.file_exists(path): return
	expedition_photos[entry] = path
	if GameManager.practice_mode: return
	photos[entry] = path
	save_progress()
func photo_for(entry: String) -> String:
	if GameManager.play_mode == GameManager.PlayMode.EDUCATIONAL or GameManager.practice_mode:
		return str(expedition_photos.get(entry, ""))
	return str(photos.get(entry, ""))
func update_records() -> void:
	if GameManager.practice_mode or not GameManager.mode_selected: return
	var depth := maxi(best_depth, GameManager.depth)
	var waste := maxi(best_waste, GameManager.waste_removed)
	var fish := maxi(best_fish, GameManager.fish_caught)
	_dirty = _dirty or depth != best_depth or waste != best_waste or fish != best_fish
	best_depth = depth
	best_waste = waste
	best_fish = fish
func _process(delta: float) -> void:
	_save_left -= delta
	if _save_left <= 0:
		_save_left = 10.0
		update_records()
		if _dirty: save_progress()
func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	config.set_value("records", "depth", best_depth)
	config.set_value("records", "waste", best_waste)
	config.set_value("records", "fish", best_fish)
	config.set_value("records", "species", species)
	config.set_value("records", "photos", photos)
	for key in ["music", "effects", "vibration", "sensitivity"]: config.set_value("settings", key, get(key))
	for key in GRAPHICS_KEYS: config.set_value("settings",key,get(key))
	var result := config.save(save_path)
	_dirty = result != OK
	if result != OK: push_warning("No se pudo guardar el almanaque: " + error_string(result))
func apply_settings() -> void:
	render_scale = clampf(render_scale, .5, 1.0)
	detail = clampi(detail, 0, 2)
	upscaler = clampi(upscaler, 0, 2)
	if fps_limit not in [0, 30, 60, 72, 90, 120, 144]: fps_limit = 0
	var viewport := get_viewport()
	viewport.scaling_3d_scale = render_scale
	var forward := RenderingServer.get_current_rendering_method() == "forward_plus"
	viewport.scaling_3d_mode = upscaler if forward and not viewport.use_xr else Viewport.SCALING_3D_MODE_BILINEAR
	Engine.max_fps = 0 if viewport.use_xr else fps_limit
	if not viewport.use_xr and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	viewport.mesh_lod_threshold = [4.0,2.0,1.0][detail]
	for fx in get_tree().get_nodes_in_group("optional_particles"):
		fx.visible = particles
		fx.set_process(particles)
	for bus_name in ["Music", "Ambience", "SFX", "UI", "Alarm"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0: continue
		var volume := music if bus_name in ["Music", "Ambience"] else effects
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, volume)))
	for pointer in get_tree().get_nodes_in_group("xr_pointers"): pointer.haptic_strength = vibration
	var scene := get_tree().current_scene
	if is_instance_valid(scene):
		var desktop := scene.get_node_or_null("DesktopPlayer")
		if desktop: desktop.look_sensitivity = 0.0025 * sensitivity
func _exit_tree() -> void:
	update_records()
	if _dirty: save_progress()
