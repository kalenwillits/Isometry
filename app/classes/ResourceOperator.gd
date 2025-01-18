extends Object
class_name ResourceOperator

var resource: Entity
var actor: Actor
var operator_result: int

class Builder extends Object:
	var this: ResourceOperator = ResourceOperator.new()

	func resource(entity: Entity) -> Builder:
		this.resource_entity = entity
		return self

	func actor(actor: Actor) -> Builder:
		this.actor = actor
		return self

	func build() -> ResourceOperator: 
		return this

static func builder() -> Builder:
	return Builder.new()

func enforce_bounds(value: int) -> int:
	return max(clamp(value, resource.min_, resource.max_), 0)

func plus(value: int) -> ResourceOperator:
	var current_value: int = actor.resources.get(resource.key())
	var new_value: int = current_value + value
	actor.resources[resource.key()] = enforce_bounds(new_value)
	return self

func minus(value: int) -> ResourceOperator:
	var current_value: int = actor.resources.get(resource.key())
	var new_value: int = current_value - value
	actor.resources[resource.key()] = enforce_bounds(new_value)
	return self

func multiply(value: int) -> ResourceOperator:
	var current_value: int = actor.resources.get(resource.key())
	var new_value: int = current_value * value
	actor.resources[resource.key()] = enforce_bounds(new_value)
	return self

func divide(value: int) -> ResourceOperator:
	## Important!!!! 
	## If someone attempts to divide by zero, it will be treated as n/1.
	if value == 0: value = 1
	var current_value: int = actor.resources.get(resource.key())
	var new_value: int = current_value / value
	actor.resources[resource.key()] = enforce_bounds(new_value)
	return self

func get_value() -> int:
	return actor.resources.get(resource.key())
