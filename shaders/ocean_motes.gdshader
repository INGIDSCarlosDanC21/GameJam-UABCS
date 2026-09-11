shader_type spatial;
render_mode unshaded;
void vertex() {
	float phase = MODEL_MATRIX[3].x * 2.1 + MODEL_MATRIX[3].z;
	VERTEX.x += sin(TIME * 0.19 + phase) * 0.18;
	VERTEX.y += sin(TIME * 0.12 + phase) * 0.3;
}
void fragment() {
	ALBEDO = vec3(0.17, 0.40, 0.44);
}
