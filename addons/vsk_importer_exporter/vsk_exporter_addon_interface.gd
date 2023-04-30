@tool
extends RefCounted

const vsk_exporter_addon_const = preload("vsk_exporter_addon.gd")

var exporter_addons: Array = []


func preprocess_scene(p_node: Node, p_validator: RefCounted) -> Node:
	for addon in exporter_addons:
		p_node = addon.preprocess_scene(p_node, p_validator)
	return p_node


func unregister_exporter_addon(p_addon: RefCounted) -> void:  #vsk_exporter_addon_const
	if p_addon:
		if !exporter_addons.has(p_addon):
			printerr("Tried to unregister non-existing addon %s!" % p_addon.get_name())
		else:
			exporter_addons.erase(p_addon)


func register_exporter_addon(p_addon: RefCounted) -> void:  #vsk_exporter_addon_const
	if p_addon:
		if exporter_addons.has(p_addon):
			printerr("Tried to unregister existing addon %s!" % p_addon.get_name())
		else:
			exporter_addons.push_back(p_addon)
