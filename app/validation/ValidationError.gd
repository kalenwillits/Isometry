## ValidationError
## Represents a single validation error with context and message.
##
class_name ValidationError

## Error type categories
enum Type {
	MISSING_REQUIRED_FIELD,
	INVALID_TYPE,
	KEYREF_UNRESOLVED,
	INVALID_DICE,
	ASSET_NOT_FOUND,
	INVALID_ACTION_PARAM,
	INVALID_ACTION_NAME,
	CONSTRAINT_VIOLATION,
	EXTRA_FIELD,
	MAIN_ENTITY_MISSING,
	MAIN_ENTITY_DUPLICATE,
	DUPLICATE_KEY,
	UNKNOWN_TYPE
}

## Type of validation error
var type: Type
## Entity type being validated (e.g., "Actor", "Action")
var entity_type: String
## Entity key being validated
var entity_key: String
## Field name where error occurred (empty if not field-specific)
var field_name: String
## Human-readable error message
var message: String

func _init(p_type: Type, p_entity_type: String, p_entity_key: String, p_field_name: String, p_message: String) -> void:
	type = p_type
	entity_type = p_entity_type
	entity_key = p_entity_key
	field_name = p_field_name
	message = p_message

## Returns formatted error string for display
func format() -> String:
	var type_str: String = Type.keys()[type]
	if field_name.is_empty():
		return "[%s] %s.%s: %s" % [type_str, entity_type, entity_key, message]
	else:
		return "[%s] %s.%s: %s - %s" % [type_str, entity_type, entity_key, field_name, message]
