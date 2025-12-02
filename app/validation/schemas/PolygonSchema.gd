## PolygonSchema
## Schema definition for Polygon entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"vertices": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Vertex"
	}
}

static func get_fields() -> Dictionary:
	return fields
