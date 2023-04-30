shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

const float PI_CONST = 3.14159265359;
const float WAVE_RATIO = 5.0;
const float WOBBLE_LENGTH = 0.05;
const float SPEED = 10.0;

void vertex() {
	float wobble = (sin((UV.y) * PI_CONST * WAVE_RATIO)) * 0.5;
	VERTEX += NORMAL * sin(TIME * SPEED) * WOBBLE_LENGTH * wobble;
}

void fragment() {
	ALBEDO = vec3(1.0, 1.0, 1.0);
	METALLIC = 1.0;
	ROUGHNESS = 0.5;
	SPECULAR = 0.5;
}
