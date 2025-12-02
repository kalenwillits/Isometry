## FloorSchema
## Schema definition for Floor entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"location": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Vertex"
	},
	"texture": {
		"type": FieldType.STRING,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
