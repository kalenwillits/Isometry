## EntitySchemaValidator
## Validates entity data against its schema definition.
##
class_name EntitySchemaValidator

var schema: Dictionary

func _init(p_schema: Dictionary) -> void:
	schema = p_schema

## Validates entity data against the schema
func validate(entity_data: Dictionary, entity_type: String, entity_key: String, result: ValidationResult) -> void:
	# Check for required fields
	_validate_required_fields(entity_data, entity_type, entity_key, result)

	# Check for extra fields not in schema
	_validate_no_extra_fields(entity_data, entity_type, entity_key, result)

	# Validate each field present in entity_data
	for field_name in entity_data.keys():
		if not schema.has(field_name):
			continue  # Already reported as extra field

		var field_def: Dictionary = schema[field_name]
		var field_value = entity_data[field_name]

		# Validate field type
		_validate_field_type(field_name, field_value, field_def, entity_type, entity_key, result)

		# Validate field constraints
		_validate_field_constraints(field_name, field_value, field_def, entity_type, entity_key, result)

## Checks that all required fields are present
func _validate_required_fields(entity_data: Dictionary, entity_type: String, entity_key: String, result: ValidationResult) -> void:
	for field_name in schema.keys():
		var field_def: Dictionary = schema[field_name]
		if field_def.get("required", false) and not entity_data.has(field_name):
			result.add_error(
				ValidationError.Type.MISSING_REQUIRED_FIELD,
				entity_type,
				entity_key,
				field_name,
				"Required field '%s' is missing" % field_name
			)

## Checks for fields in entity_data that aren't in schema
func _validate_no_extra_fields(entity_data: Dictionary, entity_type: String, entity_key: String, result: ValidationResult) -> void:
	for field_name in entity_data.keys():
		if not schema.has(field_name):
			result.add_error(
				ValidationError.Type.EXTRA_FIELD,
				entity_type,
				entity_key,
				field_name,
				"Field '%s' not defined in %s schema" % [field_name, entity_type]
			)

## Validates field type matches schema definition
func _validate_field_type(field_name: String, field_value, field_def: Dictionary, entity_type: String, entity_key: String, result: ValidationResult) -> void:
	var expected_type: EntitySchema.FieldType = field_def.get("type", EntitySchema.FieldType.STRING)

	# Special handling for KeyRef and KeyRefArray (stored as strings/arrays)
	if expected_type == EntitySchema.FieldType.KEYREF:
		if typeof(field_value) != TYPE_STRING:
			result.add_error(
				ValidationError.Type.INVALID_TYPE,
				entity_type,
				entity_key,
				field_name,
				"Expected KeyRef (String), got %s" % type_string(typeof(field_value))
			)
		return

	if expected_type == EntitySchema.FieldType.KEYREF_ARRAY:
		if typeof(field_value) != TYPE_ARRAY:
			result.add_error(
				ValidationError.Type.INVALID_TYPE,
				entity_type,
				entity_key,
				field_name,
				"Expected KeyRefArray (Array), got %s" % type_string(typeof(field_value))
			)
		else:
			# Validate each element is a string
			for i in range(field_value.size()):
				if typeof(field_value[i]) != TYPE_STRING:
					result.add_error(
						ValidationError.Type.INVALID_TYPE,
						entity_type,
						entity_key,
						field_name,
						"KeyRefArray element %d: Expected String, got %s" % [i, type_string(typeof(field_value[i]))]
					)
		return

	# For standard types, check against Variant type
	var variant_type: int = EntitySchema.field_type_to_variant_type(expected_type)

	# Special case: JSON loads all numbers as floats, so accept floats for INT fields if they're whole numbers
	if expected_type == EntitySchema.FieldType.INT and typeof(field_value) == TYPE_FLOAT:
		if field_value == floor(field_value):
			# Float represents a whole number, acceptable for INT field
			return
		else:
			result.add_error(
				ValidationError.Type.INVALID_TYPE,
				entity_type,
				entity_key,
				field_name,
				"Expected INT, got FLOAT with decimal value %s" % field_value
			)
			return

	if typeof(field_value) != variant_type:
		result.add_error(
			ValidationError.Type.INVALID_TYPE,
			entity_type,
			entity_key,
			field_name,
			"Expected %s, got %s" % [
				EntitySchema.field_type_name(expected_type),
				type_string(typeof(field_value))
			]
		)

## Validates field constraints (min, max, etc.)
func _validate_field_constraints(field_name: String, field_value, field_def: Dictionary, entity_type: String, entity_key: String, result: ValidationResult) -> void:
	# Numeric min/max constraints
	if field_def.has("min"):
		if typeof(field_value) == TYPE_INT or typeof(field_value) == TYPE_FLOAT:
			if field_value < field_def["min"]:
				result.add_error(
					ValidationError.Type.CONSTRAINT_VIOLATION,
					entity_type,
					entity_key,
					field_name,
					"Value %s is less than minimum %s" % [field_value, field_def["min"]]
				)

	if field_def.has("max"):
		if typeof(field_value) == TYPE_INT or typeof(field_value) == TYPE_FLOAT:
			if field_value > field_def["max"]:
				result.add_error(
					ValidationError.Type.CONSTRAINT_VIOLATION,
					entity_type,
					entity_key,
					field_name,
					"Value %s exceeds maximum %s" % [field_value, field_def["max"]]
				)

	# Array length constraints
	if typeof(field_value) == TYPE_ARRAY:
		if field_def.has("max_length"):
			if field_value.size() > field_def["max_length"]:
				result.add_error(
					ValidationError.Type.CONSTRAINT_VIOLATION,
					entity_type,
					entity_key,
					field_name,
					"Array length %d exceeds maximum %d" % [field_value.size(), field_def["max_length"]]
				)
		if field_def.has("min_length"):
			if field_value.size() < field_def["min_length"]:
				result.add_error(
					ValidationError.Type.CONSTRAINT_VIOLATION,
					entity_type,
					entity_key,
					field_name,
					"Array length %d is less than minimum %d" % [field_value.size(), field_def["min_length"]]
				)

	# String length constraints
	if typeof(field_value) == TYPE_STRING:
		if field_def.has("max_length"):
			if field_value.length() > field_def["max_length"]:
				result.add_error(
					ValidationError.Type.CONSTRAINT_VIOLATION,
					entity_type,
					entity_key,
					field_name,
					"String length %d exceeds maximum %d" % [field_value.length(), field_def["max_length"]]
				)
		if field_def.has("min_length"):
			if field_value.length() < field_def["min_length"]:
				result.add_error(
					ValidationError.Type.CONSTRAINT_VIOLATION,
					entity_type,
					entity_key,
					field_name,
					"String length %d is less than minimum %d" % [field_value.length(), field_def["min_length"]]
				)
