## TileSchema
## Schema definition for Tile entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"symbol": {
		"type": FieldType.STRING,
		"required": false
	},
	"index": {
		"type": FieldType.INT,
		"required": false,
		"min": 0
	},
	"origin": {
		"type": FieldType.INT,
		"required": false
	},
	"navigation": {
		"type": FieldType.BOOL,
		"required": false
	},
	"obstacle": {
		"type": FieldType.BOOL,
		"required": false
	},
	"ghost": {
		"type": FieldType.BOOL,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
