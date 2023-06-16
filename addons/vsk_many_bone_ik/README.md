# Constraints

| Step | Description                                                                             | Code Snippet                                                                     |
| ---- | --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| 1    | Traverse the tree of `Transform3D` nodes representing the humanoid skeleton.            | `process_skeleton(skeleton_root)`                                                |
| 2    | For each joint, calculate the swing and twist rotations using quaternion decomposition. | `var swing_quat, twist_quat = decompose_swing_twist(local_rotation, Vector3.UP)` |
| 3    | Rotate the top of the hinge or ball socket to face the forward axis.                    | `transform_node.look_at(target_position, Vector3.UP)`                            |
| 4    | Select the correct version of mirrored and chiral sockets.                              | `select_correct_socket_version(transform_node)`                                  |
| 5    | Return the swing rotation and the range rotations as arrays.                            | `return swing_rotatation_constraint, range_rotation_constraint`                  |

## Chiral mirror vs direct mirror

| Description | Socket Type     | Joints                                                                                                                                                          |
| ----------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CM          | Ball-and-socket | Hips, UpperChest, Chest, Spine, LeftUpperLeg, RightUpperLeg, LeftFoot, RightFoot, LeftShoulder, RightShoulder, LeftUpperArm, RightUpperArm, LeftHand, RightHand |
| CM          | Pivot           | Head, Neck                                                                                                                                                      |
| DM          | Hinge           | LeftLowerLeg, RightLowerLeg, LeftLowerArm, RightLowerArm                                                                                                        |
|  |

## Joint Sockets

| Joint         | Socket Type     | Description                                                                                                                                                                                                          |
| ------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hips          | Ball-and-socket | The hips can tilt forward and backward, allowing the legs to swing in a wide arc during walking or running. They can also move side-to-side, enabling the legs to spread apart or come together.                     |
| Head          | Pivot           | The head can tilt up (look up) and down (look down), and rotate side-to-side, enabling the character to look left and right.                                                                                         |
| Neck          | Pivot           | The neck can tilt up and down, allowing the head to look up and down, and rotate side-to-side for looking left and right.                                                                                            |
| UpperChest    | Ball-and-socket | The upper chest can tilt forward and backward, allowing for natural breathing and posture adjustments.                                                                                                               |
| Chest         | Ball-and-socket | The chest can tilt forward and backward, allowing for natural breathing and posture adjustments.                                                                                                                     |
| Spine         | Ball-and-socket | The spine can tilt forward and backward, allowing for bending and straightening of the torso.                                                                                                                        |
| LeftUpperLeg  | Ball-and-socket | The upper leg can swing forward and backward, allowing for steps during walking and running, and rotate slightly for sitting.                                                                                        |
| RightUpperLeg | Ball-and-socket | The upper leg can swing forward and backward, allowing for steps during walking and running, and rotate slightly for sitting.                                                                                        |
| LeftLowerLeg  | Hinge           | The knee can bend and straighten, allowing the lower leg to move towards or away from the upper leg during walking, running, and stepping.                                                                           |
| RightLowerLeg | Hinge           | The knee can bend and straighten, allowing the lower leg to move towards or away from the upper leg during walking, running, and stepping.                                                                           |
| LeftFoot      | Ball-and-socket | The ankle can tilt up (dorsiflexion) and down (plantarflexion), allowing the foot to step and adjust during walking and running. It can also rotate slightly inward or outward (inversion and eversion) for balance. |
| RightFoot     | Ball-and-socket | The ankle can tilt up (dorsiflexion) and down (plantarflexion), allowing the foot to step and adjust during walking and running. It can also rotate slightly inward or outward (inversion and eversion) for balance. |
| LeftShoulder  | Ball-and-socket | The shoulder can tilt forward and backward, allowing the arms to swing in a wide arc. They can also move side-to-side, enabling the arms to extend outwards or cross over the chest.                                 |
| RightShoulder | Ball-and-socket | The shoulder can tilt forward and backward, allowing the arms to swing in a wide arc. They can also move side-to-side, enabling the arms to extend outwards or cross over the chest.                                 |
| LeftUpperArm  | Ball-and-socket | The upper arm can swing forward and backward, allowing for reaching and swinging motions. It can also rotate slightly for more natural arm movement.                                                                 |
| RightUpperArm | Ball-and-socket | The upper arm can swing forward and backward, allowing for reaching and swinging motions. It can also rotate slightly for more natural arm movement.                                                                 |
| LeftLowerArm  | Hinge           | The elbow can bend and straighten, allowing the forearm to move towards or away from the upper arm during reaching and swinging motions.                                                                             |
| RightLowerArm | Hinge           | The elbow can bend and straighten, allowing the forearm to move towards or away from the upper arm during reaching and swinging motions.                                                                             |
| LeftHand      | Ball-and-socket | The wrist can tilt up and down, allowing the hand to move towards or away from the forearm. It can also rotate slightly, enabling the hand to twist inward or outward for grasping and gesturing.                    |
| RightHand     | Ball-and-socket | The wrist can tilt up and down, allowing the hand to move towards or away from the forearm. It can also rotate slightly, enabling the hand to twist inward or outward for grasping and gesturing.                    |
