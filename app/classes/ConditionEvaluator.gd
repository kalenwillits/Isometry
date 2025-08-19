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
	if params.condition_key == null or params.condition_key == "": return true # if there is no condition set, automatically pass
	var condition_ent = Repo.select(params.condition_key)
	var lvalue: int = Dice.builder().caller(params.caller_name).target(params.target_name).expression(condition_ent.left).build().evaluate()
	var rvalue: int = Dice.builder().caller(params.caller_name).target(params.target_name).expression(condition_ent.right).build().evaluate()
	match OperatorSymbolMap.get(condition_ent.operator):
		OP_EQUAL:
			return lvalue == rvalue
		OP_NOT_EQUAL:
			return lvalue != rvalue
		OP_GREATER:
			return lvalue > rvalue
		OP_LESS:
			return lvalue < rvalue
		OP_GREATER_EQUAL:
			return lvalue >= rvalue
		OP_LESS_EQUAL:
			return lvalue <= rvalue
		_:
			Logger.warn("Condition [%s] evaluates to `true` due to invalid operator [%s] used -- options are: %s" % [condition_ent.key(), condition_ent.operator, OperatorSymbolMap.keys()])
			return true
