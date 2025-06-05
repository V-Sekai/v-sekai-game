@tool
extends Control
class_name VSKTextInput

@export_group("Internal Nodes")
@export var _line_edit: LineEdit = null
@export_group("")

func _validate_property(property: Dictionary) -> void:
	if Engine.is_editor_hint():
		if is_inside_tree():
			if owner == get_tree().edited_scene_root and property.name.begins_with("_"):
				property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_property_list() -> Array[Dictionary]:
	var class_property_list: Array[Dictionary] = ClassDB.class_get_property_list(get_class())
	var extra_property_list: Array[Dictionary] = []
	
	if _line_edit:
		var line_edit_property_list: Array = _line_edit.get_property_list()
		for le_prop: Dictionary in line_edit_property_list:
			var valid_prop: Dictionary = le_prop
			for prop: Dictionary in class_property_list:
				if le_prop["name"] == prop["name"]:
					valid_prop = {}
					break
			if not valid_prop.is_empty():
				extra_property_list.append(le_prop)
					
	return extra_property_list
