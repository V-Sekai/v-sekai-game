@tool
extends Resource
class_name VSKAvatarParameter

enum ParameterType {
	BOOL,
	INT,
	FLOAT,
	VECTOR2,
	VECTOR3,
}

@export var parameter_name: String = ""
@export var parameter_type: ParameterType = ParameterType.BOOL
@export var parameter_default_value: Variant = false
@export var parameter_should_sync: bool = false
