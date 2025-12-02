## ResourceSchema
## Schema definition for Resource entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name": {
		"type": FieldType.STRING,
		"required": false
	},
	"default": {
		"type": FieldType.INT,
		"required": false
	},
	"min": {
		"type": FieldType.INT,
		"required": false
	},
	"max": {
		"type": FieldType.INT,
		"required": false
	},
	"icon": {
		"type": FieldType.STRING,
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
	},
	"description": {
		"type": FieldType.STRING,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
