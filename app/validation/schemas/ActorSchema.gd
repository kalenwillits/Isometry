## ActorSchema
## Schema definition for Actor entities.
##
## Standalone schema class

const FieldType = EntitySchema.FieldType

static var fields: Dictionary = {
	"name": {
		"type": FieldType.STRING,
		"required": false
	},
	"sprite": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Sprite"
	},
	"base": {
		"type": FieldType.INT,
		"required": false,
		"min": 0
	},
	"hitbox": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Polygon"
	},
	"perception": {
		"type": FieldType.INT,
		"required": false,
		"min": 0
	},
	"salience": {
		"type": FieldType.INT,
		"required": false,
		"min": 0
	},
	"on_touch": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	},
	"on_view": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	},
	"on_map_entered": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	},
	"on_map_exited": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Action"
	},
	"public": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Resource"
	},
	"private": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Resource"
	},
	"skills": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Skill",
		"max_length": 9
	},
	"resources": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Resource"
	},
	"measures": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Measure"
	},
	"group": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Group"
	},
	"menu": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Menu"
	},
	"triggers": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Trigger"
	},
	"timers": {
		"type": FieldType.KEYREF_ARRAY,
		"required": false,
		"element_type": "Timer"
	},
	"strategy": {
		"type": FieldType.KEYREF,
		"required": false,
		"target_type": "Strategy"
	},
	"speed": {
		"type": FieldType.FLOAT,
		"required": false,
		"min": 0.0
	},
	"bearing": {
		"type": FieldType.INT,
		"required": false,
		"default": 0,
		"min": 0,
		"max": 360
	}
}

static func get_fields() -> Dictionary:
	return fields
