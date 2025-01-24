extends MultiplayerSpawner

func _ready() -> void:
	add_to_group(Group.SPAWNER)

#func _on_spawned(node: Node) -> void:
	#Controller.broadcast_actor_render.rpc(node.peer_id, node.map)
