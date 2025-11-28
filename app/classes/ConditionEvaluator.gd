extends Object
class_name ConditionEvaluator

static var OperatorSymbolMap: Dictionary = {
	"=": OP_EQUAL,
	"==": OP_EQUAL,
	">": OP_GREATER,
	"<": OP_LESS,
	"!=": OP_NOT_EQUAL,
	"<>": OP_NOT_EQUAL,
	">=": OP_GREATER_EQUAL,
	"<=": OP_LESS_EQUAL
}	

class EvaluateParams extends Object:
	var caller_name: String
	var target_name: String
	var condition_key: String
	
	class Builder extends Object:
		var this:  = EvaluateParams.new()

		func caller_name(value: String) -> Builder:
			this.caller_name = value
			return self

		func target_name(value: String) -> Builder:
			this.target_name = value
			return self

		func condition_key(value: String) -> Builder:
			this.condition_key = value
			return self

		func build() -> EvaluateParams: 
			return this

	static func builder() -> Builder:
		return Builder.new()

static func evaluate(params: EvaluateParams) -> bool:
	var start_time = Time.get_ticks_usec()

	if params.condition_key == null or params.condition_key == "":
		Logger.trace("[CONDITION] no_condition=true result=true (auto-pass)")
		return true

	Logger.trace("[CONDITION START] condition_key=%s caller=%s target=%s" % [params.condition_key, params.caller_name, params.target_name])

	var condition_ent = Repo.select(params.condition_key)

	Logger.trace("[CONDITION] left_expression=\"%s\"" % condition_ent.left)
	var lvalue: int = Dice.builder().caller(params.caller_name).target(params.target_name).expression(condition_ent.left).build().evaluate()
	Logger.trace("[CONDITION] left_value=%d" % lvalue)

	Logger.trace("[CONDITION] right_expression=\"%s\"" % condition_ent.right)
	var rvalue: int = Dice.builder().caller(params.caller_name).target(params.target_name).expression(condition_ent.right).build().evaluate()
	Logger.trace("[CONDITION] right_value=%d" % rvalue)

	Logger.trace("[CONDITION] operator=\"%s\" comparing %d %s %d" % [condition_ent.operator, lvalue, condition_ent.operator, rvalue])

	var result: bool = false
	match OperatorSymbolMap.get(condition_ent.operator):
		OP_EQUAL:
			result = lvalue == rvalue
		OP_NOT_EQUAL:
			result = lvalue != rvalue
		OP_GREATER:
			result = lvalue > rvalue
		OP_LESS:
			result = lvalue < rvalue
		OP_GREATER_EQUAL:
			result = lvalue >= rvalue
		OP_LESS_EQUAL:
			result = lvalue <= rvalue
		_:
			Logger.warn("Condition [%s] evaluates to `true` due to invalid operator [%s] used -- options are: %s" % [condition_ent.key(), condition_ent.operator, OperatorSymbolMap.keys()])
			result = true

	var elapsed_usec = Time.get_ticks_usec() - start_time
	Logger.trace("[CONDITION END] result=%s elapsed_usec=%d" % [str(result), elapsed_usec])

	return result
