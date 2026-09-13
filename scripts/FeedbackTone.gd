extends RefCounted
static func make_tone(from_hz: float, to_hz: float, seconds: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count := int(seconds * stream.mix_rate)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += TAU * lerpf(from_hz, to_hz, t) / stream.mix_rate
		var envelope := sin(PI * t) * 0.23
		var value := int((sin(phase) + sin(phase * 2.0) * 0.2) * envelope * 32767)
		samples.encode_s16(i * 2, value)
	stream.data = samples
	return stream
