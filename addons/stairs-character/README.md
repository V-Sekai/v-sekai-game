# Stairs Character

A simple to use class that enables your CharacterBody3D to handle stairs properly.

Mainly tested with the Jolt physics engine and cylinder colliders, not guaranteed to work well with anything else - but try it!

## Usage instructions:

1. Make your character controller extend `StairsCharacter` instead of `CharacterBody3D`.
2. Ensure your character's collider is named 'Collider'.
3. Every frame, set `desired_velocity` to the desired direction of movement.
4. Call `move_and_stair_step()` instead of calling `move_and_slide()`.
5. Done!
