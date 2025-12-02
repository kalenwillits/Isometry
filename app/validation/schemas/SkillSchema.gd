## SkillSchema
## Schema definition for Skill entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name": {
		"type": FieldType.STRING,
		"required": false
	},
	"start": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	},
	"end": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	},
	"icon": {
		"type": FieldType.STRING,
		"required": false
	},
	"description": {
		"type": FieldType.STRING,
		"required": false,
		"default": ""
	},
	"charge": {
		"type": FieldType.INT,
		"required": false,
		"default": 0,
		"min": 0
	},
	"casting": {
		"type": FieldType.STRING,
		"required": false,
		"default": ""
	},
	"radius": {
		"type": FieldType.INT,
		"required": false
	},
	"speed": {
		"type": FieldType.FLOAT,
		"required": false
	},
	"range": {
		"type": FieldType.INT,
		"required": false
	},
	"time": {
		"type": FieldType.FLOAT,
		"required": false
	},
	"color": {
		"type": FieldType.STRING,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
