shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled;
uniform sampler2D screen_texture : hint_screen_texture, source_color, filter_linear;
uniform float fever = 0.0;
uniform float stun = 0.0;
void fragment() {
 vec3 c = textureLod(screen_texture,SCREEN_UV,0.0).rgb;
 float gray = dot(c,vec3(0.299,0.587,0.114));
 c = mix(c,vec3(gray),stun);
 float edge = smoothstep(0.22,0.65,length(SCREEN_UV-vec2(0.5)));
 c = mix(c,vec3(1.0,0.62,0.06), fever*(0.3+edge*0.5));
 ALBEDO = c;
 ALPHA = 1.0;
}
