## MenuSchema
## Schema definition for Menu entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name": {
		"type": FieldType.STRING,
		"required": false
	},
	"actions": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Action"
	}
}

static func get_fields() -> Dictionary:
	return fields
