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
	if actor == null:
		Logger.trace("[RESOURCE OP] operation=plus actor=%s actor_null=true skipped=true" % actor_name)
		return self

	var current_value: int = actor.resources.get(resource.key())
	var new_value_raw: int = current_value + value
	var new_value_bounded: int = enforce_bounds(new_value_raw)

	Logger.trace("[RESOURCE OP] operation=plus actor=%s resource=%s value=%d before=%d after_raw=%d after_bounded=%d clamped=%s" % [
		actor_name,
		resource.key(),
		value,
		current_value,
		new_value_raw,
		new_value_bounded,
		str(new_value_raw != new_value_bounded)
	])

	actor.resources[resource.key()] = new_value_bounded

	# Sync resource change to all clients
	if std.is_host_or_server():
		Logger.trace("[RESOURCE SYNC] actor=%s resource=%s value=%d rpc_sent=true" % [actor_name, resource.key(), actor.resources[resource.key()]])
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func minus(value: int) -> ResourceOperator:
	var actor = get_actor()
	if actor == null:
		Logger.trace("[RESOURCE OP] operation=minus actor=%s actor_null=true skipped=true" % actor_name)
		return self

	var current_value: int = actor.resources.get(resource.key())
	var new_value_raw: int = current_value - value
	var new_value_bounded: int = enforce_bounds(new_value_raw)

	Logger.trace("[RESOURCE OP] operation=minus actor=%s resource=%s value=%d before=%d after_raw=%d after_bounded=%d clamped=%s" % [
		actor_name,
		resource.key(),
		value,
		current_value,
		new_value_raw,
		new_value_bounded,
		str(new_value_raw != new_value_bounded)
	])

	actor.resources[resource.key()] = new_value_bounded

	# Sync resource change to all clients
	if std.is_host_or_server():
		Logger.trace("[RESOURCE SYNC] actor=%s resource=%s value=%d rpc_sent=true" % [actor_name, resource.key(), actor.resources[resource.key()]])
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func multiply(value: int) -> ResourceOperator:
	var actor = get_actor()
	if actor == null:
		Logger.trace("[RESOURCE OP] operation=multiply actor=%s actor_null=true skipped=true" % actor_name)
		return self

	var current_value: int = actor.resources.get(resource.key())
	var new_value_raw: int = current_value * value
	var new_value_bounded: int = enforce_bounds(new_value_raw)

	Logger.trace("[RESOURCE OP] operation=multiply actor=%s resource=%s value=%d before=%d after_raw=%d after_bounded=%d clamped=%s" % [
		actor_name,
		resource.key(),
		value,
		current_value,
		new_value_raw,
		new_value_bounded,
		str(new_value_raw != new_value_bounded)
	])

	actor.resources[resource.key()] = new_value_bounded

	# Sync resource change to all clients
	if std.is_host_or_server():
		Logger.trace("[RESOURCE SYNC] actor=%s resource=%s value=%d rpc_sent=true" % [actor_name, resource.key(), actor.resources[resource.key()]])
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func divide(value: int) -> ResourceOperator:
	var actor = get_actor()
	if actor == null:
		Logger.trace("[RESOURCE OP] operation=divide actor=%s actor_null=true skipped=true" % actor_name)
		return self

	var current_value: int = actor.resources.get(resource.key())
	# Handle divide by zero: treat as division by infinity = 0
	# Use explicit integer division to avoid float contamination
	var new_value_raw: int = 0 if value == 0 else int(current_value / value)
	var new_value_bounded: int = enforce_bounds(new_value_raw)

	Logger.trace("[RESOURCE OP] operation=divide actor=%s resource=%s value=%d before=%d after_raw=%d after_bounded=%d divide_by_zero=%s clamped=%s" % [
		actor_name,
		resource.key(),
		value,
		current_value,
		new_value_raw,
		new_value_bounded,
		str(value == 0),
		str(new_value_raw != new_value_bounded)
	])

	actor.resources[resource.key()] = new_value_bounded

	# Sync resource change to all clients
	if std.is_host_or_server():
		Logger.trace("[RESOURCE SYNC] actor=%s resource=%s value=%d rpc_sent=true" % [actor_name, resource.key(), actor.resources[resource.key()]])
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func set_value(value: int) -> ResourceOperator:
	var actor = get_actor()
	if actor == null:
		Logger.trace("[RESOURCE OP] operation=set actor=%s actor_null=true skipped=true" % actor_name)
		return self

	var current_value: int = actor.resources.get(resource.key())
	var new_value_bounded: int = enforce_bounds(value)

	Logger.trace("[RESOURCE OP] operation=set actor=%s resource=%s value=%d before=%d after_bounded=%d clamped=%s" % [
		actor_name,
		resource.key(),
		value,
		current_value,
		new_value_bounded,
		str(value != new_value_bounded)
	])

	actor.resources[resource.key()] = new_value_bounded

	# Sync resource change to all clients
	if std.is_host_or_server():
		Logger.trace("[RESOURCE SYNC] actor=%s resource=%s value=%d rpc_sent=true" % [actor_name, resource.key(), actor.resources[resource.key()]])
		Controller.sync_resource.rpc(actor_name, resource.key(), actor.resources[resource.key()])

	return self

func get_value() -> int:
	var actor = get_actor()
	if actor == null: return 0
	return actor.resources.get(resource.key())
