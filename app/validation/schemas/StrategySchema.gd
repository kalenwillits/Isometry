## StrategySchema
## Schema definition for Strategy entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"behaviors": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Behavior"
	}
}

static func get_fields() -> Dictionary:
	return fields
