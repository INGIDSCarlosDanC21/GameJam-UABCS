extends Node3D
## Bounded scenery: one milestone animal plus a small luminous colony.
var _clock := 0.0
var _stage := -1
var _special: Node3D
var _colonies: Array[Node3D] = []
var _jelly_depth := 0.0
var _lanterns: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _clam_lids: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()
var _storm_light: OmniLight3D
var _special_pool: Array[Node3D] = []
var _arm_pool: Array = []
var _encounter_time := 0.0
var _rumble_sent := false
var _special_half_depth := 1.0
var _haptic_left := 0.0
var _encounter_voice: AudioStreamPlayer3D
func _ready() -> void:
	name = "DepthFauna"
	_encounter_voice = AudioStreamPlayer3D.new()
	_encounter_voice.stream = preload("res://assets/audio/effects/encounter_monster_cc0.wav")
	_encounter_voice.bus = "SFX"
	_encounter_voice.unit_size = 12.0
	_encounter_voice.max_distance = 35.0
	add_child(_encounter_voice)
	_storm_light = OmniLight3D.new()
	_storm_light.add_to_group("self_lit")
	_storm_light.position = Vector3(0, 7, -12)
	_storm_light.omni_range = 30
	_storm_light.light_color = Color("b9cfff")
	_storm_light.shadow_enabled = false
	add_child(_storm_light)
	_rng.seed = 941
	var life = get_parent().get_node("ReefLife")
	for data in [["Shark.glb", 3.5, 10, 20], ["Whale.glb", 8.0, 20, 31]]:
		life._swimmer(load("res://assets/models/reef/fish/" + data[0]), data[1], Vector3(0, 4.5, -20), Vector2(8, 3), 0.0, 0.09)
		life._swimmers[-1]["min_depth"] = data[2]
		life._swimmers[-1]["max_depth"] = data[3]
	for index in 24:
		var at := Vector3(_rng.randf_range(-7, 7), 0, _rng.randf_range(-17, -10))
		at.y = get_parent()._height(at.x, at.z) + 0.16
		var shell := Node3D.new()
		add_child(shell)
		shell.position = at
		var bottom := _ellipsoid(shell, Vector3.ZERO, Vector3(0.3, 0.08, 0.23), Color("dba988"))
		if index % 3 == 0:
			var lid := _ellipsoid(shell, Vector3(0, 0.10, 0), Vector3(0.3, 0.08, 0.23), Color("dfb9ae"))
			_clam_lids.append(lid)
		elif index % 3 == 1:
			bottom.scale = Vector3(0.3, 0.18, 0.23)
			_ellipsoid(shell, Vector3(0.22, -0.04, 0), Vector3(0.24, 0.04, 0.1), Color("869578"))
		else:
			for arm in 5:
				var angle := arm * TAU / 5.0
				var limb := _ellipsoid(shell, Vector3(cos(angle), 0, sin(angle)) * 0.18, Vector3(0.25, 0.045, 0.08), Color("f38d65"))
				limb.rotation.y = -angle
	for index in (4 if OS.has_feature("android") else 7):
		var jelly := Node3D.new()
		add_child(jelly)
		jelly.position = Vector3(-7 + index * 2.3, 2.5, -13 - index % 3 * 2)
		_ellipsoid(jelly, Vector3.ZERO, Vector3(0.42, 0.24, 0.42), Color("66bbf4"), true)
		for arm in 5:
			var angle := arm * TAU / 5.0
			_ellipsoid(jelly, Vector3(cos(angle) * 0.2, -0.32, sin(angle) * 0.2), Vector3(0.018, 0.28 + arm * 0.018, 0.018), Color("b596ff"), true)
		if index < 2:
			var glow := OmniLight3D.new()
			glow.add_to_group("self_lit")
			glow.light_color = Color("8b9fff")
			glow.light_energy = 2.5
			glow.omni_range = 6
			glow.shadow_enabled = false
			jelly.add_child(glow)
			glow.top_level = true
		_colonies.append(jelly)
	_jelly_depth = float(GameManager.depth)
	_update_jellies(0.0)
	for index in 4:
		var fish := Node3D.new()
		fish.visible = GameManager.depth >= 12
		add_child(fish)
		_ellipsoid(fish, Vector3.ZERO, Vector3(0.45, 0.24, 0.2), Color("41656d"))
		_ellipsoid(fish, Vector3(-0.48, 0, 0), Vector3(0.22, 0.22, 0.035), Color("376a76"))
		for side in [-1.0, 1.0]:
			_ellipsoid(fish, Vector3(0.23, 0.09, side * 0.18), Vector3.ONE * 0.055, Color("c5ffb3"), true)
		_ellipsoid(fish, Vector3(0.2, 0.42, 0), Vector3(0.04, 0.25, 0.04), Color("90ada7"))
		_ellipsoid(fish, Vector3(0.2, 0.66, 0), Vector3.ONE * 0.10, Color("a6ffbd"), true)
		if index < 2:
			var glow := OmniLight3D.new()
			glow.add_to_group("self_lit")
			glow.light_color = Color("a6ffbd")
			glow.light_energy = 2.0
			glow.omni_range = 4.0
			glow.shadow_enabled = false
			fish.add_child(glow)
		_lanterns.append(fish)
	_special = Node3D.new()
	add_child(_special)
	_special_pool.append(_special)
	_arm_pool.append([])
	for milestone in range(1, 7):
		_special = Node3D.new()
		add_child(_special)
		_stage = milestone
		_construct_special()
		_special.hide()
		_special.process_mode = Node.PROCESS_MODE_DISABLED
		_special_pool.append(_special)
		_arm_pool.append(_arms.duplicate())
	_special = _special_pool[0]
	_stage = -1
