// Original source, from Google Inc. under the Apache 2.0 license.
// https://github.com/ChristophGeske/ARCoreInsideOutTrackingGearVr/blob/master/VuforiaTracking(Experimental)/Assets/DaydreamElements/Elements/Tunneling/Shaders/VignetteIrisGradient.shader
// constants from:
// https://github.com/ChristophGeske/ARCoreInsideOutTrackingGearVr/blob/master/VuforiaTracking(Experimental)/Assets/DaydreamElements/Elements/Tunneling/Scripts/TunnelingVignette.cs
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


// Copyright 2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

shader_type spatial;
render_mode skip_vertex_transform, depth_test_disabled, unshaded, cull_front;

varying float alpha;

// Gradient texture.
uniform sampler2D albedo_texture: source_color, hint_default_black;

uniform float current_fov = 100.0;
uniform float current_fade_fov = 6.5;
uniform float iris_distance : hint_range(3,10) = 5.0;
uniform float vignette_alpha = 1.0;

void vertex () {
	vec2 vignette_min_max = vec2(clamp(current_fov / 180.0, 0.0, 1.0), 180.0 / (PI * current_fade_fov));
	float v_vertex_y = VERTEX.y;
	float scaled_location = PI/2.0 * ((v_vertex_y * (1.0 - vignette_min_max.x) + vignette_min_max.x));
	float xzDist = iris_distance * sin(scaled_location);
	float yDist = iris_distance * -cos(scaled_location) - 1.0;
	VERTEX = vec3(xzDist * VERTEX.x, yDist, xzDist * VERTEX.z); // vec3(VERTEX.xz, VERTEX.y - 0.5).xzy;//

	// The blending size in radians, scaled by the size of the blend region.
	float val = clamp(vignette_min_max.y * v_vertex_y * (1.0 - vignette_min_max.x), 0.0, 1.0);
	val = val * val * (3.0 - (2.0 * val));  ///cubic (smoothstep)
	alpha = (val * vignette_alpha);

	// Calculate view direction.
	VERTEX = mat3(vec3(1,0,0),vec3(0,0,1),vec3(0,-1,0)) * VERTEX;
	vec3 view_direction = mat3(INV_VIEW_MATRIX) * normalize(VERTEX);
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * inverse(VIEW_MATRIX * MODEL_MATRIX) * vec4(VERTEX, 1.0);
	POSITION.z = 0.5;

	UV = 0.5 * vec2(1.0, view_direction.y + 1.0);
}

void fragment () {
    ALBEDO = texture(albedo_texture, UV).rgb;
    ALPHA = alpha;
}