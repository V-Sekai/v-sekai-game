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
// FIXME: Godot does not support depth_draw_only, and ideally draws before other objects.
render_mode skip_vertex_transform, depth_draw_always, unshaded, cull_front;

const float DEPTH_CULLING_SAFETY_FACTOR = 4.0; //3.0f;

uniform float current_fov = 100.0;
uniform float current_fade_fov = 6.5;
uniform float iris_distance : hint_range(3,10) = 5.0;


void vertex () {
	float vignette_min_max_z = clamp((current_fov + DEPTH_CULLING_SAFETY_FACTOR * current_fade_fov) / 180.0, 0.0, 1.0);
	float v_vertex_y = VERTEX.y;
	float scaled_location = PI/2.0 * ((v_vertex_y * (1.0 - vignette_min_max_z) + vignette_min_max_z));
	float xzDist = iris_distance * sin(scaled_location);
	float yDist = iris_distance * -cos(scaled_location) - 1.0;
	VERTEX = vec3(xzDist * VERTEX.x, yDist, xzDist * VERTEX.z); // vec3(VERTEX.xz, VERTEX.y - 0.5).xzy;//

	// Calculate view direction.
	VERTEX = mat3(vec3(1,0,0),vec3(0,0,1),vec3(0,-1,0)) * VERTEX;
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * inverse(VIEW_MATRIX * MODEL_MATRIX) * vec4(VERTEX, 1.0);
	POSITION.z = 0.0; // on near clip plane
}

void fragment () {
	ALBEDO = vec3(0.7,0.3,1); // make sure we do not see pink.
}