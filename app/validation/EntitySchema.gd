## EntitySchema
## Base class for entity schema definitions.
## Each entity type should extend this and define its fields dictionary.
##
class_name EntitySchema

## Field type constants (matching GDScript TYPE_* constants and custom types)
enum FieldType {
	STRING,           # TYPE_STRING
	INT,              # TYPE_INT
	FLOAT,            # TYPE_FLOAT
	BOOL,             # TYPE_BOOL
	VECTOR2,          # TYPE_VECTOR2
	COLOR,            # TYPE_COLOR
	KEYREF,           # Custom: KeyRef reference
	KEYREF_ARRAY,     # Custom: Array of KeyRefs
	DICT,             # TYPE_DICTIONARY
	ARRAY,            # TYPE_ARRAY
	DICE_EXPRESSION   # Custom: Dice notation string
}

## Schema definition structure:
## {
##   "field_name": {
##     "type": FieldType,
##     "required": bool,
##     "default": any (if not required),
##     "min": number (for numeric types),
##     "max": number (for numeric types),
##     "target_type": String (for KEYREF types, expected entity type),
##     "element_type": String (for KEYREF_ARRAY, expected entity type),
##     "validator": String (custom validator function name)
##   }
## }

## Maps FieldType enum to GDScript TYPE_* constants where applicable
static func field_type_to_variant_type(field_type: FieldType) -> int:
	match field_type:
		FieldType.STRING, FieldType.DICE_EXPRESSION:
			return TYPE_STRING
		FieldType.INT:
			return TYPE_INT
		FieldType.FLOAT:
			return TYPE_FLOAT
		FieldType.BOOL:
			return TYPE_BOOL
		FieldType.VECTOR2:
			return TYPE_VECTOR2
		FieldType.COLOR:
			return TYPE_COLOR
		FieldType.DICT:
			return TYPE_DICTIONARY
		FieldType.ARRAY, FieldType.KEYREF_ARRAY:
			return TYPE_ARRAY
		FieldType.KEYREF:
			return TYPE_STRING  # KeyRefs are stored as strings
		_:
			return TYPE_NIL

## Returns human-readable name for field type
static func field_type_name(field_type: FieldType) -> String:
	return FieldType.keys()[field_type]
