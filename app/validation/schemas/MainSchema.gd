## MainSchema
## Schema definition for Main entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"actor": {
		"type": FieldType.KEYREF,
		"required": true,
		"target_type": "Actor"
	},
	"map": {
		"type": FieldType.KEYREF,
		"required": true,
		"target_type": "Map"
	},
	"notes": {
		"type": FieldType.STRING,
		"required": false,
		"default": ""
	}
}

static func get_fields() -> Dictionary:
	return fields
