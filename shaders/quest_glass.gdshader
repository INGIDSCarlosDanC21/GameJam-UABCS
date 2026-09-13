shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
void fragment() {
 float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),4.0);
 ALBEDO=vec3(0.25,0.7,0.9);
 ALPHA=.012+rim*.045;
}
