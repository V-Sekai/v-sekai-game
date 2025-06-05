@tool
class_name AnimationTreeStateMachinePlaybackPropertyWriter
extends Node

@export var animation_tree_driver: AnimationTreeDriver = null
@export var table: AnimationTreeStateMachinePlaybackPropertyTable = null

func _update_properties() -> void:
	var animation_tree: AnimationTree = animation_tree_driver.animation_tree
	
	if animation_tree_driver and animation_tree:
		for property in table.properties:
			var playback: AnimationNodeStateMachinePlayback = animation_tree.get(property.playback_path)
			if playback:
				if property.playback_play_position_property_name:
					animation_tree_driver.set(property.playback_play_position_property_name, playback.get_current_play_position())
				if property.playback_delta_property_name:
					animation_tree_driver.set(property.playback_delta_property_name, playback.get_current_delta())
				if property.playback_length_property_name:
					animation_tree_driver.set(property.playback_length_property_name, playback.get_current_length())

func _on_mixer_applied() -> void:
	_update_properties()
