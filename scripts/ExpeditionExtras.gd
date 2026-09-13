extends Node3D
var CATALOG: Array[String] = []
var _panel: Node3D
var _content: Label3D
var _controls: Node3D
var _page := "Almanaque"
var _catalog_page := 0
var _practice_depth := 0
var _photo_view := true
var _status: Label3D
var _left: Label3D
var _right: Label3D
var _notice := ""
var _notice_left := 0.0
var _objective := 0
var _baseline := 0
var _protect_time := 0.0
var _completed := false
var _objective_wait := 0.0
var _storm_seen := false
var _check_left := 0.0
var _restore_mouse := false
var _selected := 0
var _settings_page := 0
var _preview: Node3D
var _preview_clock := 0.0
const Catalog = preload("res://scripts/SpeciesCatalog.gd")
func _ready() -> void:
	for entry in Catalog.entries(): CATALOG.append(str(entry.name))
	name = "ExpeditionExtras"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var entry := _button(self, "DIARIO / AJUSTES", Vector3(0.34, 0.68, -0.55), open_menu)
	entry.basis = Basis.looking_at(entry.position - Vector3(0, 1.6, 0), Vector3.UP)
	_panel = Node3D.new()
	add_child(_panel)
	_panel.add_to_group("journal_panels")
	_panel.position = Vector3(0, 1.55, -1.4)
	var face := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.7, 1.16, 0.025)
	face.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("102e3b")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	material.render_priority = 20
	face.material_override = material
	_panel.add_child(face)
	var heading := _label(_panel,Vector3(0,.54,.04),.0009)
	heading.text = "OCEAN VR  /  CUADERNO DE CAMPO"
	heading.modulate = Color("92d8c5")
	heading.no_depth_test = true
	heading.render_priority = 23
	_content = Label3D.new()
	_content.position = Vector3(0, 0.03, 0.03)
	_content.font_size = 26
	_content.pixel_size = 0.0012
	_content.no_depth_test = true
	_content.render_priority = 23
	_panel.add_child(_content)
	_controls = Node3D.new()
	_panel.add_child(_controls)
	for index in 4:
		var page: String = ["Almanaque", "Récords", "Ajustes", "Práctica"][index]
		_button(_panel, page, Vector3(-0.48 + index * 0.32, 0.44, 0.04), func(): _page = page; _render_page())
	_button(_panel, "CERRAR", Vector3(0, -0.48, 0.04), close_menu)
	_panel.hide()
	_status = _label(self, Vector3(0, 0.98, -1.6), 0.00085)
	_left = _label(self, Vector3(-0.7, 1.55, -1.4), 0.0009)
	_right = _label(self, Vector3(0.7, 1.55, -1.4), 0.0009)
	PlayerJournal.apply_settings.call_deferred()
func _label(parent: Node3D, at: Vector3, pixel: float) -> Label3D:
	var label := Label3D.new()
	label.position = at
	label.font_size = 20
	label.pixel_size = pixel
	parent.add_child(label)
	return label
func _button(parent: Node3D, title: String, at: Vector3, action: Callable) -> Area3D:
	var button := Area3D.new()
	button.set_script(preload("res://scripts/JournalButton.gd"))
	button.title = title
	button.action = action
	button.position = at
	parent.add_child(button)
	if parent == _controls: button.scale.y = .8
	return button
func open_menu() -> void:
	var pause = get_parent().get_node("Cabin/PauseButton")
	if not get_tree().paused:
		pause._owns_pause = true
		get_tree().paused = true
	_panel.show()
	if not get_viewport().use_xr:
		_restore_mouse = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var camera := get_viewport().get_camera_3d()
	_panel.global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, -1.4))
	_render_page()
func close_menu() -> void:
	if _panel.visible: PlayerJournal.save_progress()
	_panel.hide()
	if _restore_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_restore_mouse = false
