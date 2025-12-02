## WaypointSchema
## Schema definition for Waypoint entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name_": {
		"type": FieldType.STRING,
		"required": false
	},
	"location": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Vertex"
	},
	"icon": {
		"type": FieldType.STRING,
		"required": false
	},
	"map": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Map"
	},
	"menu": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Menu"
	},
	"description": {
		"type": FieldType.STRING,
		"required": false
	}
}

static func get_fields() -> Dictionary:
	return fields
