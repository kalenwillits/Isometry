## KeyRefValidator
## Validates that all KeyRef and KeyRefArray references resolve to existing entities.
##
class_name KeyRefValidator

var all_keys: Dictionary  # entity_type -> [entity_keys]
var all_keys_flat: Dictionary  # entity_key -> entity_type (for quick lookup)

func _init(p_all_keys: Dictionary) -> void:
	all_keys = p_all_keys
	_build_flat_lookup()

## Builds a flat lookup dictionary for fast key resolution
func _build_flat_lookup() -> void:
	all_keys_flat.clear()
	for entity_type in all_keys.keys():
		for entity_key in all_keys[entity_type]:
			all_keys_flat[entity_key] = entity_type

## Validates all KeyRef and KeyRefArray fields in the campaign
func validate(asset_dict: Dictionary, result: ValidationResult) -> void:
	for entity_type in asset_dict.keys():
		for entity_key in asset_dict[entity_type].keys():
			var entity_data: Dictionary = asset_dict[entity_type][entity_key]
			_validate_entity_keyrefs(entity_data, entity_type, entity_key, result)

## Validates all KeyRef fields in a single entity
func _validate_entity_keyrefs(entity_data: Dictionary, entity_type: String, entity_key: String, result: ValidationResult) -> void:
	# Get schema for this entity type to know which fields are KeyRefs
	var schema: Dictionary = _get_schema_for_type(entity_type)
	if schema.is_empty():
		return

	for field_name in entity_data.keys():
		if not schema.has(field_name):
			continue

		var field_def: Dictionary = schema[field_name]
		var field_value = entity_data[field_name]

		# Validate KeyRef fields
		if field_def.get("type") == EntitySchema.FieldType.KEYREF:
			if field_value is String and not field_value.is_empty():
				_validate_keyref(
					field_value,
					field_def.get("target_type", ""),
					entity_type,
					entity_key,
					field_name,
					result
				)

		# Validate KeyRefArray fields
		elif field_def.get("type") == EntitySchema.FieldType.KEYREF_ARRAY:
			if field_value is Array:
				for i in range(field_value.size()):
					var ref_key = field_value[i]
					if ref_key is String and not ref_key.is_empty():
						_validate_keyref(
							ref_key,
							field_def.get("element_type", ""),
							entity_type,
							entity_key,
							"%s[%d]" % [field_name, i],
							result
						)

## Validates a single KeyRef resolves to an existing entity
func _validate_keyref(ref_key: String, expected_type: String, entity_type: String, entity_key: String, field_name: String, result: ValidationResult) -> void:
	# Check if key exists
	if not all_keys_flat.has(ref_key):
		result.add_error(
			ValidationError.Type.KEYREF_UNRESOLVED,
			entity_type,
			entity_key,
			field_name,
			"KeyRef '%s' does not exist in campaign" % ref_key
		)
		return

	# Check if key resolves to expected type (if specified)
	if not expected_type.is_empty():
		var actual_type: String = all_keys_flat[ref_key]
		if actual_type != expected_type:
			result.add_error(
				ValidationError.Type.KEYREF_UNRESOLVED,
				entity_type,
				entity_key,
				field_name,
				"KeyRef '%s' resolves to type '%s', expected '%s'" % [ref_key, actual_type, expected_type]
			)

## Gets schema for an entity type (helper function)
func _get_schema_for_type(entity_type: String) -> Dictionary:
	# This should match the schema registry in CampaignValidator
	var schema_map: Dictionary = {
		"Action": preload("res://validation/schemas/ActionSchema.gd"),
		"Actor": preload("res://validation/schemas/ActorSchema.gd"),
		"Animation": preload("res://validation/schemas/AnimationSchema.gd"),
		"AnimationSet": preload("res://validation/schemas/AnimationSetSchema.gd"),
		"Behavior": preload("res://validation/schemas/BehaviorSchema.gd"),
		"Condition": preload("res://validation/schemas/ConditionSchema.gd"),
		"Deployment": preload("res://validation/schemas/DeploymentSchema.gd"),
		"Floor": preload("res://validation/schemas/FloorSchema.gd"),
		"Group": preload("res://validation/schemas/GroupSchema.gd"),
		"Layer": preload("res://validation/schemas/LayerSchema.gd"),
		"Main": preload("res://validation/schemas/MainSchema.gd"),
		"Map": preload("res://validation/schemas/MapSchema.gd"),
		"Measure": preload("res://validation/schemas/MeasureSchema.gd"),
		"Menu": preload("res://validation/schemas/MenuSchema.gd"),
		"Parallax": preload("res://validation/schemas/ParallaxSchema.gd"),
		"Parameter": preload("res://validation/schemas/ParameterSchema.gd"),
		"Plate": preload("res://validation/schemas/PlateSchema.gd"),
		"Polygon": preload("res://validation/schemas/PolygonSchema.gd"),
		"Resource": preload("res://validation/schemas/ResourceSchema.gd"),
		"Skill": preload("res://validation/schemas/SkillSchema.gd"),
		"Sound": preload("res://validation/schemas/SoundSchema.gd"),
		"Sprite": preload("res://validation/schemas/SpriteSchema.gd"),
		"Strategy": preload("res://validation/schemas/StrategySchema.gd"),
		"Tile": preload("res://validation/schemas/TileSchema.gd"),
		"TileMap": preload("res://validation/schemas/TileMapSchema.gd"),
		"TileSet": preload("res://validation/schemas/TileSetSchema.gd"),
		"Timer": preload("res://validation/schemas/TimerSchema.gd"),
		"Trigger": preload("res://validation/schemas/TriggerSchema.gd"),
		"Vertex": preload("res://validation/schemas/VertexSchema.gd"),
		"Waypoint": preload("res://validation/schemas/WaypointSchema.gd")
	}

	var schema_class = schema_map.get(entity_type)
	if schema_class != null:
		return schema_class.get_fields()
	return {}