func _render_page() -> void:
	for control in _controls.get_children():
		control.hide()
		if control is CollisionObject3D: control.collision_layer = 0
		control.queue_free()
	_content.position = Vector3(0,.03,.03)
	_content.pixel_size = .0012
	_preview = null
	match _page:
		"Almanaque":
			_render_catalog()
		"Récords":
			PlayerJournal.update_records()
			_content.text = "MEJORES EXPEDICIONES\n\nProfundidad: %d\nResiduos retirados: %d\nPeces capturados: %d\nEspecies registradas: %d\n\nLa práctica no modifica los récords." % [PlayerJournal.best_depth, PlayerJournal.best_waste, PlayerJournal.best_fish, PlayerJournal.species.size()]
		"Ajustes":
			_render_settings()
		"Práctica":
			_content.text = "LABORATORIO · PROFUNDIDAD DE PRUEBA\n\nSalud protegida y monedas para probar mejoras.\nSin récords ni descubrimientos permanentes.\n\n%s" % ["PRÁCTICA ACTIVA" if GameManager.practice_mode else "Entrar convierte esta partida en práctica."]
			_slider("_practice_depth", "Profundidad (km)", Vector3(-.32,-.18,.04),0,30,1,self)
			_button(_controls, "ENTRAR / APLICAR", Vector3(0.32, -0.18, 0.04), _start_practice)
			_button(_controls, "TORMENTA", Vector3(-0.32, -0.34, 0.04), func(): _event("storm"))
			_button(_controls, "FIEBRE", Vector3(0, -0.34, 0.04), func(): _event("fever"))
			_button(_controls, "MEDUSA", Vector3(0.32, -0.34, 0.04), func(): _event("jelly"))
func _setting(key: String) -> void:
	var value := float(PlayerJournal.get(key)) + (0.5 if key == "sensitivity" else 0.2)
	if value > (2.01 if key == "sensitivity" else 1.01): value = 0.5 if key == "sensitivity" else 0.0
	PlayerJournal.set(key, value)
	PlayerJournal.apply_settings()
	PlayerJournal.save_progress()
	if key == "effects": GameManager.sound_requested.emit("success")
	_render_page()
func _start_practice() -> void:
	PlayerJournal.update_records()
	PlayerJournal.save_progress()
	GameManager.practice_mode = true
	GameManager.defeated = false
	GameManager.expedition_finished = false
	GameManager.expedition_success = false
	GameManager.ocean_health = 100.0
	GameManager.ocean_health_changed.emit(100.0)
	GameManager.stun_left = 0.0
	var session := get_parent().get_node("OceanSession")
	session._restart.hide()
	session._restart.collision_layer = 0
	session._status.show()
	session._mission.show()
	for robot in get_tree().get_nodes_in_group("cleaners"): robot.set_physics_process(true)
	GameManager.select_mode(GameManager.PlayMode.ARCADE)
	GameManager.depth = _practice_depth
	GameManager.level = _practice_depth * 5 + 1
	GameManager.coins = 50000
	GameManager.coins_changed.emit(GameManager.coins)
	GameManager.depth_changed.emit(_practice_depth)
	GameManager.level_changed.emit(GameManager.level)
	var mode_menu := get_parent().get_node_or_null("ModeMenu")
	if mode_menu: mode_menu.queue_free()
	for shop in get_tree().get_nodes_in_group("shop_items"):
		shop.show()
		shop.collision_layer = 2
	_panel.hide()
	get_parent().get_node("Cabin/PauseButton")._owns_pause = false
	get_tree().paused = false
func _event(kind: String) -> void:
	if not GameManager.practice_mode: return
	if kind == "storm": GameManager.storm_left = 12.0; GameManager.sound_requested.emit("storm")
	elif kind == "fever": GameManager.start_fever()
	else:
		var jelly := Area3D.new()
		jelly.set_script(preload("res://scripts/Hostile.gd"))
		jelly.jellyfish = true
		get_parent().add_child(jelly)
	_panel.hide()
	get_parent().get_node("Cabin/PauseButton")._owns_pause = false
	get_tree().paused = false

func _process(delta: float) -> void:
	if is_instance_valid(_preview):
		_preview_clock += delta
		_preview.rotation.y += delta*.35
		_preview.position.y = .06+sin(_preview_clock*1.8)*.025
	if not get_tree().paused: close_menu()
	var playing := not get_tree().paused and not GameManager.is_run_over()
	_status.visible = playing
	_left.visible = playing
	_right.visible = playing
	if not playing: return
	_notice_left = maxf(0, _notice_left - delta)
	_update_objective(delta)
	_status.text = "PRÁCTICA · Sin récords" if GameManager.practice_mode else _objective_text()
	if _notice_left > 0: _status.text = _notice
	_check_left -= delta
	if _check_left <= 0:
		_check_left = 0.25
		_update_warnings()
func _objective_text() -> String:
	if _completed: return "OBJETIVO COMPLETADO · +50 monedas"
	match _objective:
		0: return "OBJETIVO · Retira residuos %d/5" % mini(5, GameManager.waste_removed - _baseline)
		1: return "OBJETIVO · Conserva salud ≥70%% · %d/15 s" % int(_protect_time)
		_: return "OBJETIVO · Sobrevive a una tormenta"
