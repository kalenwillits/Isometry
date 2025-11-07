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
	return get_tree().get_first_node_in_group(tag)

func get_primary_actor() -> Actor:
	return get_tree().get_first_node_in_group(Group.PRIMARY)
	
func get_actor(actor_name: String) -> Actor:
	return get_tree().get_first_node_in_group(Group.WORLD).get_node_or_null(actor_name)
