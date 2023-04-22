// res://addons/canvas_plane/canvas_shader.gdshader
// This file is part of the V-Sekai Game.
// https://github.com/V-Sekai/canvas_plane
//
// Copyright (c) 2018-2022 SaracenOne
// Copyright (c) 2019-2022 K. S. Ernest (iFire) Lee (fire)
// Copyright (c) 2020-2022 Lyuma
// Copyright (c) 2020-2022 MMMaellon
// Copyright (c) 2022 V-Sekai Contributors
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

shader_type spatial;

render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,unshaded;

uniform sampler2D texture_albedo : source_color;
uniform float bias = 0.0;
uniform int billboard_mode = 0;

void vertex() {
	UV=vec2(UV.x, UV.y);
	if (billboard_mode >= 1) {
		
		mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0])*length(MODEL_MATRIX[0]),normalize(INV_VIEW_MATRIX[1])*length(MODEL_MATRIX[0]),normalize(INV_VIEW_MATRIX[2])*length(MODEL_MATRIX[2]),MODEL_MATRIX[3]);
		
	    vec3 target_position = INV_VIEW_MATRIX[3].xyz; // camera position?
	    vec3 vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	    vec3 origin = (MODEL_MATRIX * vec4(0,0,0,1)).xyz;
	    vec3 forward = normalize(target_position - origin);
	    vec3 right = normalize(cross(vec3(0,1,0),forward));
		vec3 up;
		if (billboard_mode >= 2) {
	    	up = vec3(0.0, 1.0, 0.0); //normalize(cross(forward,right));
			forward = cross(right, up);
		} else {
			up = normalize(cross(forward,right));
		}
	    mat3 mat = (mat3(right * length(MODEL_MATRIX[0]), up * length(MODEL_MATRIX[1]), forward * length(MODEL_MATRIX[2])));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(mat[0], 0.0), vec4(mat[1], 0.0), vec4(mat[2], 0.0), MODEL_MATRIX[3]);
	}
}

vec3 srgb_conversion(vec3 pixel) {
	return mix(pow((pixel + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),pixel.rgb * (1.0 / 12.92),lessThan(pixel,vec3(0.04045)));
}

vec4 ordered_grid_super_sampling(sampler2D p_texture, vec2 p_uv, float p_bias) {
	vec2 dx = dFdx(p_uv);
	vec2 dy = dFdy(p_uv);
	
	const vec2 UV_OFFSETS = vec2(0.125, 0.375);
	
	vec2 offset_uv = vec2(0.0, 0.0);
	
	vec4 color;
	offset_uv.xy = p_uv + UV_OFFSETS.x * dx + UV_OFFSETS.y * dy;
	color += texture(p_texture, offset_uv, p_bias);
	offset_uv.xy = p_uv - UV_OFFSETS.x * dx - UV_OFFSETS.y * dy;
	color += texture(p_texture, offset_uv, p_bias);
	offset_uv.xy = p_uv + UV_OFFSETS.y * dx - UV_OFFSETS.x * dy;
	color += texture(p_texture, offset_uv, p_bias);
	offset_uv.xy = p_uv - UV_OFFSETS.y * dx + UV_OFFSETS.x * dy;
	color += texture(p_texture, offset_uv, p_bias);
	
	color *= 0.25;
	
	return color;
}

vec4 passthrough_sampling(sampler2D p_texture, vec2 p_uv, float p_bias) {
	vec4 color = texture(p_texture, p_uv);
	return color;
}

void fragment() {
//  FIXME: iFire 2021-11-07 
//	vec4 color = ordered_grid_super_sampling(texture_albedo, UV, bias);
	vec4 color = passthrough_sampling(texture_albedo, UV, bias);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.5;
}
