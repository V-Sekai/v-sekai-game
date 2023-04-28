shader_type spatial;
render_mode unshaded, cull_disabled, skip_vertex_transform, depth_test_disabled;

uniform float width = 0.1;
uniform float height = 0.1;
uniform vec4 mix_color : source_color;
uniform sampler2D main_texture : source_color;

void vertex() {
	float half_width = sign(VERTEX.x) * width / 2.0;
	float half_height = sign(VERTEX.y) * height / 2.0;
	VERTEX.x = 0.0;
	VERTEX.y = 0.0;

	// Translate to our world vector.
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Apply our camera matrix.
	VERTEX = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 obj_center = (MODEL_MATRIX * vec4(0,0,0,1)).xyz; // The circle center can break if multiple of these are combined into one mesh.
	vec3 camera_pos = (INV_VIEW_MATRIX * vec4(0,0,0,1)).xyz;
	float camera_distance = distance(camera_pos, obj_center);
	VERTEX += vec3(half_width * camera_distance, 0.0, 0.0);
	VERTEX += vec3(0.0, half_height * camera_distance, 0.0);
}

void fragment() {
	vec4 col = texture(main_texture, vec2(UV.x, UV.y)).rgba;
	ALBEDO = col.rgb * mix_color.rgb;
	
	// Need to fix our image and add an alpha channel.
	ALPHA = col.a * mix_color.a;
}
