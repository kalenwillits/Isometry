## PlateSchema
## Schema definition for Plate entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"title": {
		"type": FieldType.STRING,
		"required": true
	},
	"text": {
		"type": FieldType.STRING,
		"required": true
	}
}

static func get_fields() -> Dictionary:
	return fields
