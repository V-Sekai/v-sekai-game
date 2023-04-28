// Original source, from Google Inc. under the Apache 2.0 license.
// https://github.com/ChristophGeske/ARCoreInsideOutTrackingGearVr/blob/master/VuforiaTracking(Experimental)/Assets/DaydreamElements/Elements/Tunneling/Shaders/VignetteIrisGradient.shader
// constants from:
// https://github.com/ChristophGeske/ARCoreInsideOutTrackingGearVr/blob/master/VuforiaTracking(Experimental)/Assets/DaydreamElements/Elements/Tunneling/Scripts/VignetteCage.cs
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
render_mode skip_vertex_transform, depth_test_disabled, unshaded;

// Gradient texture.
uniform vec4 cage_color: source_color = vec4(1);
uniform float current_fov = 100.0;
uniform float current_fade_fov = 6.5;
uniform float vignette_alpha = 1.0;
uniform float floor_offset = 0.0;

varying float alpha;
varying float view_dot_camera;
varying vec2 vignette_pixel;

void vertex () {
	VERTEX = VERTEX;
	// Hack 6dof support into a shader designed for 3dof ;-) ~Lyuma
	VERTEX.y -= floor_offset;
	if (NORMAL.y > 0.5) {
		VERTEX.xz += fract(MODEL_MATRIX[3].xz) - vec2(0.5);
		VERTEX.xz = clamp(VERTEX.xz, -vec2(4.5), vec2(4.5));
	} else {
		VERTEX.xz *= 4.5 / 5.0;
	}
	vignette_pixel = vec2(cos(PI / 180.0 * (current_fov + 3.0 * current_fade_fov) * 0.5f),
		cos(PI / 180.0 * current_fov * 0.5f));
	VERTEX = (MODELVIEW_MATRIX * inverse(VIEW_MATRIX * MODEL_MATRIX) * vec4(mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX) * VERTEX, 1)).xyz;
	view_dot_camera = normalize(-VERTEX).z;

	alpha = pow(COLOR.r, 2.2);
}

void fragment () {
    float tmp_alpha = 1.0 - smoothstep(vignette_pixel.x, vignette_pixel.y, view_dot_camera);
	ALBEDO = cage_color.rgb;
	ALPHA = cage_color.a * alpha * tmp_alpha * tmp_alpha * vignette_alpha;
}
