shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform vec4 emission : source_color;

const float CYCLE_TIME = 5.0;

void vertex() {
	UV=UV;
}

void fragment() {
	vec2 base_uv = UV;
	ALBEDO = albedo.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.5;
	EMISSION = (emission.rgb)*((sin(TIME * CYCLE_TIME) + 1.0) * 0.5);
}
