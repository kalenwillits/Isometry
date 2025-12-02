## SoundSchema
## Schema definition for Sound entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"source": {
		"type": FieldType.STRING,
		"required": false
	},
	"scale": {
		"type": FieldType.DICE_EXPRESSION,
		"required": false
	},
	"loop": {
		"type": FieldType.BOOL,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
