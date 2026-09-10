shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D atlas : source_color, filter_linear, repeat_disable;
void fragment() {
 vec4 c = texture(atlas, UV);
 float green = step(c.r * 1.5 + 0.1, c.g) * step(c.b * 1.5 + 0.1, c.g);
 ALBEDO = c.rgb;
 ALPHA = (1.0 - green) * smoothstep(0.03, 0.09, max(c.r, max(c.g, c.b)));
}