extends Node

var _player_movement_controller: Node = null
var _origin: XROrigin3D = null

# Controller node
@onready var _controller: XRController3D = get_parent()

func _ready():
	assert(_controller)
	_origin = _controller.get_parent()
	assert(_origin)
	_player_movement_controller = _origin.player_movement_controller
