## VertexSchema
## Schema definition for Vertex entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"x": {
		"type": FieldType.INT,
		"required": false
	},
	"y": {
		"type": FieldType.INT,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
