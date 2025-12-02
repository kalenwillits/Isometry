## TileMapSchema
## Schema definition for TileMap entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"tileset": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "TileSet"
	},
	"layers": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Layer"
	}
}

static func get_fields() -> Dictionary:
	return fields
