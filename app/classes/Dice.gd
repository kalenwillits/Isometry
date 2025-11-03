extends Object
class_name Dice

## GDScript implementation of dice roller - replaces C++ GDExtension
class RollEngine:
	const VALID_CHARS = "0123456789()*%/+-dD<>"

	static var _dice_regex: RegEx = null
	static var _number_regex: RegEx = null

	static func _init_regex() -> void:
		if _dice_regex == null:
			_dice_regex = RegEx.new()
			_dice_regex.compile(r"(\d*)[dD](\d+)")
		if _number_regex == null:
			_number_regex = RegEx.new()
			_number_regex.compile(r"\d+")

	static func roll(expr: String) -> int:
		if expr == null or expr.is_empty():
			return 0

		# Validate expression
		for i in range(expr.length()):
			if not expr[i] in VALID_CHARS:
				Logger.error("RollEngine: Invalid character '%s' in expression: %s" % [expr[i], expr])
				return 0

		_init_regex()

		# Evaluate in order (matching C++ precedence)
		expr = _eval_parentheses(expr)
		expr = _eval_filters(expr)
		expr = _eval_dice_pool(expr)
		expr = _eval_multiplication(expr)
		expr = _eval_division(expr)
		expr = _eval_modulus(expr)
		expr = _eval_addition(expr)
		expr = _eval_subtraction(expr)

		# Final result - clamp to minimum 0
		var result = int(expr) if expr.is_valid_int() else 0
		return max(result, 0)

	static func _eval_parentheses(expr: String) -> String:
		# Recursively evaluate innermost parentheses first
		while "(" in expr:
			var depth = 0
			var start = -1
			var end = -1

			for i in range(expr.length()):
				if expr[i] == '(':
					if depth == 0:
						start = i
					depth += 1
				elif expr[i] == ')':
					depth -= 1
					if depth == 0:
						end = i
						break

			if start >= 0 and end > start:
				var inner = expr.substr(start + 1, end - start - 1)
				var result = roll(inner)  # Recursive evaluation
				expr = expr.substr(0, start) + str(result) + expr.substr(end + 1)
			else:
				break  # Unbalanced parentheses

		return expr

	static func _eval_filters(expr: String) -> String:
		# Handle > (keep highest) and < (keep lowest) operators
		# Format: NdM>X or NdM<X
		while true:
			var filter_pos = -1
			var is_greater = false

			# Find first filter operator
			for i in range(expr.length()):
				if expr[i] == '>' or expr[i] == '<':
					filter_pos = i
					is_greater = (expr[i] == '>')
					break

			if filter_pos == -1:
				break

			# Find the dice notation before the filter
			var dice_start = filter_pos - 1
			while dice_start >= 0 and (expr[dice_start].is_valid_int() or expr[dice_start].to_lower() == 'd'):
				dice_start -= 1
			dice_start += 1

			# Extract dice notation (e.g., "4d6")
			var dice_str = expr.substr(dice_start, filter_pos - dice_start)

			# Extract filter count
			var filter_end = filter_pos + 1
			while filter_end < expr.length() and expr[filter_end].is_valid_int():
				filter_end += 1
			var filter_count = int(expr.substr(filter_pos + 1, filter_end - filter_pos - 1))

			# Roll the dice
			var parts = dice_str.to_lower().split("d")
			var num_dice = int(parts[0]) if parts[0] != "" else 1
			var num_sides = int(parts[1]) if parts.size() > 1 else 1

			var rolls = []
			for i in range(num_dice):
				rolls.append(randi_range(1, num_sides))

			# Apply filter
			rolls.sort()
			if is_greater:
				# Keep highest: reverse and take first N
				rolls.reverse()
				rolls = rolls.slice(0, filter_count)
			else:
				# Keep lowest: take first N
				rolls = rolls.slice(0, filter_count)

			# Sum the kept rolls
			var total = 0
			for roll in rolls:
				total += roll

			# Substitute back into expression
			expr = expr.substr(0, dice_start) + str(total) + expr.substr(filter_end)

		return expr

	static func _eval_dice_pool(expr: String) -> String:
		# Evaluate all dice notation (NdM)
		while true:
			var match_obj = _dice_regex.search(expr)
			if match_obj == null:
				break

			var num_str = match_obj.get_string(1)
			var sides_str = match_obj.get_string(2)

			var num_dice = int(num_str) if num_str != "" else 1
			var num_sides = int(sides_str)

			# Roll dice
			var total = 0
			for i in range(num_dice):
				total += randi_range(1, num_sides)

			# Replace in expression
			expr = expr.substr(0, match_obj.get_start()) + str(total) + expr.substr(match_obj.get_end())

		return expr

	static func _eval_binary_op(expr: String, op: String, default_left: int, default_right: int, calc: Callable) -> String:
		# Generic binary operator evaluation
		while op in expr:
			var pos = expr.find(op)
			if pos == -1:
				break

			# Extract left operand
			var left_start = pos - 1
			while left_start >= 0 and expr[left_start].is_valid_int():
				left_start -= 1
			left_start += 1

			var left_str = expr.substr(left_start, pos - left_start)
			var left_val = int(left_str) if left_str != "" else default_left

			# Extract right operand
			var right_end = pos + op.length()
			while right_end < expr.length() and expr[right_end].is_valid_int():
				right_end += 1

			var right_str = expr.substr(pos + op.length(), right_end - pos - op.length())
			var right_val = int(right_str) if right_str != "" else default_right

			# Calculate result
			var result = calc.call(left_val, right_val)

			# Substitute back
			expr = expr.substr(0, left_start) + str(result) + expr.substr(right_end)

		return expr

	static func _eval_multiplication(expr: String) -> String:
		return _eval_binary_op(expr, "*", 1, 1, func(a, b): return a * b)

	static func _eval_division(expr: String) -> String:
		return _eval_binary_op(expr, "/", 1, 1, func(a, b): return a / b if b != 0 else 0)

	static func _eval_modulus(expr: String) -> String:
		return _eval_binary_op(expr, "%", 1, 1, func(a, b): return a % b if b != 0 else 0)

	static func _eval_addition(expr: String) -> String:
		return _eval_binary_op(expr, "+", 0, 0, func(a, b): return max(a + b, 0))

	static func _eval_subtraction(expr: String) -> String:
		return _eval_binary_op(expr, "-", 0, 0, func(a, b): return max(a - b, 0))

