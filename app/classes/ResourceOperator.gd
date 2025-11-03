extends Object
class_name ResourceOperator

var resource: Entity
var actor_name: String
var operator_result: int

class Builder extends Object:
	var this: ResourceOperator = ResourceOperator.new()

	func resource(entity: Entity) -> Builder:
		this.resource = entity
		return self

	func actor(actor_name: String) -> Builder:
		this.actor_name = actor_name
		return self

	func build() -> ResourceOperator: 
		return this

static func builder() -> Builder:
	return Builder.new()

func get_actor() -> Actor:
	return Finder.get_actor(actor_name)

func enforce_bounds(value: int) -> int:
	return max(clamp(value, resource.min_, resource.max_), 0)

func plus(value: int) -> ResourceOperator:
	var actor = get_actor()
	if actor == null: return self
	var current_value: int = actor.resources.get(resource.key())
	var new_value: int = current_value + value
	actor.resources[resource.key()] = enforce_bounds(new_value)

	# Sync resource change to all clients
	if std.is_host_or_server():
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func minus(value: int) -> ResourceOperator:
	var actor = get_actor()
	if actor == null: return self
	var current_value: int = actor.resources.get(resource.key())
	var new_value: int = current_value - value
	actor.resources[resource.key()] = enforce_bounds(new_value)

	# Sync resource change to all clients
	if std.is_host_or_server():
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func multiply(value: int) -> ResourceOperator:
	var actor = get_actor()
	if actor == null: return self
	var current_value: int = actor.resources.get(resource.key())
	var new_value: int = current_value * value
	actor.resources[resource.key()] = enforce_bounds(new_value)

	# Sync resource change to all clients
	if std.is_host_or_server():
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func divide(value: int) -> ResourceOperator:
	## Important!!!!
	## If someone attempts to divide by zero, it will be treated as infitity
	if value == 0: value = INF
	var actor = get_actor()
	if actor == null: return self
	var current_value: int = actor.resources.get(resource.key())
	var new_value: int = current_value / value
	actor.resources[resource.key()] = enforce_bounds(new_value)

	# Sync resource change to all clients
	if std.is_host_or_server():
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func get_value() -> int:
	var actor = get_actor()
	if actor == null: return 0
	return actor.resources.get(resource.key())
