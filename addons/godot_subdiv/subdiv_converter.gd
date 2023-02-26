
var importer: TopologyDataImporter
var import_mode: int
var subdiv_level: int

func _init(import_mode_string: String, p_subdiv_level: int):
	self.importer=TopologyDataImporter.new()
	self.import_mode=_convert_string_to_import_mode(import_mode_string)
	self.subdiv_level=p_subdiv_level
	
func _convert_string_to_import_mode(enum_string: String) -> int:
	match enum_string:
		"BakedSubdivMesh (bake at runtime)":
			return TopologyDataImporter.BAKED_SUBDIV_MESH
		"ImporterMesh (bake at import)":
			return TopologyDataImporter.IMPORTER_MESH
		_:
			return -1

func convert_importer_mesh_instances_recursively(node: Node):
	for i in node.get_children():
		convert_importer_mesh_instances_recursively(i)
		if i is ImporterMeshInstance3D:
			importer.convert_importer_meshinstance_to_subdiv(i, import_mode, subdiv_level)
