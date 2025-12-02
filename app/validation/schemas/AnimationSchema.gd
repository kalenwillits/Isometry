## AnimationSchema
## Schema definition for Animation entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"N": {
		"type": FieldType.ARRAY,
		"required": false,
		"default": []
	},
	"NE": {
		"type": FieldType.ARRAY,
		"required": false,
		"default": []
	},
	"E": {
		"type": FieldType.ARRAY,
		"required": false,
		"default": []
	},
	"SE": {
		"type": FieldType.ARRAY,
		"required": false,
		"default": []
	},
	"S": {
		"type": FieldType.ARRAY,
		"required": false,
		"default": []
	},
	"SW": {
		"type": FieldType.ARRAY,
		"required": false,
		"default": []
	},
	"W": {
		"type": FieldType.ARRAY,
		"required": false,
		"default": []
	},
	"NW": {
		"type": FieldType.ARRAY,
		"required": false,
		"default": []
	},
	"sound": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Sound"
	},
	"loop": {
		"type": FieldType.BOOL,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
