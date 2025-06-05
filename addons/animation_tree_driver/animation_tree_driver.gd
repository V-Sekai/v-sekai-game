@tool
extends Node
class_name AnimationTreeDriver

## This class is intended to provide a table of properties used to drive the
## the parameters inside an AnimationTree.
##
## The idea is to provide one unified table of input properties which can
## manipulated to drive many different parameters inside an AnimationTree,
## with one property able to mutate into different forms for different
## properties.
## Note: this is highly experimental and subject to change since there are
## various approaches to driving blend tree parameters used here which
## might be better suited to metadata tagging or in-engine features.
## We can already drive the state machine via the expression parser,
## so one potential plan is introduce expression parsing in blend trees
## directly, which would likely render the concept of 'controllers' here
## an obsolete feature.

# For faster lookups (TODO: implement)
# var _property_hash_table: Dictionary = {}

var _property_values: Dictionary[String, Variant] = {}

func _changed() -> void:
	if Engine.is_editor_hint():
		if animation_tree:
			for prop: AnimationTreeDriverProperty in property_table.properties:
				if prop:
					for controller: AnimationTreeDriverPropertyController in prop.controllers:
						if not controller.animation_tree_property_path.is_empty() and controller.value:
							animation_tree[controller.animation_tree_property_path] = controller.value.get_value(_property_values[prop.property_name])

static func _get_variant_type_for_driver_property_type(p_type: AnimationTreeDriverProperty.PropertyType) -> Variant.Type:
	match p_type:
		AnimationTreeDriverProperty.PropertyType.BOOLEAN:
			return TYPE_BOOL
		AnimationTreeDriverProperty.PropertyType.INT:
			return TYPE_INT
		AnimationTreeDriverProperty.PropertyType.FLOAT:
			return TYPE_FLOAT
		AnimationTreeDriverProperty.PropertyType.VECTOR_2:
			return TYPE_VECTOR2
		AnimationTreeDriverProperty.PropertyType.VECTOR_3:
			return TYPE_VECTOR3
		_:
			return TYPE_BOOL
			
func _add_default_value_for_property(p_property: AnimationTreeDriverProperty) -> void:
	match (p_property.property_type):
		AnimationTreeDriverProperty.PropertyType.BOOLEAN:
			_property_values[p_property.property_name] = false
		AnimationTreeDriverProperty.PropertyType.INT:
			_property_values[p_property.property_name] = 0
		AnimationTreeDriverProperty.PropertyType.FLOAT:
			_property_values[p_property.property_name] = 0.0
		AnimationTreeDriverProperty.PropertyType.VECTOR_2:
			_property_values[p_property.property_name] = Vector2(0.0, 0.0)
		AnimationTreeDriverProperty.PropertyType.VECTOR_3:
			_property_values[p_property.property_name] = Vector3(0.0, 0.0, 0.0)
			
func _get(p_property: StringName) -> Variant:
	if property_table:
		for prop: AnimationTreeDriverProperty in property_table.properties:
			if prop:
				if prop.property_name == p_property:
					if _property_values.has(p_property):
						if typeof(_property_values[p_property]) != _get_variant_type_for_driver_property_type(prop.property_type):
							_add_default_value_for_property(prop)
					else:
						_add_default_value_for_property(prop)
						
					return _property_values[p_property]
			
	return null
	
func _set(p_property: StringName, p_value: Variant) -> bool:
	if property_table:
		for prop: AnimationTreeDriverProperty in property_table.properties:
			if prop:
				if prop.property_name == p_property:
					_property_values[p_property] = p_value
					if animation_tree:
						for controller: AnimationTreeDriverPropertyController in prop.controllers:
							if not controller.animation_tree_property_path.is_empty() and controller.value:
								if controller.animation_tree_property_path in animation_tree:
									animation_tree[controller.animation_tree_property_path] = controller.value.get_value(p_value)
								else:
									printerr("%s is not a valid animation tree parameter." % controller.animation_tree_property_path)
					return true
	return false
					
func _get_property_list() -> Array[Dictionary]:
	var used_names: PackedStringArray = PackedStringArray()
	var properties: Array[Dictionary] = []
	
	if property_table:
		for prop: AnimationTreeDriverProperty in property_table.properties:
			if prop:
				if not used_names.has(prop.property_name):
					if not prop.property_name.is_empty():
						properties.append({
							"name": prop.property_name,
							"type": _get_variant_type_for_driver_property_type(prop.property_type),
							"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
							"hint": PROPERTY_HINT_NONE,
							"hint_string": ""
						})
						used_names.append(prop.property_name)
		
	return properties

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	
	if animation_tree:
		var advance_expression_node: Node = animation_tree.get_node_or_null(animation_tree.advance_expression_base_node)
		if advance_expression_node != self:
			warnings.push_back("The associated AnimationTree's advance expression base node is not set to this.")
	else:
		warnings.push_back("No AnimationTree assigned to this driver.")
		
	return warnings
	
func _property_edited(p_property: String) -> void:
	if EditorInterface.get_inspector().get_edited_object() is AnimationTree:
		if p_property == "advance_expression_base_node":
			update_configuration_warnings()
	
func _ready() -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_inspector().property_edited.connect(_property_edited)
##

## Reference the AnimationTree this node is meant to drive and
## the tree is meant to reference.
@export var animation_tree: AnimationTree = null:
	set(p_animation_tree):
		animation_tree = p_animation_tree

## The property able resource containing the global property list meant 
## to drive the AnimationTree.
@export var property_table: AnimationTreeDriverPropertyTable = null:
	set(p_property_table):
		if p_property_table != property_table:
			if property_table:
				property_table.changed.disconnect(_changed)
				
			property_table = p_property_table
			
			if property_table:
				assert(property_table.changed.connect(_changed) == OK)
