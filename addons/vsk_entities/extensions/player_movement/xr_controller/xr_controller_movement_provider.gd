extends Node

@export var movement_controller: Node

var _origin: XROrigin3D = null

# Controller node
@onready var _controller: XRController3D = get_parent()

func _ready():
	assert(_controller)
	_origin = _controller.get_parent()
	assert(movement_controller)
