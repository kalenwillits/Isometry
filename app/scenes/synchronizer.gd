extends MultiplayerSynchronizer

func _ready() -> void:
	add_visibility_filter(visibility_filter)
	
func visibility_filter(peer_id: int) -> bool:
	var this_actor = Finder.get_actor(str(peer_id))
	var primary_actor = Finder.get_primary_actor()
	if this_actor == null or primary_actor == null: 
		# This is an NPC!
		return true
	if this_actor.name == primary_actor.name:
		return true
	else:
		return primary_actor.map == this_actor.map
