extends Node

func query(tags: Array) -> Array:
	var results: Array = []
	var initialized: bool = false

	for tag in tags:
		if tag == null: continue
		var subquery = get_tree().get_nodes_in_group(tag)

		if not initialized:
			results = subquery
			initialized = true
		else:
			results = std.intersect(results, subquery)

	return results
	
func select(tag: String) -> Node:
	var node = get_tree().get_first_node_in_group(tag)
	if node == null:
		Logger.warn("Finder: No node found in group '%s'" % tag)
	return node

func get_primary_actor() -> Actor:
	var actor = get_tree().get_first_node_in_group(Group.PRIMARY)
	if actor == null:
		Logger.trace("Finder: Primary actor not found")
	return actor
	
func get_actor(actor_name: String) -> Actor:
	if actor_name.is_empty():
		Logger.warn("Finder.get_actor called with empty actor_name")
		return null

	var world = get_tree().get_first_node_in_group(Group.WORLD)
	if world == null:
		Logger.error("Finder: WORLD node not found - cannot get actor '%s'" % actor_name)
		return null

	var actor = world.get_node_or_null(actor_name)
	if actor == null:
		Logger.warn("Finder: Actor not found: '%s'" % actor_name)
	else:
		Logger.trace("Finder: Actor found: '%s'" % actor_name)
	return actor