const CALLER_MARKER: String = "$"
const TARGET_MARKER: String = "@"
const MAX_RECURSION_DEPTH: int = 10

var caller_name: String
var target_name: String
var expression: String

static var _regex: RegEx = null
static var _recursion_depth: int = 0

class Builder extends Object:
	var this: Dice = Dice.new()

	func caller(self_name: String) -> Builder:
		this.caller_name = self_name
		return self

	func caller_name(self_name: String) -> Builder:
		this.caller_name = self_name
		return self

	func target(target_name: String) -> Builder:
		this.target_name = target_name
		return self

	func target_name(target_name: String) -> Builder:
		this.target_name = target_name
		return self

	func expression(expr: String) -> Builder:
		this.expression = expr
		return self

	func build() -> Dice:
		return this

static func builder() -> Builder:
	return Builder.new()

## Ensure regex is compiled (lazy initialization)
static func _ensure_regex_compiled() -> void:
	if _regex != null:
		return

	_regex = RegEx.new()
	# Pattern matches: ($|@)(identifier)
	# Group 1: marker type ($ or @)
	# Group 2: key name (alphanumeric + underscore, must start with letter/underscore)
	var pattern: String = "([$@])([a-zA-Z_][a-zA-Z0-9_]*)"
	var err = _regex.compile(pattern)
	if err != OK:
		Logger.error("Dice: Failed to compile regex pattern")

## Inject actor resource values into the expression.
## $key = caller resources, @key = target resources
## Missing resources default to 0 with a warning.
## Note: Actor type hints removed to avoid circular dependency.
func inject_resources(caller_actor, target_actor) -> String:
	if expression == null or expression == "":
		return expression

	# Early exit if no markers present
	if not CALLER_MARKER in expression and not TARGET_MARKER in expression:
		return expression

	_ensure_regex_compiled()
	if _regex == null:
		Logger.error("Dice: Regex not compiled, returning original expression")
		return expression

	var result: String = expression
	var matches: Array = _regex.search_all(expression)

	# Process matches in reverse order to maintain string positions
	for i in range(matches.size() - 1, -1, -1):
		var match_obj: RegExMatch = matches[i]
		var marker: String = match_obj.get_string(1)
		var key: String = match_obj.get_string(2)
		var start_pos: int = match_obj.get_start(0)
		var end_pos: int = match_obj.get_end(0)

		var actor = caller_actor if marker == CALLER_MARKER else target_actor
		var value: String = "0"  # Default to 0

		# Handle null actor - default to 0 (intended behavior)
		if actor == null:
			pass  # Silently default to 0
		# Check if it's a resource
		elif key in actor.resources:
			value = str(actor.resources[key])
		# Not a resource - leave it for measure injection
		else:
			continue

		# Replace the match with the resolved value
		result = result.substr(0, start_pos) + value + result.substr(end_pos)

	return result

