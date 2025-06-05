shader_type spatial;

// https://godotshaders.com/shader/shield-shader-with-intersection-highlight/

render_mode unshaded, cull_disabled;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform vec4 color1: source_color = vec4(1,1,1,.1);
uniform vec4 color2: source_color = vec4(1,1,1,1);
uniform float threshold = .2;
uniform float fresnel_sharpness = 1.0;


void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	//vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	float object_depth = FRAGCOORD.z;
	//vec3 object_ndc = vec3(SCREEN_UV, object_depth) * 2.0 - 1.0;
	vec3 object_ndc = vec3(SCREEN_UV * 2.0 - 1.0, object_depth);
	vec4 object_view = INV_PROJECTION_MATRIX * vec4(object_ndc, 1.0);
	object_view.xyz /= object_view.w;
	float linear_object_depth = -object_view.z;
	
	float fresnel = pow(1.0 - dot(VIEW, NORMAL), fresnel_sharpness);
	
	if (linear_depth - linear_object_depth > threshold) {
		ALBEDO = color1.rgb;
		ALPHA = (color1.a+fresnel);
	}
	else {
		ALBEDO = color2.rgb;
		ALPHA = color2.a+fresnel;
	}
}