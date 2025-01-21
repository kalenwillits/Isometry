extends Object
class_name Strategy

var _index: int

var behaviors: Array[Behavior] = []

class Builder extends Object:
	var this: Strategy = Strategy.new()
	
	func behaviors(value: Array[Behavior]) -> Builder:
		this.behaviors = value
		return self

	func build() -> Strategy: 
		this.reset()
		return this

static func builder() -> Builder:
	return Builder.new()

func reset() -> void:
	_index = 0
	
func increment_index() -> void:
	_index += 1

func use(interaction: ActorInteraction) -> void:
	var num_behaviors: int = behaviors.size()
	if num_behaviors <= 0: return
	var current_behavior: Behavior = behaviors[_index % num_behaviors]
	current_behavior.use(interaction)
	match current_behavior.get_state():
		Behavior.State.IDLE:
			pass # TODO - add hooks if needed
		Behavior.State.STARTING:
			pass
		Behavior.State.ACTIVE:
			pass
		Behavior.State.COMPLETED:
			increment_index()
