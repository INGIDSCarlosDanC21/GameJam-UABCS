extends Node3D

@onready var _sky_vp: SubViewport = $SkyViewport
@onready var _video: VideoStreamPlayer = $SkyViewport/VideoStreamPlayer
@onready var _world_env: WorldEnvironment = $WorldEnvironment
@onready var _hud: Label3D = $Cabin/StatusLabel


func _ready() -> void:
	_setup_xr()
	_setup_sky()
	GameManager.coins_changed.connect(_refresh_hud)
	GameManager.ocean_health_changed.connect(_on_health)
	_refresh_hud(GameManager.coins)


func _setup_xr() -> void:
	# OpenXR is enabled at engine startup; the scene must opt into XR rendering.
	var xr := XRServer.find_interface("OpenXR")
	var viewport := get_viewport()
	viewport.use_xr = false
	if xr != null and (xr.is_initialized() or xr.initialize()):
		$XROrigin3D/XRCamera3D.make_current()
		viewport.use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		print("Ocean VR: OpenXR activo; viewport enviando imagen al visor.")
	else:
		print("Ocean VR: OpenXR no disponible; modo PC activo.")


func _setup_sky() -> void:
	var env := _world_env.environment
	if env == null:
		env = Environment.new()
		_world_env.environment = env
	var sky := Sky.new()
	var mat := PanoramaSkyMaterial.new()
	mat.panorama = _sky_vp.get_texture()
	sky.sky_material = mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	var path := "res://assets/sky/ocean_360.ogv"
	if ResourceLoader.exists(path):
		_video.visible = true
		_video.stream = load(path)
		_video.loop = true
		_video.play()


func _refresh_hud(_coins: int) -> void:
	_hud.text = "Monedas: %d\nSalud océano: %d" % [_coins, int(GameManager.ocean_health)]


func _on_health(_v: float) -> void:
	_refresh_hud(GameManager.coins)
