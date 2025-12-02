## ActionSchema
## Schema definition for Action entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name": {
		"type": FieldType.STRING,
		"required": false
	},
	"parameters": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Parameter"
	},
	"if": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Condition"
	},
	"do": {
		"type": FieldType.STRING,
		"required": true
	},
	"else": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	},
	"then": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	},
	"time": {
		"type": FieldType.FLOAT,
		"required": false,
		"default": 0.0,
		"min": 0.0
	},
	"animation": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Animation"
	}
}

static func get_fields() -> Dictionary:
	return fields
