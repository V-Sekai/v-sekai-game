@tool
extends EditorScenePostImportPlugin

func _get_import_options(path: String)->void:
	add_import_option_advanced(TYPE_STRING, 
	"subdivision/import_as", 
	"ImporterMesh (bake at import)", 
	PROPERTY_HINT_ENUM, 
	"BakedSubdivMesh (bake at runtime),ImporterMesh (bake at import)")
	
	add_import_option_advanced(TYPE_INT,
	"subdivision/subdivision_level",
	0,
	PROPERTY_HINT_RANGE,
	"0,6")

func _pre_process(scene: Node):
	var subdiv_import_option=get_option_value("subdivision/import_as")
	var subdiv_level=get_option_value("subdivision/subdivision_level")
	var subdiv_converter=load("res://addons/godot_subdiv/subdiv_converter.gd").new(subdiv_import_option, subdiv_level)
	if scene:
		subdiv_converter.convert_importer_mesh_instances_recursively(scene)
