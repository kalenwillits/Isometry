extends Object
class_name ActorInteraction

var caller: Actor
var target: Actor

class Builder extends Object:
	var this: ActorInteraction = ActorInteraction.new()
	
	func caller(value: Actor) -> Builder:
		this.caller = value
		return self
		
	func target(value: Actor) -> Builder:
		this.target = value
		return self

	func build() -> ActorInteraction: 
		return this

static func builder() -> Builder:
	return Builder.new()
	
func get_caller() -> Actor:
	return caller
	
func get_target() -> Actor:
	return target
