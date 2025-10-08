extends Object
class_name Behavior

var state: State = State.ACTIVE

var goals: Array # Condition Key
var action: Callable

enum State {
	FALLBACK,
	ACTIVE,
	ADVANCE
}

class Builder extends Object:
	var this: Behavior = Behavior.new()
	
	func goals(value: Array) -> Builder:
		this.goals = value
		return self
		
	func action(value: Callable) -> Builder:
		this.action = value
		return self

	func build() -> Behavior: 
		this.state = State.ACTIVE
		return this

static func builder() -> Builder:
	return Builder.new()

func goals_are_met(interaction: ActorInteraction) -> bool:
	var goal_results: Array[bool] = []
	for condition_key in goals:
		goal_results.append(ConditionEvaluator.evaluate(
			ConditionEvaluator.EvaluateParams.builder()
			.caller_name(interaction.get_caller().name)
			.target_name(Optional.of_nullable(interaction.get_target()).map(func(t): t.name).or_else(""))
			.condition_key(condition_key)
			.build()
		))
	return goal_results.all(func(result): return result)
	
func get_state() -> Behavior.State:
	return state
	
func get_action() -> Callable:
	return action
	
func advance() -> void:
	state = Behavior.State.ADVANCE
	
func fallback() -> void: 
	state = Behavior.State.FALLBACK
	
func arm() -> void: 
	state = Behavior.State.ACTIVE
#
#func use(interaction: ActorInteraction):
	#if goals_are_met(interaction):
		#state = Behavior.State.ADVANCE
	#else:
		#state = Behavior.State.ACTIVE
