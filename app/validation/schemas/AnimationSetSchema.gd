## AnimationSetSchema
## Schema definition for AnimationSet entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name": {
		"type": FieldType.STRING,
		"required": false
	},
	"animations": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Animation"
	}
}

static func get_fields() -> Dictionary:
	return fields
