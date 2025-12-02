## BehaviorSchema
## Schema definition for Behavior entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"goals": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Condition"
	},
	"action": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	}
}

static func get_fields() -> Dictionary:
	return fields
