## ValidationResult
## Aggregates validation errors from campaign validation process.
##
class_name ValidationResult

## Array of ValidationError objects
var errors: Array = []

## Adds a validation error to the result
func add_error(type: ValidationError.Type, entity_type: String, entity_key: String, field_name: String, message: String) -> void:
	errors.append(ValidationError.new(type, entity_type, entity_key, field_name, message))

## Returns true if any validation errors occurred
func has_errors() -> bool:
	return errors.size() > 0

## Returns all validation errors
func get_errors() -> Array:
	return errors

## Returns total count of errors
func get_error_count() -> int:
	return errors.size()

## Returns errors grouped by entity type
func get_errors_by_type() -> Dictionary:
	var grouped: Dictionary = {}
	for error in errors:
		if not grouped.has(error.entity_type):
			grouped[error.entity_type] = []
		grouped[error.entity_type].append(error)
	return grouped

## Returns errors grouped by error category
func get_errors_by_category() -> Dictionary:
	var grouped: Dictionary = {}
	for error in errors:
		var category: String = ValidationError.Type.keys()[error.type]
		if not grouped.has(category):
			grouped[category] = []
		grouped[category].append(error)
	return grouped

## Returns a summary string of all errors
func get_summary() -> String:
	if not has_errors():
		return "Validation passed - no errors found"

	var summary := "Validation failed with %d error(s):\n" % errors.size()
	for error in errors:
		summary += "  " + error.format() + "\n"
	return summary
