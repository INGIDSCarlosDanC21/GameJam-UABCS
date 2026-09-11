extends RefCounted
## Small synthesized cues, no sampled third-party recordings.
static func make_tone(alarm: bool) -> AudioStreamWAV:
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	var seconds := 0.48 if alarm else 4.0
	var count := int(seconds * audio.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for index in count:
		var t := float(index) / audio.mix_rate
		var wave: float
		if alarm:
			var beat := fmod(t, 0.24)
			var frequency := 660.0 if t < 0.24 else 880.0
			wave = sin(TAU * frequency * t) * sin(PI * minf(1.0, beat / 0.18)) * 0.28 if beat < 0.18 else 0.0
		else:
			wave = (sin(TAU * 55.0 * t) * 0.12 + sin(TAU * 82.5 * t) * 0.035) * (0.85 + 0.15 * cos(TAU * t / 4.0))
		bytes.encode_s16(index * 2, int(wave * 32767))
	audio.data = bytes
	if not alarm:
		audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
		audio.loop_end = count
	return audio
