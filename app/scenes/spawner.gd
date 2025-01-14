extends MultiplayerSpawner

func _ready() -> void:
	add_to_group(Group.SPAWNER)

#func refresh_actor_visiblity(map: String) -> void:
	## This is an essential loop that hides actors on other maps from the primary.
	#for actor_node in get_tree().get_nodes_in_group(Group.ACTOR):
		#if actor_node.map == map:
			#actor_node.is_awake(true)
		#else:
			#actor_node.is_awake(false)

func _on_spawned(actor: Actor) -> void: # TODO - Consider removing this
	pass
	#Queue.enqueue(
		#Queue.Item.builder()
		#.comment("New spawn visibility handler")
		#.task(func(): actor.is_awake(Finder.get_primary_actor().map == actor.map))
		#.condition(func(): return Finder.get_primary_actor() != null)
		#.build()
	#)
	#Queue.enqueue(
		#Queue.Item.builder()
		#.comment("Clean up when primary respawns")
		#.task(func(): if actor.is_primary(): 
			#Finder.query([Group.ACTOR]).map(func(a): a.is_awake(false))
			#Finder.query([Group.ACTOR, actor.map]).map(func(a): a.is_awake(true))
			#)
		#.condition(func(): return Finder.get_primary_actor() != null)
		#.build()
	#)
