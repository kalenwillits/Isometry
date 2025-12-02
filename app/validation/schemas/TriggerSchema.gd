## TriggerSchema
## Schema definition for Trigger entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"resource": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Resource"
	},
	"action": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	}
}

static func get_fields() -> Dictionary:
	return fields
