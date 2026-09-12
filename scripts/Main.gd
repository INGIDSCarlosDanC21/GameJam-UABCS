extends Node3D

@onready var _sky_vp: SubViewport = $SkyViewport
@onready var _video: VideoStreamPlayer = $SkyViewport/VideoStreamPlayer
@onready var _world_env: WorldEnvironment = $WorldEnvironment
@onready var _hud: Label3D = $Cabin/StatusLabel


func _ready() -> void:
	_setup_xr()
	_setup_sky()
	_setup_music()
	var hands := Node.new()
	hands.set_script(preload("res://scripts/HandTouchButtons.gd"))
	add_child(hands)
	GameManager.coins_changed.connect(_refresh_hud)
	GameManager.ocean_health_changed.connect(_on_health)
	_refresh_hud(GameManager.coins)
	if not GameManager.mode_selected:
		var menu := Node3D.new()
		menu.set_script(preload("res://scripts/ModeMenu.gd"))
		add_child(menu)


func _setup_xr() -> void:
	# OpenXR is enabled at engine startup; the scene must opt into XR rendering.
	var xr := XRServer.find_interface("OpenXR")
	var viewport := get_viewport()
	# Keep an active XR swapchain intact across scene reloads.
	if xr != null and (xr.is_initialized() or xr.initialize()):
		# OpenXR already supplies the physical headset height. Keeping the desktop
		# offset here would stack both heights and place the player above the cabin.
		$XROrigin3D/XRCamera3D.position.y = 0.0
		$XROrigin3D/XRCamera3D.make_current()
		viewport.use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		print("Ocean VR: OpenXR activo; viewport enviando imagen al visor.")
	else:
		$XROrigin3D/XRCamera3D.position.y = 1.6
		viewport.use_xr = false
		print("Ocean VR: OpenXR no disponible; modo PC activo.")


func _setup_sky() -> void:
	var env := _world_env.environment.duplicate(true) as Environment
	_world_env.environment = env
	env.background_mode = Environment.BG_SKY
	var sky_material := ShaderMaterial.new()
	sky_material.shader = preload("res://shaders/underwater_sky.gdshader")
	env.sky = Sky.new()
	env.sky.sky_material = sky_material
	env.sky.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("66a6b3")
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color("0c5267")
	env.fog_density = 0.018
	env.fog_sky_affect = 0.65
	_video.stop()
	_video.hide()
	_sky_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var ocean := Node3D.new()
	ocean.set_script(preload("res://scripts/OceanWorld.gd"))
	add_child(ocean)

func _refresh_hud(_coins: int) -> void:
	_hud.text = "Monedas: %d\nSalud océano: %d" % [_coins, int(GameManager.ocean_health)]


func _on_health(_v: float) -> void:
	_refresh_hud(GameManager.coins)

func _setup_music() -> void:
	# SoundHub owns the dynamic score; retained scene node stays available to artists.
	$AmbientAudio.stop()
