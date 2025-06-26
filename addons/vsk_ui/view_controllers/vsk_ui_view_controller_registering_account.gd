#func _ready() -> void::
#	GodotUro.register_async()

@tool
extends SarUIViewController
class_name VSKUIViewControllerRegistering

enum RegisterResult {
	PENDING,
	OK,
	FAILED,
}

signal sign_up_complete(p_result: RegisterResult, p_id: String)

var _domain: String = ""
var _username: String = ""

var _service: SarGameService = null
var _request: SarGameServiceRequest = null
var _register_result: RegisterResult = RegisterResult.PENDING

func will_disappear() -> void:
	if _service and _request:
		_service.stop_request(_request)
		
	if _service.session_request_complete.is_connected(_session_request_complete):
		_service.session_request_complete.disconnect(_session_request_complete)

func _process_register_result() -> void:
	if _register_result != RegisterResult.PENDING:
		get_navigation_controller().pop_view_controller(true)
		
		sign_up_complete.emit(_register_result, "%s@%s" % [_username, _domain])

func _session_request_complete(p_request: SarGameServiceRequest, p_result: Dictionary) -> void:
	if not is_node_ready():
		await ready
	
	if p_request != _request:
		return
		
	if _service.session_request_complete.is_connected(_session_request_complete):
		_service.session_request_complete.disconnect(_session_request_complete)
		
	if p_result.get("response_code", -1) == HTTPClient.RESPONSE_OK:
		_username = p_result.get("user_username", "")
		if not _username.is_empty():
			_register_result = RegisterResult.OK
		else:
			_register_result = RegisterResult.FAILED
	else:
		_register_result = RegisterResult.FAILED
		
	_process_register_result() 
	
	return
		
func _ready() -> void:
	super._ready()

###

## Call this method to request a registration with a game service.
func register(p_game_service: SarGameService, p_register_data: Dictionary) -> void:
	assert(_service == null)
	assert(_request == null)
	
	_service = p_game_service
	
	assert(_service.session_request_complete.connect(_session_request_complete) == OK)
	
	_domain = p_register_data.get("domain", "")
	_username = ""
	
	_request = p_game_service.create_request({"domain":_domain})
	p_game_service.register(_request, p_register_data)
