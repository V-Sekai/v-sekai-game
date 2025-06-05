@tool
extends SarGameEntityComponent
class_name VSKGameEntityComponentDebugInfo

@export var posession_info_labels: Array[Label3D] = [null]

func _update_possession_info_label(p_soul: SarSoul) -> void:
	if not Engine.is_editor_hint():
		for posession_info_label in posession_info_labels:
			if not p_soul:
				posession_info_label.text = "Unpossessed"
			else:
				posession_info_label.text = "Possessed by: %s" % p_soul.get_name()

func _on_possessed_by_soul(p_soul: SarSoul) -> void:
	if not Engine.is_editor_hint():
		if not is_node_ready():
			await ready
		_update_possession_info_label(p_soul) 

func _ready() -> void:
	if not Engine.is_editor_hint():
		_update_possession_info_label(null)
