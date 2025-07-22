extends Object
class_name Strategy

var behavior_index: int = 0

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

func get_active_behavior() -> Behavior:
	return behaviors[behavior_index % behaviors.size()]

func reset() -> void:
	behavior_index = 0
	
func advance() -> void:
	behavior_index += 1;
	if behavior_index >= behaviors.size():
		reset()
		
func fallback() -> void:
	behavior_index = max(0, behavior_index - 1)

func use(interaction: ActorInteraction) -> void:
	for i in range(0, behavior_index + 1):
		var behavior_goals_are_met: bool = behaviors[i].goals_are_met(interaction)
		if behavior_goals_are_met and behavior_index == i:
			behaviors[i].advance()
		if !behavior_goals_are_met and behavior_index != i:
			behaviors[i].fallback()
		match behaviors[i].get_state():
			Behavior.State.FALLBACK:
				fallback()
				behaviors[i].arm()
			Behavior.State.ACTIVE:
				behaviors[i].get_action().call(interaction)
			Behavior.State.ADVANCE:
				advance()
