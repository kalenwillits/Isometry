extends Node

func query(tags: Array) -> Array:
	var results: Array = []
	for tag in tags:
		var subquery = get_tree().get_nodes_in_group(tag)
		if results.is_empty():
			results = subquery
		else:
			results = std.intersect(results, subquery)
	Logger.info("Query %s yields %d results" % [tags, results.size()])
	return results
	
func select(tag: String) -> Node:
	return get_tree().get_first_node_in_group(tag)

func get_primary_actor() -> Actor:
	return get_tree().get_first_node_in_group(Group.PRIMARY)
