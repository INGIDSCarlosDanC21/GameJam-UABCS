extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.get_node("GameManager").select_mode(0)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.7).timeout
	var gm = root.get_node("GameManager")
	gm.set_process(false)
	main.get_node("Spawner").set_process(false)
	main.get_node("OceanSession").set_process(false)
	var hub = main.get_node("SoundHub")
	var director = hub.get_node("AudioDirector")
	check(hub.explosion.resource_path.ends_with("deltarune-explosion.mp3"), "original Deltarune explosion restored")
	check(hub.alarm.resource_path.ends_with("FNAF 3 ventilation error.mp3"), "original ventilation alarm restored")
	check(director.music_volume_db == -7 and hub.effects_volume_db == -6, "classroom mix raises music and effects")
	var previous_pitch: float = hub._varied_pitch("fish")
	var varied := true
	for index in 20:
		var next_pitch: float = hub._varied_pitch("fish")
		varied = varied and absf(next_pitch - previous_pitch) > 0.01 and next_pitch > 0.90 and next_pitch < 1.10
		previous_pitch = next_pitch
	check(varied and hub._varied_pitch("alarm") == 1.0, "repeated effects vary within bounds while alarm stays recognizable")
	check(director._normal.playing and director._normal.stream.loop, "expedition music starts and loops")
	check(not main.get_node("AmbientAudio").playing, "legacy music does not overlap")
	for event in hub._sounds:
		check(hub._sounds[event] != null and hub._sounds[event].get_length() > 0, "valid clip: " + event)
	check(AudioServer.get_bus_send(AudioServer.get_bus_index("Alarm")) == &"Master", "alarm bypasses world attenuation")
	check(AudioServer.get_bus_send(AudioServer.get_bus_index("UI")) == &"Master", "UI bypasses world attenuation")
	var master_db := AudioServer.get_bus_volume_db(0)
	gm._set_health(20)
	check(AudioServer.get_bus_volume_db(0) == master_db and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("World")) < -5, "ecology attenuates world without overwriting Master")
	hub.play_event("alarm")
	check(hub._alarm_voice.playing, "alarm owns an independent voice")
	gm._set_health(100)
	hub._process(0.1)
	check(not hub._alarm_voice.playing, "alarm stops on recovery")
	for voice in hub._voices:
		voice.stream = hub.explosion
		voice.play()
	hub.play_event("success")
	check(hub._ui_voices[0].playing or hub._ui_voices[1].playing, "purchase feedback survives crowded SFX")
	director.set_process(false)
	gm.fever_left = 10
	director._process(0.1)
	check(director._blend > 0 and director._blend < 1, "fever crossfade is gradual")
	director._process(1.0)
	check(director._fever.playing and not director._normal.playing, "fever replaces normal music")
	gm.fever_left = 0
	director._process(1.0)
	check(director._normal.playing and not director._fever.playing, "normal music returns after fever")
	gm.stun_left = 5
	director._process(1.0)
	check(director._filter.cutoff_hz < 3000 and director._normal.pitch_scale < 1, "stun muffles music")
	gm.stun_left = 0
	hub.play_at("explosion", Vector3(1, 1.5, -3))
	check(hub._spatial[0].global_position == Vector3(1, 1.5, -3), "world effects use spatial source")
	# Record a short mixed preview after the Master limiter.
	director.set_process(true)
	var record := AudioEffectRecord.new()
	record.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, record)
	record.set_recording_active(true)
	await create_timer(2.0).timeout
	gm.fever_left = 10
	hub.play_event("fever")
	await create_timer(2.0).timeout
	gm.fever_left = 0
	gm._set_health(20)
	await create_timer(2.0).timeout
	record.set_recording_active(false)
	var recording := record.get_recording()
	check(recording.data.size() > 1000, "mixed audio produces samples")
	var peak := 0.0
	var samples: PackedByteArray = recording.data
	for index in range(0, samples.size(), 2):
		peak = maxf(peak, absf(float(samples.decode_s16(index))) / 32768.0)
	check(peak > 0.001 and peak < 0.92, "recorded mix is audible and below clipping")
	print("Recorded peak dBFS: ", linear_to_db(maxf(peak, 0.00001)))
	recording.save_to_wav("res://.godot/arcade-audio-preview.wav")
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	gm._set_health(0)
	hub._process(0.1)
	director._process(2.0)
	check(not hub._alarm_voice.playing and not director._normal.playing and not director._fever.playing, "terminal state stops alarm and score")
	gm.restart()
	await create_timer(0.8).timeout
	check(get_nodes_in_group("sound_hub").size() == 1 and AudioServer.bus_count == 7, "restart does not duplicate audio buses or hub")
	print("AUDIO FAILURES: ", failures)
	quit(failures)
