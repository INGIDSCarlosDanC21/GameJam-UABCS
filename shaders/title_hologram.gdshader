shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float opacity = 1.0;
void fragment() {
 vec2 edge = min(UV, 1.0-UV);
 float border = 1.0-smoothstep(0.002,0.008,min(edge.x,edge.y));
 float scan = pow(0.5+0.5*sin(UV.y*180.0-TIME*2.0),6.0);
 float glow = 0.1+0.07*scan+border*0.6;
 ALBEDO = vec3(0.07,0.65,0.7);
 EMISSION = ALBEDO*0.4;
 ALPHA = glow*opacity;
}
