extends Node
class_name VSKSimulationSceneRespawnerComponent3D

## This class is designed for respawning the player entity.

func _respawn() -> void:
	if simulation:
		var game_session_manager: SarGameSessionManager = get_tree().get_first_node_in_group("game_session_managers")
		if game_session_manager:
			# Go to the game session manager and attempt to find a valid spawn point.
			var spawn_transform: Transform3D = game_session_manager.find_valid_spawn_transform_for_peer_entity_3d(get_multiplayer_authority())
			
			# Reset the transform and interpolation.
			var game_entity: SarGameEntity3D = simulation.get_game_entity_interface().get_game_entity()
			if game_entity:
				# TODO: I had assumed that the way we set up the transform notification callbacks
				# on the main entity, we would be informed immediately when the transform changed,
				# but it seems to not be working. Need to investiate further. Until then,
				# just modify the position of the physics position directly.
				var movement_component: SarGameEntityComponentVesselMovement3D = simulation.get_game_entity_interface().get_movement_component()
				if movement_component:
					# Sync physics position with visual transform
					movement_component.set_physics_position(spawn_transform.origin)
					movement_component.previous_physics_position = spawn_transform.origin
				
				game_entity.teleport.bind(spawn_transform).rpc()
			
			# TODO: we likely want send some kind of teleport message to other peers that we
			# have respawned to prevent respawn players flying across the map.
			
			# Emit the signal that we have respawned.
			respawned.emit()
		else:
			printerr("Attempted to respawn, but a game session manager could not be found.")

func request_respawn() -> void:
	_respawn()
		
###

## Reference to the root simulation.
@export var simulation: SarSimulationVessel3D = null

## Emitted when the player respawns.
signal respawned
