extends Object
class_name Behavior

var _state: State = State.IDLE

var criteria: String # Condition Key
var action: Callable

enum State {
	IDLE,
	STARTING,
	ACTIVE,
	COMPLETED,
}

class Builder extends Object:
	var this: Behavior = Behavior.new()
	
	func criteria(value: String) -> Builder:
		this.criteria = value
		return self
		
	func action(value: Callable) -> Builder:
		this.action = value
		return self

	func build() -> Behavior: 
		assert(this.criteria != null)
		assert(this.action != null)
		this._state = State.IDLE
		return this

static func builder() -> Builder:
	return Builder.new()
	
func get_state() -> State:
	return _state
	
func promote_state() -> void:
	match get_state():
		Behavior.State.IDLE: 
			_state = State.STARTING
		Behavior.State.STARTING: 
			_state = State.ACTIVE
		Behavior.State.ACTIVE: 
			_state = State.COMPLETED
		Behavior.State.COMPLETED: 
			_state = State.IDLE

func use(interaction: ActorInteraction) -> void:
	match get_state():
		Behavior.State.IDLE:
			promote_state()
		Behavior.State.STARTING:
			action.call(interaction)
			promote_state()
		Behavior.State.ACTIVE:
			if ConditionEvaluator.evaluate(
				ConditionEvaluator.EvaluateParams.builder()
				.caller_name(interaction.get_caller().name)
				.target_name(Optional.of_nullable(interaction.get_target()).map(func(t): t.name).or_else(""))
				.condition_key(criteria)
				.build()
			): promote_state()
			else: action.call(interaction)
		Behavior.State.COMPLETED:
			promote_state()
