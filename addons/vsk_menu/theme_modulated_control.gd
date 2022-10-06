@tool
extends Control

func get_encompasing_theme(p_node: Node) -> Theme:
	if p_node == null:
		push_warning("Somehow every Control and Window has null Theme.")
		return Theme.new()

	var current_theme: Theme = null
	if p_node is Control:
		current_theme = p_node.theme
	if p_node is Window:
		current_theme = p_node.theme

	var node_parent: Object = p_node.get_parent()
	if current_theme:
		return current_theme
	elif node_parent == null and p_node.get_viewport() != p_node:
		return get_encompasing_theme(p_node.get_viewport())
	elif typeof(node_parent) == TYPE_OBJECT and node_parent != null:
		return get_encompasing_theme(node_parent)
	else:
		return get_encompasing_theme(null)

func _ready():
	var current_theme: Theme = get_encompasing_theme(self)

	set_modulate(current_theme.get_color("modulate_color", "Global"))
