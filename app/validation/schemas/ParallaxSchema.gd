## ParallaxSchema
## Schema definition for Parallax entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"texture": {
		"type": FieldType.STRING,
		"required": false
	},
	"effect": {
		"type": FieldType.FLOAT,
		"required": false,
		"min": 0.0
	}
}

static func get_fields() -> Dictionary:
	return fields
