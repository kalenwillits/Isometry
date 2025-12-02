## DiceValidator
## Validates dice notation expressions using Dice.RollEngine.
##
class_name DiceValidator

## Fields that contain dice expressions, grouped by entity type
const DICE_FIELDS: Dictionary = {
	"Measure": ["expression"],
	"Sound": ["scale"],
	"Timer": ["total", "interval"]
}

## Validates all dice expressions in the campaign
func validate(asset_dict: Dictionary, result: ValidationResult) -> void:
	for entity_type in DICE_FIELDS.keys():
		if not asset_dict.has(entity_type):
			continue

		var fields: Array = DICE_FIELDS[entity_type]

		for entity_key in asset_dict[entity_type].keys():
			var entity_data: Dictionary = asset_dict[entity_type][entity_key]

			for field_name in fields:
				if not entity_data.has(field_name):
					continue

				var expression: String = entity_data[field_name]
				if expression.is_empty():
					continue

				_validate_dice_expression(expression, entity_type, entity_key, field_name, result)

## Validates a single dice expression
func _validate_dice_expression(expression: String, entity_type: String, entity_key: String, field_name: String, result: ValidationResult) -> void:
	# Check for invalid characters using Dice.RollEngine's valid character set
	const valid_chars: String = "0123456789()*%/+-dD<>"
	for i in range(expression.length()):
		var c: String = expression[i]
		if c not in valid_chars:
			result.add_error(
				ValidationError.Type.INVALID_DICE,
				entity_type,
				entity_key,
				field_name,
				"Invalid dice expression '%s' - invalid character '%s' at position %d" % [expression, c, i]
			)
			return
