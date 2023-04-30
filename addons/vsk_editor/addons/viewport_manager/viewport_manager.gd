@tool
extends Node


func create_viewport(p_name):
	var viewport = SubViewport.new()
	viewport.set_name(p_name)
	add_child(viewport, true)

	return viewport