func _update_objective(delta: float) -> void:
	if GameManager.practice_mode: return
	if _completed:
		_objective_wait -= delta
		if _objective_wait <= 0:
			_completed = false
			_objective = (_objective + 1) % 3
			_baseline = GameManager.waste_removed
			_protect_time = 0.0
			_storm_seen = false
		return
	var achieved := false
	if _objective == 0: achieved = GameManager.waste_removed - _baseline >= 5
	elif _objective == 1:
		_protect_time = _protect_time + delta if GameManager.ocean_health >= 70 else 0.0
		achieved = _protect_time >= 15.0
	else:
		if GameManager.storm_left > 0: _storm_seen = true
		achieved = _storm_seen and GameManager.storm_left <= 0
	if achieved:
		_completed = true
		_objective_wait = 5.0
		GameManager.coins += 50
		GameManager.coins_changed.emit(GameManager.coins)
		GameManager.sound_requested.emit("objective")
func _update_warnings() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera: return
	var trash_counts: Array[int] = [0, 0]
	var robots: Array[int] = [0, 0]
	for trash in get_tree().get_nodes_in_group("trash"):
		if trash._clicked or trash.collision_layer == 0: continue
		var side := 0 if camera.to_local(trash.global_position).x < 0 else 1
		trash_counts[side] += 1
	for robot in get_tree().get_nodes_in_group("cleaners"):
		if robot.paralyzed_left <= 0: continue
		var side := 0 if camera.to_local(robot.global_position).x < 0 else 1
		robots[side] += 1
	for index in 2:
		var label := _left if index == 0 else _right
		label.global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(-0.65 if index == 0 else 0.65, -0.12, -1.4))
		label.text = ""
		if trash_counts[index] > 0: label.text += "◀ " if index == 0 else "▶ "
		if trash_counts[index] > 0: label.text += "%d residuos" % trash_counts[index]
		if robots[index] > 0: label.text += "\n⚡ %d robots" % robots[index]
		label.modulate = Color("ffbf76") if robots[index] == 0 else Color("cba7ff")

func notify_photo(species: String) -> void:
	_notice = ("FOTO DE PRÁCTICA · " if GameManager.practice_mode else "FOTOGRAFIADO · ") + species.capitalize()
	_notice_left = 3
func _note(text: String, at: Vector3, pixel: float = .0009) -> Label3D:
	var label := _label(_controls,at,pixel)
	label.font_size = 26
	label.text = text
	label.no_depth_test = true
	label.render_priority = 24
	label.modulate = Color("d5eee9")
	label.outline_size = 0
	return label
func _picture(path: String, at: Vector3, width: float) -> void:
	if path.is_empty(): return
	var texture: Texture2D
	if path.begins_with("user://"):
		if not FileAccess.file_exists(path): return
		var image := Image.load_from_file(path)
		if image == null or image.is_empty(): return
		texture = ImageTexture.create_from_image(image)
	elif ResourceLoader.exists(path): texture = load(path)
	if texture == null: return
	var sprite := Sprite3D.new()
	sprite.texture = texture
	var bounds := sprite.texture.get_image().get_used_rect()
	sprite.region_enabled = true
	sprite.region_rect = Rect2(bounds)
	sprite.pixel_size = width / maxf(bounds.size.x,bounds.size.y)
	sprite.position = at
	sprite.no_depth_test = true
	sprite.render_priority = 24
	_controls.add_child(sprite)
