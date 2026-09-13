extends Area3D
const Catalog = preload("res://scripts/SpeciesCatalog.gd")
var holder: Node3D
var shots := 0
var successful_shots := 0
var photo_folder := "user://photos"
var last_photo := ""
var _busy := false
var _home: Transform3D
var _message: Label3D
var _view: SubViewport
var _lens: Camera3D
var _flash := 0.0
var _photo_target: Node3D
var _flash_light: OmniLight3D
var _saved_notice: Label3D
func _ready() -> void:
	name = "ResearchCamera"
	add_to_group("research_camera")
	add_to_group("interactable")
	collision_layer = 2
	position = Vector3(-.42,.95,-.48)
	_home = transform
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.25,.18,.13)
	shape.shape = box
	add_child(shape)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("194451")
	mat.metallic = .45
	body.material_override = mat
	add_child(body)
	Catalog.part(self,Vector3(0,0,-.085),Vector3(.065,.065,.06),Color("75e5e5"))
	Catalog.part(self,Vector3(.08,.095,0),Vector3(.026,.012,.026),Color("ffb965"))
	var lens := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius=.056
	cylinder.bottom_radius=.062
	cylinder.height=.07
	lens.mesh=cylinder
	lens.rotation.x=PI/2
	lens.position.z=-.085
	var black := StandardMaterial3D.new()
	black.albedo_color=Color("101e27")
	black.metallic=.6
	lens.material_override=black
	add_child(lens)
	Catalog.part(self,Vector3(0,0,-.125),Vector3(.044,.044,.005),Color("5cbdc7"))
	_message = Label3D.new()
	_message.text = "CÁMARA · Agarrar"
	_message.pixel_size = .00065
	_message.font_size = 24
	_message.position.y = .16
	add_child(_message)
	_view = SubViewport.new()
	_view.size = Vector2i(512,512)
	_view.world_3d = get_world_3d()
	_view.transparent_bg = false
	_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_view)
	_lens = Camera3D.new()
	_lens.fov = 65
	_lens.cull_mask = 1048575 & ~2
	_view.add_child(_lens)
	_flash_light = OmniLight3D.new()
	_flash_light.add_to_group("self_lit")
	_flash_light.omni_range = 4.0
	_flash_light.shadow_enabled = false
	_flash_light.light_energy = 0
	add_child(_flash_light)
	_saved_notice = Label3D.new()
	_saved_notice.font_size = 28
	_saved_notice.pixel_size = .001
	_saved_notice.no_depth_test = true
	_saved_notice.render_priority = 30
	_saved_notice.hide()
	add_child(_saved_notice)
	var disk := Sprite3D.new()
	disk.texture = load("res://assets/ui/photo_disk.svg")
	disk.pixel_size = .0007
	disk.position = Vector3(-.18,0,.005)
	disk.no_depth_test = true
	disk.render_priority = 31
	_saved_notice.add_child(disk)
	for visual in get_children():
		if visual is GeometryInstance3D: visual.layers = 2
func on_pointer_click(pointer: Node3D) -> void:
	if is_instance_valid(holder): return
	holder = pointer
	collision_layer = 0
	pointer._held = false
func release() -> void:
	holder = null
	transform = _home
	collision_layer = 2
	_message.text = "CÁMARA · Agarrar"
func handle_press(pointer: Node3D) -> bool:
	if get_tree().paused: return false
	if holder != pointer: return false
	if not get_tree().paused: photograph()
	return true
func _process(delta: float) -> void:
	_flash = maxf(0,_flash-delta)
	_flash_light.light_energy = 5.0 * maxf(0.0, (_flash-2.75)/.25)
	_saved_notice.visible = _flash > 0
	if _saved_notice.visible:
		var head := get_viewport().get_camera_3d()
		_saved_notice.global_transform = head.global_transform * Transform3D(Basis.IDENTITY,Vector3(0,-.22,-.8))
		_saved_notice.modulate.a = minf(1,_flash/.4)
	if not is_instance_valid(holder): return
	var camera := get_viewport().get_camera_3d()
	var pose := holder.global_transform if get_viewport().use_xr else camera.global_transform
	global_transform = pose * Transform3D(Basis.IDENTITY, Vector3(0,0,-.08) if get_viewport().use_xr else Vector3(.12,-.12,-.28))
	if not _busy: _lens.global_transform = pose
	_message.text = "ENCUADRA · Clic / gatillo: foto\nSoltar: clic derecho / grip" if _flash <= 0 else "FOTO GUARDADA"
	if GameManager.is_run_over(): release()
