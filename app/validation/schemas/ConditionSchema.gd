## ConditionSchema
## Schema definition for Condition entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"left": {
		"type": FieldType.STRING,
		"required": false
	},
	"operator": {
		"type": FieldType.STRING,
		"required": true
	},
	"right": {
		"type": FieldType.STRING,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
