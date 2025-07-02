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
					if not SarUtils.assert_ok(property.changed.connect(_changed),
						"Could not connect signal 'property.changed' to '_changed'"):
						return

func _init() -> void:
	for property in properties:
		if not SarUtils.assert_ok(property.changed.connect(_changed),
			"Could not connect signal 'property.changed' to '_changed'"):
			return
