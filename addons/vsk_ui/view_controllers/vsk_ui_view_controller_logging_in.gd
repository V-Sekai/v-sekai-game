@tool
extends SarUIViewController
class_name VSKUIViewControllerLoggingIn

enum LogInResult {
	PENDING,
	OK,
	FAILED,
}

signal sign_in_complete(p_result: LogInResult, p_id: String)

var _domain: String = ""
var _username: String = ""

var _service: SarGameService = null
var _request: SarGameServiceRequest = null
var _log_in_result: LogInResult = LogInResult.PENDING

func will_disappear() -> void:
	if _service and _request:
		_service.stop_request(_request)
		
	if _service.session_request_complete.is_connected(_session_request_complete):
		_service.session_request_complete.disconnect(_session_request_complete)

func _process_log_in_result() -> void:
	if _log_in_result != LogInResult.PENDING:
		get_navigation_controller().pop_view_controller(true)
		
		sign_in_complete.emit(_log_in_result, "%s@%s" % [_username, _domain])

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
			_log_in_result = LogInResult.OK
		else:
			_log_in_result = LogInResult.FAILED
	else:
		_log_in_result = LogInResult.FAILED
		
	_process_log_in_result() 
	
	return
		
func _ready() -> void:
	super._ready()

###

## Call this method to request a sign in with a game service.
func sign_in(p_game_service: SarGameService, p_sign_in_data: Dictionary) -> void:
	assert(_service == null)
	assert(_request == null)
	
	_service = p_game_service
	
	assert(_service.session_request_complete.connect(_session_request_complete) == OK)
	
	_domain = p_sign_in_data.get("domain", "")
	_username = ""
	
	_request = p_game_service.create_request({"domain":_domain})
	p_game_service.sign_in(_request, p_sign_in_data)
