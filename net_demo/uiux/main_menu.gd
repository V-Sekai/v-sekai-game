extends Control

@export var ip_path: NodePath = NodePath()
@export var port_path: NodePath = NodePath()
@export var max_player_path: NodePath = NodePath()
@export var dedicated_server_path: NodePath = NodePath()

func _on_HostButton_pressed():
	GameManager.host_server(get_node(port_path).value, get_node(max_player_path).value, get_node(dedicated_server_path).is_pressed())

func _on_JoinButton_pressed():
	GameManager.join_server(get_node(ip_path).text, get_node(port_path).value)
