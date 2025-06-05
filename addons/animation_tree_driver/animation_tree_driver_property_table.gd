@tool
extends Resource
class_name AnimationTreeDriverPropertyTable

func _changed() -> void:
	emit_changed()

@export var properties: Array[AnimationTreeDriverProperty]:
	set(p_properties):
		if properties != p_properties:
			for property in properties:
				if property:
					property.changed.disconnect(_changed)
				
			properties = p_properties
			
			for property in properties:
				if property:
					assert(property.changed.connect(_changed) == OK)

func _init() -> void:
	for property in properties:
		assert(property.changed.connect(_changed) == OK)
