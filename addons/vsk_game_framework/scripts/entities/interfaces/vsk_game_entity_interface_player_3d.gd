@tool
extends SarGameEntityInterfaceCharacter3D
class_name VSKGameEntityInterfacePlayer3D

@export var avatar_parameters_component: VSKGameEntityComponentAvatarParameters = null
@export var avatar_sync_component: VSKGameEntityComponentAvatarSync = null

func get_avatar_parameters_component() -> VSKGameEntityComponentAvatarParameters:
	return avatar_parameters_component

func get_avatar_sync_component() -> VSKGameEntityComponentAvatarSync:
	return avatar_sync_component
