extends MultiplayerSynchronizer

func _ready() -> void:
	#add_visibility_filter(visibility_filter)
	pass
	
func visibility_filter(peer_id: int) -> bool:
	var this_actor = get_tree().get_first_node_in_group(str(peer_id))
	var primary_actor = get_tree().get_first_node_in_group(str(multiplayer.get_unique_id()))
	if this_actor == null or primary_actor == null: return true
	if this_actor.name == primary_actor.name:
		return true
	else:
		return primary_actor.map == this_actor.map
