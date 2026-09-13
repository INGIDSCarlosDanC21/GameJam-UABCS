extends Node3D

@onready var _sky_vp: SubViewport = $SkyViewport
@onready var _video: VideoStreamPlayer = $SkyViewport/VideoStreamPlayer
@onready var _world_env: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_setup_xr()
	var flashlight := Area3D.new()
	flashlight.set_script(preload("res://scripts/FlashlightShop.gd"))
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	flashlight.add_child(shape)
	var label := Label3D.new()
	label.name = "Label3D"
	flashlight.add_child(label)
	$Cabin.add_child(flashlight)
	var seated := Node.new()
	seated.set_script(preload("res://scripts/SeatedCalibration.gd"))
	add_child(seated)
	var pause_button := Area3D.new()
	pause_button.set_script(preload("res://scripts/PauseButton.gd"))
	$Cabin.add_child(pause_button)
	var restart_pause := Area3D.new()
	restart_pause.set_script(preload("res://scripts/PauseRestart.gd"))
	$Cabin.add_child(restart_pause)
	var snail_shake := Node.new()
	snail_shake.set_script(preload("res://scripts/SnailShake.gd"))
	add_child(snail_shake)
	_setup_sky()
	_setup_music()
	var hands := Node.new()
	hands.set_script(preload("res://scripts/HandTouchButtons.gd"))
	add_child(hands)
	var extras := Node3D.new()
	extras.set_script(preload("res://scripts/ExpeditionExtras.gd"))
	add_child(extras)
	var research_camera := Area3D.new()
	research_camera.set_script(preload("res://scripts/ResearchCamera.gd"))
	add_child(research_camera)
	var tutorial := Node3D.new()
	tutorial.set_script(preload("res://scripts/ExpeditionTutorial.gd"))
	add_child(tutorial)
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
		var desktop_player := Node.new()
		desktop_player.set_script(preload("res://scripts/DesktopPlayer.gd"))
		add_child(desktop_player)
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

func _setup_music() -> void:
	# SoundHub owns the dynamic score; retained scene node stays available to artists.
	$AmbientAudio.stop()
