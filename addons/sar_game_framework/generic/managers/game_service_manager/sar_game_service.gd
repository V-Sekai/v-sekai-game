@tool
extends Node
class_name SarGameService

func _emit_session_request_renew_started(p_request: SarGameServiceRequest) -> void:
	session_renew_started.emit(p_request)
	
func _emit_session_request_complete(p_request: SarGameServiceRequest, p_result: Dictionary) -> void:
	session_request_complete.emit(p_request, p_result)
	
func _emit_session_deletion_complete(p_request: SarGameServiceRequest, p_result: Dictionary) -> void:
	session_deletion_complete.emit(p_request, p_result)

###

signal session_renew_started(p_request: SarGameServiceRequest)
signal session_request_complete(p_request: SarGameServiceRequest, p_result: Dictionary)
signal session_deletion_complete(p_request: SarGameServiceRequest, p_result: Dictionary)

## Returns the name of the service.
static func get_service_name() -> String:
	return "UnknownGameService"
	
## Attempts to sign-in/register into the service. A SarGameServiceRequestObject created
## from the service required to keep track of the individual request,
## and a Dictionary containing service-specific sign in data, should be
## passed in as a parameters. The method may await a coroutine,
## but will return a dictionary containing the result, or an empty one if
## the action failed outright.
func sign_in(_service_request: SarGameServiceRequest, _sign_in_data: Dictionary) -> Dictionary:
	return {}

func register(_service_request: SarGameServiceRequest, _register_data: Dictionary) -> Dictionary:
	return {}

## Creates a service request object. This can then be passed into
## into the request API to keep track of the status and callbacks of
## the request.
func create_request(_data: Dictionary) -> SarGameServiceRequest:
	return SarGameServiceRequest.new()

## Will attempt to cancel an ongoing service request. Will return true
## if the request was active and subsequently stopped, and false if
## the request wasn't active and there was nothing to stop.
func stop_request(_service_request: SarGameServiceRequest) -> bool:
	return false

## Returns true if the request is active.
func is_request_active(_service_request: SarGameServiceRequest) -> bool:
	return false
