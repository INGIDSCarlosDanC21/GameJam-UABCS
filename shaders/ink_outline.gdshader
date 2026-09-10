shader_type spatial;
render_mode unshaded, cull_front;
uniform float thickness = 0.012;
void vertex() { VERTEX += NORMAL * thickness; }
void fragment() { ALBEDO = vec3(0.008, 0.01, 0.02); }
