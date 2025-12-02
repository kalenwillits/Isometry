## SpriteSchema
## Schema definition for Sprite entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"animation_set": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "AnimationSet"
	},
	"texture": {
		"type": FieldType.STRING,
		"required": false
	},
	"size": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Vertex"
	},
	"margin": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Vertex"
	}
}

static func get_fields() -> Dictionary:
	return fields
