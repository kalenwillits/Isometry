## MapSchema
## Schema definition for Map entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name": {
		"type": FieldType.STRING,
		"required": false
	},
	"title": {
		"type": FieldType.STRING,
		"required": false
	},
	"floor": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Floor"
	},
	"tilemap": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "TileMap"
	},
	"spawn": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Vertex"
	},
	"deployments": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Deployment"
	},
	"background": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Parallax"
	},
	"audio": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Sound"
	}
}

static func get_fields() -> Dictionary:
	return fields
