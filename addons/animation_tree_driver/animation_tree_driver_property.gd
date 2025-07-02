@tool
extends Resource
class_name AnimationTreeDriverProperty

enum PropertyType {
	BOOLEAN,
	FLOAT,
	INT,
	VECTOR_2,
	VECTOR_3
}

func _changed():
	emit_changed()

@export var property_type: PropertyType = PropertyType.BOOLEAN:
	set(p_property_type):
		if property_type != p_property_type:
			property_type = p_property_type
			_changed()

@export var property_name: String = "":
	set(p_property_name):
		if property_name != p_property_name:
			property_name = p_property_name
			_changed()
		
@export var controllers: Array[AnimationTreeDriverPropertyController] = []:
	set(p_controllers):
		if p_controllers != controllers:
			for controller in controllers:
				if controller:
					controller.changed.disconnect(_changed)
				
			controllers = p_controllers
				
			for controller in controllers:
				if controller:
					if not SarUtils.assert_ok(controller.changed.connect(_changed),
						"Could not connect signal 'controller.changed' to '_changed'"):
						return
				
func _init() -> void:
	for controller in controllers:
		if not SarUtils.assert_ok(controller.changed.connect(_changed),
			"Could not connect signal 'controller.changed' to '_changed'"):
			return