## Inject actor measure values into the expression.
## $key = caller measures, @key = target measures
## Missing measures default to 0 with a warning.
## Note: Actor type hints removed to avoid circular dependency.
func inject_measures(caller_actor, target_actor, processed_expr: String) -> String:
	if processed_expr == null or processed_expr == "":
		return processed_expr

	# Early exit if no markers present
	if not CALLER_MARKER in processed_expr and not TARGET_MARKER in processed_expr:
		return processed_expr

	_ensure_regex_compiled()
	if _regex == null:
		Logger.error("Dice: Regex not compiled, returning original expression")
		return processed_expr

	var result: String = processed_expr
	var matches: Array = _regex.search_all(processed_expr)

	# Process matches in reverse order to maintain string positions
	for i in range(matches.size() - 1, -1, -1):
		var match_obj: RegExMatch = matches[i]
		var marker: String = match_obj.get_string(1)
		var key: String = match_obj.get_string(2)
		var start_pos: int = match_obj.get_start(0)
		var end_pos: int = match_obj.get_end(0)

		var actor = caller_actor if marker == CALLER_MARKER else target_actor
		var value: String = "0"  # Default to 0

		# Handle null actor - default to 0 (intended behavior)
		if actor == null:
			pass  # Silently default to 0
		# Check if it's a measure
		elif key in actor.measures:
			var measure = actor.measures[key]

			# Handle callable measures
			if measure is Callable:
				# Check the argument count to determine measure type
				var arg_count = measure.get_argument_count()

				if arg_count == 0:
					# Built-in measure (no parameters)
					var measure_value = measure.call()
					value = str(measure_value)
				else:
					# Entity measure (expects ActorInteraction parameter)
					# Build ActorInteraction for measure evaluation
					# Determine caller and target based on marker
					var interaction_caller = caller_actor if marker == CALLER_MARKER else target_actor
					var interaction_target = target_actor if marker == CALLER_MARKER else caller_actor

					var interaction = ActorInteraction.builder()\
						.caller(interaction_caller)\
						.target(interaction_target)\
						.build()

					var measure_value = measure.call(interaction)
					value = str(measure_value)
			else:
				value = str(measure)
		else:
			# Key not found in either resources or measures - default to 0 (intended behavior)
			pass  # Silently default to 0

		# Replace the match with the resolved value
		result = result.substr(0, start_pos) + value + result.substr(end_pos)

	return result

## Evaluate the dice expression, injecting actor values and rolling.
## Two-phase injection: resources first, then measures.
func evaluate() -> int:
	# Recursion guard to prevent infinite loops from circular measure references
	_recursion_depth += 1
	if _recursion_depth > MAX_RECURSION_DEPTH:
		Logger.error("Dice: Maximum recursion depth exceeded - possible circular measure reference")
		_recursion_depth -= 1
		return 0

	var caller_actor = Finder.get_actor(caller_name) if caller_name else null
	var target_actor = Finder.get_actor(target_name) if target_name else null

	# Phase 1: Inject resources
	var after_resources: String = inject_resources(caller_actor, target_actor)

	# Phase 2: Inject measures (which may contain dice notation with resources)
	var processed_expr: String = inject_measures(caller_actor, target_actor, after_resources)

	var result = RollEngine.roll(processed_expr)
	_recursion_depth -= 1
	return result

## Get the processed expression with actor values injected.
## Useful for displaying the expression without evaluating dice rolls.
func get_processed_expression() -> String:
	# Recursion guard to prevent infinite loops from circular measure references
	_recursion_depth += 1
	if _recursion_depth > MAX_RECURSION_DEPTH:
		Logger.error("Dice: Maximum recursion depth exceeded - possible circular measure reference")
		_recursion_depth -= 1
		return "0"

	var caller_actor = Finder.get_actor(caller_name) if caller_name else null
	var target_actor = Finder.get_actor(target_name) if target_name else null

	# Phase 1: Inject resources
	var after_resources: String = inject_resources(caller_actor, target_actor)

	# Phase 2: Inject measures
	var result = inject_measures(caller_actor, target_actor, after_resources)
	_recursion_depth -= 1
	return result
