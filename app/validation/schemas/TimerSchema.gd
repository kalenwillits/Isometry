## TimerSchema
## Schema definition for Timer entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"total": {
		"type": FieldType.DICE_EXPRESSION,
		"required": false
	},
	"interval": {
		"type": FieldType.DICE_EXPRESSION,
		"required": false
	},
	"action": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	}
}

static func get_fields() -> Dictionary:
	return fields
