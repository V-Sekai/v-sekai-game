shader_type spatial;
render_mode unshaded;

uniform bool use_screenspace = false;
uniform vec4 albedo_color: source_color = vec4(1,1,1,1);
uniform sampler2D albedo_texture: source_color, hint_default_white;

void vertex() {
	// For testing, lock to camera: it should match the player's view perfectly
	//render_mode cull_disabled, depth_test_disabled, depth_draw_always;
	//POSITION = vec4(VERTEX.x * 2.0, VERTEX.y * (0.75 + 0.25 * sin(TIME)), 0.0, 1.0);
}
vec4 GammaToLinearSpace (vec4 sRGB)
{
	// Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
	return vec4(sRGB.rgb * (sRGB.rgb * (sRGB.rgb * 0.305306011 + 0.682171111) + 0.012522878), sRGB.a);
}
uniform sampler2D textureL;
uniform sampler2D textureR;
void fragment() {
	vec2 uv;
	if (use_screenspace) {
		uv = vec2(SCREEN_UV.x, SCREEN_UV.y);
	} else {
		uv = vec2(UV.x,  UV.y);
	}
	
	if(VIEW_INDEX==0)
		ALBEDO = texture(textureL,uv).rgb;
	else
		ALBEDO = texture(textureR,uv).rgb;
	ALBEDO = GammaToLinearSpace(vec4(ALBEDO, 1.0)).rgb;
	ALBEDO *= albedo_color.rgb * texture(albedo_texture, UV).rgb;
	
	// Place fragment code here.
}
