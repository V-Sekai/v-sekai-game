# import_plugin.gd
# This plugin adds the custom godot-subdiv.importer and will not change the scene importer at all.
@tool
extends EditorImportPlugin


func _get_importer_name():
	return "godot-subdiv.importer"

func _get_visible_name():
	return "Godot Subdiv Importer"

func _get_recognized_extensions():
	return ["glb", "gltf"]

func _get_save_extension():
	return "scn"

func _get_resource_type():
	return "PackedScene"

func _get_preset_count():
	return 1

func _get_preset_name(i):
	return "Default"
	
func _get_priority():
	return 0
	
func _get_import_order():
	return IMPORT_ORDER_SCENE
	
func _get_option_visibility(path, option_name, options):
	return true
	
func _get_import_options(path, preset_index):
	var options=[
		{
		"name": "import_as",
		"property_hint": PROPERTY_HINT_ENUM,
		"default_value": "BakedSubdivMesh",
		"hint_string": "BakedSubdivMesh (bake at runtime),ImporterMesh (bake at import)"
		},
		{
		"name": "subdivision_level",
		"default_value": 0,
		"property_hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,6"
		}
	]
	return options

func _import(source_file, save_path, options, platform_variants, gen_files):
	var gltf := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	gltf.append_from_file(source_file, gltf_state, 0)
	var node=gltf.generate_scene(gltf_state)
	#set root name, otherwise throws name is empty
	node.name=source_file.get_file().get_basename()
	
	var subdiv_level=options["sudbivision_level"]
	
	var subdiv_converter = load("res://addons/godot_subdiv/subdiv_converter.gd").new(options["import_as"], subdiv_level)

	if node!=null:
		subdiv_converter.convert_importer_mesh_instances_recursively(node)
	else:
		print("GLTF importer failed, so could not run convert code")
	
	var packed=PackedScene.new()
	packed.pack(node)
	node.free()
	
	ResourceSaver.save(packed, save_path+".scn")
	