func _render_catalog() -> void:
	var data: Dictionary = Catalog.entries()[_selected]
	var educational := GameManager.play_mode == GameManager.PlayMode.EDUCATIONAL
	var found: bool = educational or data.name in PlayerJournal.species
	var own_photo := PlayerJournal.photo_for(str(data.name))
	_content.text = "CUADERNO DE EXPEDICIÓN" if educational else "ALMANAQUE DEL OCÉANO"
	_content.position = Vector3(0,.31,.04)
	_content.pixel_size = .0011
	_button(_controls, str(data.name).capitalize()+" ▾", Vector3(-.42,.19,.04), _choose_species).scale.x=2.1
	_button(_controls, "MI FOTO" if _photo_view else "REFERENTE REAL",Vector3(.43,.19,.04),func(): _photo_view=not _photo_view; _render_page()).scale.x=1.9
	if not found:
		_note("Centra esta especie con la cámara\ny toma una foto para descubrirla.",Vector3(0,-.02,.04),.0011)
		return
	_picture(data.sprite if not str(data.sprite).is_empty() else data.photo,Vector3(-.43,-.04,.04),.27)
	if _photo_view and not own_photo.is_empty():
		_picture(own_photo,Vector3(.36,-.04,.04),.32)
		var enlarge := _button(_controls,"",Vector3(.36,-.04,.055),func(): _enlarge_photo(own_photo))
		enlarge.scale = Vector3(1.52,2.7,1)
		enlarge._face.hide()
		enlarge._label.hide()
	elif not _photo_view:
		_picture(data.photo,Vector3(.36,-.04,.04),.33)
	else:
		_note("TU PRÓXIMA FOTOGRAFÍA\n\nCentra el animal y dispara.\nTambién cuentan especies conocidas.",Vector3(.34,-.025,.04),.00085)
	var joke := str(data.joke)
	if joke.length()>65:
		var split := joke.rfind(" ",65)
		joke = joke.substr(0,split)+"\n"+joke.substr(split+1)
	_note(str(data.taxon)+"\n"+joke,Vector3(0,-.235,.04),.0009)
	_button(_controls,"MODELO 3D",Vector3(-.48,-.36,.04),_show_model)
	_button(_controls,"CRÉDITOS",Vector3(0,-.36,.04),func(): _show_credit(data))
	_button(_controls,"MIS FOTOS ▾",Vector3(.48,-.36,.04),_choose_photos)
func _choose_species() -> void:
	var labels: Array = []
	for species in CATALOG: labels.append(species.capitalize())
	_options("ELIGE UNA ESPECIE",labels,func(index: int): _selected=index; _render_page())
func _enlarge_photo(path: String) -> void:
	for child in _controls.get_children():
		child.hide()
		if child is CollisionObject3D: child.collision_layer=0
		child.queue_free()
	_preview=null
	_content.text="TU FOTOGRAFÍA · "+CATALOG[_selected].to_upper()
	_content.position=Vector3(0,.31,.04)
	_content.pixel_size=.0009
	_picture(path,Vector3(0,-.01,.04),.56)
	_button(_controls,"VOLVER",Vector3(0,-.37,.04),_render_page)
func _choose_photos() -> void:
	var available: Array = []
	for species in CATALOG:
		if not PlayerJournal.photo_for(species).is_empty(): available.append(species)
	if available.is_empty():
		_options("Aún no hay fotos de esta expedición",["VOLVER"],func(_index: int): _render_page())
		return
	_options("FOTOS · ESTA EXPEDICIÓN" if GameManager.play_mode == GameManager.PlayMode.EDUCATIONAL else "TUS FOTOGRAFÍAS",available,func(index: int): _selected=CATALOG.find(available[index]); _photo_view=true; _render_page())
func _options(title: String, labels: Array, choose: Callable) -> void:
	for child in _controls.get_children():
		child.hide()
		if child is CollisionObject3D: child.collision_layer=0
		child.queue_free()
	_preview=null
	_content.text=title
	_content.position=Vector3(0,.31,.04)
	_content.pixel_size=.001
	var columns := 3 if labels.size()>6 else 1
	for index in labels.size():
		var column := index % columns
		var row := int(index / columns)
		var at := Vector3((column-(columns-1)*.5)*.5,.20-row*.095,.05)
		var option := _button(_controls,str(labels[index]),at,func(): choose.call(index))
		option.scale=Vector3(1.55,.69,1)
		option._label.pixel_size=.00082
	_button(_controls,"CANCELAR",Vector3(0,-.39,.04),_render_page)
func _show_credit(data: Dictionary) -> void:
	for child in _controls.get_children():
		child.hide()
		if child is CollisionObject3D: child.collision_layer=0
		child.queue_free()
	_preview=null
	_content.position=Vector3(0,.04,.04)
	_content.pixel_size=.001
	_content.text="FOTOGRAFÍA · "+str(data.taxon)+"\n\n"+str(data.credit)+"\n"+str(data.license)+"\n\nWikimedia Commons · Miniatura sin otros cambios.\nIdentificación del personaje: referente aproximado.\nConsulta la fuente original para la identificación científica."
	_button(_controls,"VER FUENTE",Vector3(-.3,-.32,.04),func(): OS.shell_open(str(data.source)))
	_button(_controls,"VOLVER",Vector3(.3,-.32,.04),_render_page)
