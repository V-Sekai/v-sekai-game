@tool
extends Node
class_name SarGameServiceManager

var _services: Dictionary[String, SarGameService] = {}

###

func add_service(p_service_name: StringName, p_service_class: Script) -> void:
	if _services.has(p_service_name):
		push_error("Duplicate service named %s" % p_service_name)
		return
		
	var base_service_script: Script = p_service_class
	while base_service_script:
		if base_service_script.get_global_name() == "SarGameService":
			break
		base_service_script = base_service_script.get_base_script()
	
	if base_service_script:
		var service: SarGameService = p_service_class.new()
		service.set_name(p_service_name)
		add_child(service)
				
		_services[p_service_name] = service
		
	else:
		push_error("Attempted to add a class which does not inherit SarService.")
		
func remove_service(p_service_name: String) -> void:
	if _services.has(p_service_name):
		var service: SarGameService = _services.get(p_service_name)
		if service.is_inside_tree():
			remove_child(service)
		_services.erase(p_service_name) 
	else:
		push_error("There is no active service named %s." % p_service_name)
		
func get_service(p_service_name: String) -> SarGameService:
	if _services.has(p_service_name):
		return _services.get(p_service_name)
		
	return null
