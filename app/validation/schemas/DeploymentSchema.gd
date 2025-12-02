## DeploymentSchema
## Schema definition for Deployment entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"location": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Vertex"
	},
	"actor": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Actor"
	}
}

static func get_fields() -> Dictionary:
	return fields
