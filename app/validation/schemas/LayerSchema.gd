## LayerSchema
## Schema definition for Layer entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"source": {
		"type": FieldType.STRING,
		"required": false
	},
	"ysort": {
		"type": FieldType.BOOL,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