func _show_model() -> void:
	if is_instance_valid(_preview): _preview.queue_free(); _preview = null; return
	_preview = Catalog.model(_selected)
	if _preview == null:
		_options("Modelo pendiente de conseguir", ["VOLVER"], func(_index: int): _render_page())
		return
	_controls.add_child(_preview)
	_preview.position = Vector3(.27,.06,.40)
	_preview.scale = Vector3.ONE*.65
	preload("res://scripts/MarineMaterials.gd").prepare(_preview,true)
	_note("VISTA 3D · MODELO A ESCALA",Vector3(.28,-.255,.06),.00065)
func _slider(key: String,title: String,at: Vector3,low: float=0,high: float=1,step_size: float=.05, source: Object=null) -> void:
	var slider := Area3D.new()
	slider.set_script(preload("res://scripts/JournalSlider.gd"))
	slider.value_source=source
	slider.key=key
	slider.title=title
	slider.low=low
	slider.high=high
	slider.step=step_size
	slider.position=at
	_controls.add_child(slider)
func _render_settings() -> void:
	_content.text = "CONFIGURACIÓN"
	_button(_controls,["SONIDO Y CONTROL ▾","IMAGEN ▾","CALIDAD ▾"][_settings_page],Vector3(0,-.36,.04),func(): _options("CATEGORÍA",["Sonido y control","Imagen","Calidad"],func(index: int): _settings_page=index; _render_page())).scale.x=2.2
	_content.position.y = .27
	_note("Arrastra las barras con clic / gatillo. Se guarda al cerrar.",Vector3(0,.20,.04),.0008)
	if _settings_page == 0:
		_slider("music","Música",Vector3(-.35,.08,.04))
		_slider("effects","Efectos",Vector3(.35,.08,.04))
		_slider("vibration","Vibración VR",Vector3(-.35,-.09,.04))
		_slider("sensitivity","Ratón",Vector3(.35,-.09,.04),.5,2,.1)
		_button(_controls,"PROBAR SONIDO",Vector3(0,-.25,.04),func(): GameManager.sound_requested.emit("success"))
	elif _settings_page == 1:
		_slider("render_scale","Resolución 3D",Vector3(0,.06,.04),.5,1,.05)
		var vr := get_viewport().use_xr
		_button(_controls,"FPS: "+("VISOR" if vr else ("LIBRES" if PlayerJournal.fps_limit==0 else str(PlayerJournal.fps_limit))),Vector3(-.5,-.12,.04),func():
			if not vr: _graphics_options("fps_limit",[0,30,60,72,90,120,144],["Sin límite","30 FPS","60 FPS","72 FPS","90 FPS","120 FPS","144 FPS"]))
		_button(_controls,"VSync: "+("VISOR" if vr else ("SÍ" if PlayerJournal.vsync else "NO")),Vector3(0,-.12,.04),func():
			if not vr: _graphics_options("vsync",[false,true],["Desactivado","Activado"]))
		var fsr := RenderingServer.get_current_rendering_method()=="forward_plus" and not vr
		_button(_controls,["BILINEAL","FSR 1","FSR 2"][PlayerJournal.upscaler] if fsr else "BILINEAL",Vector3(.5,-.12,.04),func():
			if fsr: _graphics_options("upscaler",[0,1,2],["Bilineal","FSR 1","FSR 2"]))
		_note("DLSS: no disponible en esta versión.\nEn VR, el visor controla la sincronización y los FPS.",Vector3(0,-.24,.04),.00085)
	else:
		_button(_controls,"DETALLE: "+["BAJO","MEDIO","ALTO"][PlayerJournal.detail],Vector3(-.34,.03,.04),func(): _graphics_options("detail",[0,1,2],["Bajo","Medio","Alto"]))
		_button(_controls,"PARTÍCULAS: "+("SÍ" if PlayerJournal.particles else "NO"),Vector3(.34,.03,.04),func(): _graphics_options("particles",[false,true],["Desactivadas","Activadas"]))
		_note("Detalle ajusta fauna decorativa y geometría lejana.\nPartículas controla burbujas y motas ambientales.\nRay tracing: no disponible en esta versión.",Vector3(0,-.14,.04),.0009)
func _graphics_options(key: String, values: Array, labels: Array) -> void:
	_options("SELECCIONA UNA OPCIÓN",labels,func(index: int):
		if key == "upscaler" and (get_viewport().use_xr or RenderingServer.get_current_rendering_method()!="forward_plus"): return
		if key in ["fps_limit","vsync"] and get_viewport().use_xr: return
		PlayerJournal.set(key,values[index])
		PlayerJournal.apply_settings()
		PlayerJournal.save_progress()
		_render_page())
