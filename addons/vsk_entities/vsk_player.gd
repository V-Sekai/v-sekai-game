extends CharacterBody3D

@export var player_movement_controller: Node = null
@export var collision_shape: CollisionShape3D = null
@export var camera: Camera3D = null

@export var spawn_sync_node: MultiplayerSynchronizer = null
@export var update_sync_node: MultiplayerSynchronizer = null

##
## Assigns the correct authority ID based on the name of the
## node.
##
func _setup_authority() -> void:
	# Modifiy the player's authority based on its name.
	if name.begins_with("Player_"):
		var id_string: String = name.lstrip("Player_")
		if id_string.is_valid_int():
			set_multiplayer_authority(id_string.to_int())
	
	# The MultiplayerSynchronizerSpawn node show always have its authority
	# owned by the host
	if spawn_sync_node:
		spawn_sync_node.set_multiplayer_authority(1)

func _enter_tree() -> void:
	# This derives the correct authority for this node based on the node's name.
	_setup_authority()

func _ready() -> void:
	if collision_shape:
		collision_shape.disabled = not is_multiplayer_authority()
	else:
		printerr("Collision shape not found!")
	
	if is_multiplayer_authority():
		pass
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		if player_movement_controller:
			player_movement_controller.queue_free()
		else:
			printerr("Player movement controller not found!")
		
		if camera:
			camera.queue_free()
			camera.get_parent().remove_child(camera)
		else:
			printerr("Player camera controller not found!")