func _ellipsoid(parent: Node3D, at: Vector3, size: Vector3, color: Color, glowing: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	material.emission_enabled = glowing
	material.disable_fog = glowing
	material.emission = color
	material.emission_energy_multiplier = 1.4 if glowing else 0.0
	node.material_override = material
	node.position = at
	node.scale = size
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node
func _process(delta: float) -> void:
	_clock += delta * GameManager.world_time_scale()
	# Slow, soft electrical pulses rather than rapid full-screen flashes.
	_storm_light.light_energy = (0.5 + pow(maxf(0, sin(_clock * 2.0)), 4.0) * 2.0) if GameManager.storm_left > 0 else 0.0
	var stage := mini(6, int(GameManager.depth / 5))
	if stage != _stage:
		_stage = stage
		_build_special()
	_update_jellies(delta)
	for index in _lanterns.size():
		var fish := _lanterns[index]
		fish.visible = GameManager.depth >= 12
		fish.position = Vector3(sin(_clock * 0.18 + index * 1.7) * 6, 1.8 + sin(_clock + index) * 0.25, -12 - index)
		fish.rotation.y = 0 if cos(_clock * 0.18 + index * 1.7) >= 0 else PI
		fish.rotation.z = sin(_clock * 1.6 + index) * 0.07
	for index in _clam_lids.size(): _clam_lids[index].rotation.z = 0.12 + (sin(_clock * 0.45 + index) + 1) * 0.13
	_encounter_time += delta * GameManager.world_time_scale()
	_update_encounter(delta)
	for index in _arms.size(): _arms[index].rotation.z = sin(_clock * 1.4 - index * 0.5) * 0.28

func _update_encounter(delta: float) -> void:
	# Cross the window without reversing against a clamp. Return out of sight.
	var cycle := fmod(_encounter_time, 42.0)
	var fraction := clampf(cycle / 23.0, 0.0, 1.0)
	var x := lerpf(-23.0, 23.0, fraction)
	var front_clearance := (15.0 if _stage in [3,6] else 8.0) + _special_half_depth
	_special.position = Vector3(x, 2.8 + sin(_clock * .6) * .15, -front_clearance - pow(absf(x) / 12.0, 2.0))
	_special.rotation.y = 0.0
	if _stage == 2:
		# Approach head-on, then bank away before reaching the window.
		var approach := smoothstep(2.0,11.0,cycle)
		var retreat := smoothstep(11.0,20.0,cycle)
		_special.position = Vector3(-1.5+retreat*17.0,2.1+retreat*1.5,-22.0+approach*13.0-retreat*12.0)
		_special.rotation.y = lerp_angle(-PI*.5,0.0,retreat)
	_special.rotation.z = sin(_clock * .7) * .035
	_special.visible = _stage > 0 and cycle < 23.0
	if cycle > 23.0: _rumble_sent = false
	var proximity := (1.0 - smoothstep(1.5, 9.0, absf(x))) if _special.visible else 0.0
	if proximity > .05 and not _rumble_sent:
		_rumble_sent = true
		if _stage == 1:
			_encounter_voice.stream = preload("res://assets/audio/effects/dolphin_cry.ogg") if int(_encounter_time/42.0)%2==0 else preload("res://assets/audio/effects/dolphin_clicks.ogg")
		_encounter_voice.pitch_scale = 1.0 if _stage in [1,4] else [.8,1.3,.95,.8,.65,.85,.55][_stage]
		_encounter_voice.play()
	_encounter_voice.position = _special.position
	_encounter_voice.volume_db = lerpf(-26.0, -1.0, proximity)
	if cycle >= 23.0: _encounter_voice.stop()
	_haptic_left -= delta
	if proximity > .1 and _haptic_left <= 0:
		_haptic_left = .18
		for pointer in get_tree().get_nodes_in_group("xr_pointers"):
			pointer.pulse(proximity * minf(.9,.25+_stage*.1), .22)

func _update_jellies(delta: float) -> void:
	_jelly_depth = lerpf(_jelly_depth, float(GameManager.depth), 1.0 - exp(-delta * 0.7))
	var abyss := smoothstep(8.0, 25.0, _jelly_depth)
	for index in _colonies.size():
		var jelly := _colonies[index]
		var phase := index * 2.39996
		var t := _clock * (0.10 + index * 0.009) + phase
		var presence := 1.0 if index < 2 else smoothstep(float(index * 3 - 4), float(index * 3), _jelly_depth)
		jelly.visible = presence > 0.01
		if not jelly.visible: continue
		# Independent broad loops, entirely behind the playable lanes.
		jelly.position = Vector3(sin(t) * (4.8 + index * 0.3), 3.0 + sin(t * 1.7 + phase) * 0.8, -15.0 - index * 0.6 + cos(t * 0.8) * 2.0)
		jelly.rotation = Vector3(sin(t) * 0.12, t * 0.2, -cos(t) * 0.18)
		var size := (0.32 + index % 3 * 0.035 + abyss * 0.07) * presence
		jelly.scale = Vector3.ONE * size
		var pulse := sin(_clock * (1.6 + index * 0.07) + phase)
		var bell := jelly.get_child(0) as MeshInstance3D
		bell.scale = Vector3(0.42 * (1.0 + pulse * 0.10), 0.24 * (1.0 - pulse * 0.16), 0.42 * (1.0 + pulse * 0.10))
		for arm in 5:
			var tentacle := jelly.get_child(arm + 1) as MeshInstance3D
			tentacle.rotation.z = sin(_clock * 1.6 + phase - arm * 0.65) * 0.23
			tentacle.rotation.x = cos(_clock * 1.3 + phase - arm * 0.5) * 0.18
		for child in jelly.get_children():
			if child is MeshInstance3D:
				var material := child.material_override as StandardMaterial3D
				material.emission = Color("69b6cc").lerp(Color("9d7ae6"), abyss)
				material.emission_energy_multiplier = 1.2 + abyss * 1.3 + pulse * 0.15
			elif child is OmniLight3D:
				child.global_position = jelly.global_position
				child.light_energy = 1.6 + abyss * 1.6

func _build_special() -> void:
	if _special_pool.is_empty(): return
	for model in _special_pool:
		model.hide()
		model.process_mode = Node.PROCESS_MODE_DISABLED
	_special = _special_pool[_stage]
	_special.show()
	_special.process_mode = Node.PROCESS_MODE_INHERIT
	_arms.assign(_arm_pool[_stage])
	_encounter_time = 0.0
	_rumble_sent = false
	_special_half_depth = float(_special.get_meta("half_depth", 1.0))
	_encounter_voice.stop()
	_encounter_voice.stream = preload("res://assets/audio/effects/dolphin_cry.ogg") if _stage == 1 else (preload("res://assets/audio/effects/whale_song.ogg") if _stage == 4 else preload("res://assets/audio/effects/encounter_monster_cc0.wav"))

func _construct_special() -> void:
	for child in _special.get_children(): child.queue_free()
	_arms.clear()
	if _stage == 0: return
	# Imported large fauna cover shark/whale stages; other milestones get a unique silhouette.
	if _stage in [1, 2, 4]:
		var path := "res://assets/models/reef/fish/" + ("Dolphin.fbx" if _stage == 1 else ("Shark.glb" if _stage == 2 else "Whale.glb"))
		var model: Node3D = load(path).instantiate()
		_special.add_child(model)
		_fit_model(model, 3.5 if _stage < 4 else 12.0)
		for player in model.find_children("*", "AnimationPlayer", true, false):
			for clip in player.get_animation_list():
				if "swim" in clip.to_lower():
					player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
					player.play(clip)
					break
	elif _stage == 5:
		var model: Node3D = load("res://assets/models/reef/fish/Manta ray.fbx").instantiate()
		_special.add_child(model)
		_fit_model(model, 9.0)
		for player in model.find_children("*", "AnimationPlayer", true, false):
			for clip in player.get_animation_list():
				if "swim" in clip.to_lower():
					player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
					player.play(clip)
	else:
		var giant := 1.8 if _stage == 6 else 1.0
		_ellipsoid(_special, Vector3.ZERO, Vector3(0.7, 1.0, 0.6) * giant, Color("aa689f"), _stage == 6)
		for index in 8:
			var arm := Node3D.new()
			_special.add_child(arm)
			var angle := index * TAU / 8.0
			arm.position = Vector3(cos(angle) * 0.5, -0.5, sin(angle) * 0.5) * giant
			arm.rotation.y = -angle
			for segment in 5:
				var t := float(segment) / 4.0
				_ellipsoid(arm, Vector3(t * 1.2, -t * 1.4, 0) * giant, Vector3(0.19 - t * 0.13, 0.28, 0.19 - t * 0.13) * giant, Color("aa689f"), _stage == 6)
			_arms.append(arm)
		for side in [-1.0, 1.0]:
			_ellipsoid(_special, Vector3(side * 0.4, 0.0, 0.52) * giant, Vector3.ONE * 0.15 * giant, Color("f6d9a2"))
			_ellipsoid(_special, Vector3(side * 0.4, 0.0, 0.65) * giant, Vector3(0.07, 0.1, 0.04) * giant, Color("18202b"))
		_special.set_meta("half_depth", 2.1 * giant)

func _fit_model(model: Node3D, length: float) -> void:
	preload("res://scripts/MarineMaterials.gd").prepare(model)
	var bounds := AABB()
	var first := true
	var life = get_parent().get_node("ReefLife")
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = life._source_transform(mesh, model) * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var factor := length / maxf(0.01, maxf(bounds.size.x, bounds.size.z))
	model.scale = Vector3.ONE * factor
	model.position = -bounds.get_center() * factor
	if _stage in [1, 2, 4, 5]:
		model.rotation.y = PI * .5
		model.position = Basis(Vector3.UP, PI * .5) * model.position
		_special.set_meta("half_depth", bounds.size.x * factor * .5)
	else:
		_special.set_meta("half_depth", bounds.size.z * factor * .5)
