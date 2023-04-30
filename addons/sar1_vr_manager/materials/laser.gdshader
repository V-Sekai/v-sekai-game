shader_type spatial;
render_mode unshaded, cull_disabled, skip_vertex_transform, depth_test_disabled;

uniform vec3 target = vec3(0,0,-1);
uniform float width = 0.1;
uniform float max_stretch = 10;
uniform float uv_multiplier = 4;
uniform float speed = 1.0;

//uniform float scale_t = 0.2;
//uniform float length = 20.0;
//uniform float ws = 1.0;
uniform vec4 mix_color : source_color;
uniform sampler2D arrow_texture : source_color;

void vertex() {
	// vec3 down = vec3(0.0, -1.0 / ws, 0.0);
	
	// offset our Z so we're projecting from our origin point
	VERTEX.z -= 0.5;
	// VERTEX.z *= length; //right now the mesh goes from origin to -1 z
	// a = 0, 0, 0
	// b = 0, 0, -1
	// target = target
	// vec3 delta = target - vec3(0.0, 0.0, -1.0);
	// VERTEX = mix(VERTEX, target, -VERTEX.z * VERTEX.z * VERTEX.z);
	// VERTEX += delta * pow(abs(VERTEX.z), 2);
	float half_width = sign(VERTEX.x) * width / 2.0;
	float mix_amount = -VERTEX.z;
	vec3 p1 = vec3(0,0,0);
	vec3 p2 = vec3(0,0, max(-max_stretch, -length(target)) / 2.0);
	vec3 p3 = target + vec3(0, 0, 0);
	
	VERTEX = mix(mix(p1, p2, mix_amount), mix(p2, p3, mix_amount), mix_amount);
	vec3 next_vertex = mix(mix(p1, p2, mix_amount + 0.01), mix(p2, p3, mix_amount + 0.01), mix_amount + 0.01);
	
	// now use that to create our arch
	// float t = VERTEX.z * scale_t;
	// float t2 = t * t;

	// translate to our world vector
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	next_vertex = (MODEL_MATRIX * vec4(next_vertex, 1.0)).xyz;
	
	vec3 along_line = normalize((VERTEX - next_vertex));
	vec3 camera_pos = (INV_VIEW_MATRIX * vec4(0,0,0,1)).xyz;
	vec3 camera_line = normalize(camera_pos - VERTEX);
	vec3 cross_prod = normalize(cross(along_line, camera_line));
	vec3 sideways = cross_prod * half_width;
	VERTEX += sideways;
	
	// and apply our camera matrix
	VERTEX = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// and do our color
	float offset =  (TIME * speed);
	vec4 col = texture(arrow_texture, vec2(UV.x, UV.y * length(target) * uv_multiplier + offset )).rgba;
	ALBEDO = col.rgb * mix_color.rgb;
	
	// need to fix up our image and add an alpha channel
	ALPHA = col.a * mix_color.a;
}
