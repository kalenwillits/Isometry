extends Object

const CHARACTER_SET = "0123456789()*%/+-D<>"

var expr : String = ""
var result : int = 0

static func eval(expression: String) -> int:
	return new().evaluate(expression.strip_edges().strip_escapes().replace(" ", "").to_upper())

# Validate expression (check for invalid characters, parentheses, division by zero)
func validate(expression: String) -> bool:
	var parentheses_stack = []
	for i in range(expression.length()):
		var ch = expression[i].to_upper()
		
		if CHARACTER_SET.find(ch) == -1:
			return false # Invalid character
			
		match expression[i]:
			"(":
				parentheses_stack.append(i)
			")":
				if parentheses_stack.size() == 0:
					return false # Unbalanced parentheses
				parentheses_stack.pop_back()
			"/":
				if i + 1 < expression.length() and expression[i + 1] == "0":
					return false # Division by zero
	return parentheses_stack.size() == 0

# Evaluate the entire expression
func evaluate(expression: String) -> int:
	if expression == "":
		return 0
	expr = expression
	# Step-by-step evaluation: parentheses -> dice notation -> filters -> arithmetic
	expr = eval_parentheses(expr)       # Handle parentheses first
	expr = eval_dice_pool(expr)         # Evaluate dice notation
	expr = eval_filters(expr)           # Apply filters (>, <)
	expr = eval_operations(expr)        # Perform arithmetic operations
	return int(expr)

# Handle parentheses first
func eval_parentheses(expression: String) -> String:
	var start = expression.find("(")
	while start != -1:
		var end = expression.find(")", start)
		if end != -1:
			var inner_expr = expression.substr(start + 1, end)
			var evaluated = str(evaluate(inner_expr))  # Recursively evaluate inside parentheses
			expression = expression.substr(0, start) + evaluated + expression.substr(end + 1, expression.length())
			start = expression.find("(")  # Check for new parentheses
		else:
			break
	return expression

# Evaluate dice notation (e.g., 2D6 -> replace with actual roll)
func eval_dice_pool(expression: String) -> String:
	# Regular expression to match the dice notation (e.g., 1D6, 2D20, etc.)
	var dice_regex = RegEx.new()
	dice_regex.compile(r"(\d+)D(\d+)")

	var result_expression = expression
	var matches = dice_regex.search_all(expression)

	for match_ in matches:
		var dice_count = int(match_.get_string(1))  # Get number of dice
		var dice_sides = int(match_.get_string(2))  # Get number of sides
		var roll_result = roll_dice(dice_count, dice_sides)
		print("Rolled Dice:", roll_result)  # Debug: Show rolled dice
		result_expression = result_expression.replace(match_.get_string(0), str(roll_result))  # Replace dice notation with roll result

	return result_expression

# Simulate rolling dice and returning the results
func roll_dice(count: int, sides: int) -> Array:
	var results = []
	for _n in range(count):
		results.append(randi_range(1, sides))
	return results

# Apply filters (>, <) and replace with sum of filtered dice
func eval_filters(expression: String) -> String:
	var filtered_expression = expression
	var filter_regex = RegEx.new()
	
	# Regex for "ndX > Y" or "ndX < Y"
	filter_regex.compile(r"(\d+)D(\d+)([<>])(\d+)")

	var matches = filter_regex.search_all(expression)
	for match_ in matches:
		var dice_count = int(match_.get_string(1))
		var dice_sides = int(match_.get_string(2))
		var filter_operator = match_.get_string(3)
		var filter_value = int(match_.get_string(4))

		# Roll dice and apply filter
		var dice_rolls = roll_dice(dice_count, dice_sides)
		print("Dice Rolls for Filter:", dice_rolls)  # Debug: Show dice rolls before applying filter

		# Sort the rolls and apply the filter
		dice_rolls.sort()

		if filter_operator == ">":
			dice_rolls.reverse()  # Sort in descending order to keep highest values
			dice_rolls = dice_rolls.slice(0, filter_value)  # Keep only the highest 'filter_value' results
		elif filter_operator == "<":
			dice_rolls = dice_rolls.slice(0, filter_value)  # Keep only the lowest 'filter_value' results

		print("Filtered Dice Rolls:", dice_rolls)  # Debug: Show filtered dice rolls

		var filtered_result = str(dice_rolls.sum())  # Sum the filtered dice rolls
		filtered_expression = filtered_expression.replace(match_.get_string(0), filtered_result)  # Replace with the filtered sum

	return filtered_expression

# Evaluate arithmetic operations (+, -, *, /, %, etc.)
func eval_operations(expression: String) -> String:
	expression = eval_multiplication(expression)
	expression = eval_division(expression)
	expression = eval_modulus(expression)
	expression = eval_addition(expression)
	expression = eval_subtraction(expression)
	return expression

# Evaluate multiplication
func eval_multiplication(expression: String) -> String:
	var parts = expression.split("*")
	if parts.size() == 2:
		return str(int(parts[0]) * int(parts[1]))
	return expression

# Evaluate division
func eval_division(expression: String) -> String:
	var parts = expression.split("/")
	if parts.size() == 2:
		if int(parts[1]) != 0:
			return str(int(parts[0]) / int(parts[1]))
		else:
			return "0"  # Return 0 if dividing by 0
	return expression

# Evaluate modulus
func eval_modulus(expression: String) -> String:
	var parts = expression.split("%")
	if parts.size() == 2:
		return str(int(parts[0]) % int(parts[1]))
	return expression

# Evaluate addition
func eval_addition(expression: String) -> String:
	var parts = expression.split("+")
	if parts.size() == 2:
		return str(int(parts[0]) + int(parts[1]))
	return expression

# Evaluate subtraction
func eval_subtraction(expression: String) -> String:
	var parts = expression.split("-")
	if parts.size() == 2:
		return str(int(parts[0]) - int(parts[1]))
	return expression
