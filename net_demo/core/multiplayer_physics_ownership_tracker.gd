extends Node

# This singleton is run exclusively on the host and tracks requests
# for authority of physics objects, then dispatches them each frame.

var queued_authority_request = {}

func request_authority(p_sync_node: MultiplayerSynchronizer, p_peer_id: int) -> void:
	queued_authority_request[p_sync_node] = p_peer_id
	
func flush_authority_requests() -> void:
	for sync_node in queued_authority_request:
		if sync_node:
			sync_node.rpc("assign_authority", queued_authority_request[sync_node])
		
	queued_authority_request.clear()

func _physics_process(_delta: float) -> void:
	flush_authority_requests()