func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(holder): return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT: release()
func centered_species(pose: Transform3D) -> String:
	_photo_target = null
	var best := .985
	var name_found := ""
	var candidates: Array = get_tree().get_nodes_in_group("entities") + get_tree().get_nodes_in_group("hostiles") + get_tree().get_nodes_in_group("photographic_fauna")
	for target in candidates:
		var species := Catalog.identify(target)
		if species.is_empty() or not target.is_visible_in_tree(): continue
		var offset: Vector3 = target.global_position - pose.origin
		var alignment := offset.normalized().dot(-pose.basis.z)
		if alignment <= best: continue
		var query := PhysicsRayQueryParameters3D.create(pose.origin,target.global_position,2)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider != target: continue
		best = alignment
		name_found = species
		_photo_target = target
	var fauna := get_parent().get_node_or_null("OceanWorld/DepthFauna")
	if name_found.is_empty() and fauna and fauna._stage > 0 and is_instance_valid(fauna._special) and fauna._special.visible:
		var offset: Vector3 = fauna._special.global_position - pose.origin
		if offset.normalized().dot(-pose.basis.z) > .985:
			name_found = ["","delfín","tiburón","pulpo gigante","ballena","mantarraya gigante","pulpo abisal"][fauna._stage]
			_photo_target = fauna._special
	return name_found
func photograph() -> void:
	if _busy or not is_instance_valid(holder): return
	_busy = true
	var camera := get_viewport().get_camera_3d()
	_lens.global_transform = holder.global_transform if get_viewport().use_xr else camera.global_transform
	var species := centered_species(_lens.global_transform)
	if species.is_empty() or not is_instance_valid(_photo_target):
		_message.text = "Centra un animal para fotografiarlo"
		_busy = false
		return
	_prepare_portrait(_photo_target)
	GameManager.sound_requested.emit("shutter")
	shots += 1
	_flash = 0
	if not species.is_empty():
		successful_shots += 1
		PlayerJournal.discover(species)
	if DisplayServer.get_name() != "headless":
		_view.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(photo_folder)
		var path := photo_folder+"/%d_%d.png" % [Time.get_unix_time_from_system(),shots]
		var error := _view.get_texture().get_image().save_png(path)
		if error == OK:
			last_photo = path
			PlayerJournal.record_photo(species, path)
			_flash = 3.0
			_saved_notice.text = "FOTO GUARDADA\nEN EL ALMANAQUE"
			get_parent().get_node("ExpeditionExtras").notify_photo(species)
		if error != OK: push_warning("No se pudo guardar la foto: " + error_string(error))
	_busy = false
func _prepare_portrait(target: Node3D) -> void:
	# Photograph the real scene from the player's position, zoomed around its subject.
	var bounds := AABB()
	var first := true
	for visual in target.find_children("*","GeometryInstance3D",true,false):
		if not visual.is_visible_in_tree() or visual is Label3D: continue
		if not (visual is MeshInstance3D or visual is Sprite3D): continue
		var box: AABB = visual.global_transform * visual.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var center := target.global_position if first else bounds.get_center()
	var extent := .3 if first else maxf(.1,maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)))
	var distance := _lens.global_position.distance_to(center)
	_lens.look_at(center,Vector3.UP)
	_lens.projection = Camera3D.PROJECTION_PERSPECTIVE
	_lens.fov = clampf(rad_to_deg(2.0*atan(extent*1.15/maxf(distance,.1))),12.0,75.0)
	_lens.near = .05
