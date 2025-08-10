# godot-humanoid

Work in progress with humanoid muscle encoding to/from quaternion. We can use this in the future for more efficient network serialization (similar to ShaderMotion's format, or networked IK)

The code is using the list of allowed muscle axes in Unity, and Unity does not permit certain "inhuman" movement such as bending the knee sideways or twisting the shoulder, so that is where the desyncs come from between the white (original) and pink (encoded/decoded) skeletons. My code tries to do its best to compensate by passing the quaternion delta to the child bones where necessary.

Godot humanoid is a mix of effort by lox9973, Saracen and Lyuma.
