@tool
extends Node
class_name VSKPlayerSimulationNameplateAssignerComponent3D

## This component is responsible for tracking when other players have entered
## the scene and will attach nameplates to them.

# TODO: finish implementing.

# Mapping between peer_ids and individual nametag nodes.
var _peer_nametag_table: Dictionary[int, Node] = {}

func _setup_nametag(p_player: VSKGameEntityPlayer3D) -> void:
	if not p_player.is_node_ready():
		await p_player.ready
		
	if not p_player.is_multiplayer_authority():
		var label_3d: Label3D = Label3D.new()
		
		label_3d.text = "Placeholder Nametag"
		label_3d.set_multiplayer_authority(get_multiplayer_authority())
		
		_peer_nametag_table[p_player.get_multiplayer_authority()] = label_3d
		
		p_player.add_child(label_3d)

func _ready() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("VSKPlayers")
	for player: Node in players:
		if player is VSKGameEntityPlayer3D:
			_setup_nametag(player)
			

func _scene_tree_state_notifier_entered(p_node: Node) -> void:
	if p_node is VSKGameEntityPlayer3D:
		_setup_nametag(p_node)

func _scene_tree_state_notifier_exited(p_node: Node) -> void:
	if p_node is VSKGameEntityPlayer3D:
		var peer_id: int = p_node.get_multiplayer_authority()
		if _peer_nametag_table.has(peer_id):
			_peer_nametag_table.erase(peer_id)
