## ParameterSchema
## Schema definition for Parameter entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name": {
		"type": FieldType.STRING,
		"required": true
	},
	"value": {
		"type": FieldType.STRING,
		"required": true
	}
}

static func get_fields() -> Dictionary:
	return fields
