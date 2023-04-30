extends "res://addons/vsk_importer_exporter/vsk_pipeline.gd"  # vsk_pipeline.gd

@export var database_id: String = ""


func _init(p_database_id: String):
	database_id = p_database_id
