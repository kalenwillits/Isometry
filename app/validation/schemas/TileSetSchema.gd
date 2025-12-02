## TileSetSchema
## Schema definition for TileSet entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"columns": {
		"type": FieldType.INT,
		"required": false,
		"min": 1
	},
	"texture": {
		"type": FieldType.STRING,
		"required": false
	},
	"tiles": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Tile"
	}
}

static func get_fields() -> Dictionary:
	return fields
