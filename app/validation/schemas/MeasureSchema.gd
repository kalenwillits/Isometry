## MeasureSchema
## Schema definition for Measure entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"expression": {
		"type": FieldType.DICE_EXPRESSION,
		"required": false
	},
	"icon": {
		"type": FieldType.STRING,
		"required": false
	},
	"public": {
		"type": FieldType.BOOL,
		"required": false
	},
	"private": {
		"type": FieldType.BOOL,
		"required": false
	},
	"reveal": {
		"type": FieldType.INT,
		"required": false,
		"min": 0
	},
	"menu": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Menu"
	}
}

static func get_fields() -> Dictionary:
	return fields
