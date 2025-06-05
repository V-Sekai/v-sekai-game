@tool
extends SarGameEntityComponent
class_name VSKGameEntityComponentAvatarParameters

const FIXED_PARAMETERS = ["velocity", "grounded"]

@export var avatar_component: VSKGameEntityComponentAvatar3D = null
@export var parameters_snapshot: SarSnapshot = null

func _on_model_component_model_changed(_new_model: SarModel3D) -> void:
	pass
	
func _update_parameters_snapshot() -> void:
	if avatar_component and avatar_component.get_model_node():
		var avatar: VSKAvatar3D = avatar_component.get_model_node() as VSKAvatar3D
		if avatar:
			for parameter_name in FIXED_PARAMETERS:
				var variant: Variant = avatar.animation_tree_driver.get(parameter_name)
				var value_snapshot: SarValueSnapshot = parameters_snapshot.get_node_or_null(parameter_name)
				if value_snapshot:
					value_snapshot.set_value(variant)

# This is intended to be called by a signal received on remote peers. 
func _on_parameters_updated() -> void:
	if not Engine.is_editor_hint() and not is_multiplayer_authority():
		if avatar_component and avatar_component.get_model_node():
			var avatar: VSKAvatar3D = avatar_component.get_model_node() as VSKAvatar3D
			if avatar:
				for parameter_name in FIXED_PARAMETERS:
					var value_snapshot: SarValueSnapshot = parameters_snapshot.get_node_or_null(parameter_name)
					if value_snapshot:
						var variant: Variant = value_snapshot.get_value()
						avatar.animation_tree_driver.set(parameter_name, variant)

func _process(_delta: float) -> void:
	_update_parameters_snapshot()

func _ready() -> void:
	if not Engine.is_editor_hint() and is_multiplayer_authority():
		set_process(true)
	else:
		set_process(false)
