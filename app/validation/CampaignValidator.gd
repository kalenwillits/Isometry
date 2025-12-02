## CampaignValidator
## Main orchestrator for campaign validation.
## Coordinates all validation phases and aggregates errors.
##
class_name CampaignValidator

var result: ValidationResult
var all_keys: Dictionary = {}  # entity_type -> [entity_keys]
var asset_dict: Dictionary = {}
var archive: ZIPReader

## Schema registry mapping entity type names to their schema classes
var schema_registry: Dictionary = {
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

## Validates campaign asset dictionary and ZIP archive
func validate(p_asset_dict: Dictionary, p_archive: ZIPReader) -> ValidationResult:
	result = ValidationResult.new()
	asset_dict = p_asset_dict
	archive = p_archive

	Logger.info("Starting campaign validation...")

	# Phase 1: Schema validation
	_validate_schemas()

	# Phase 2: Cross-reference validation
	_validate_cross_references()

	# Phase 3: Asset validation (if archive provided)
	if archive != null:
		_validate_assets()

	# Phase 4: Dice validation
	_validate_dice_expressions()

	if result.has_errors():
		Logger.error("Campaign validation failed with %d error(s)" % result.get_error_count())
	else:
		Logger.info("Campaign validation passed")

	return result

## Phase 1: Validate all entities against their schemas
func _validate_schemas() -> void:
	for entity_type in asset_dict.keys():
		# Get schema for this entity type
		var schema_class = schema_registry.get(entity_type)
		if schema_class == null:
			result.add_error(
				ValidationError.Type.UNKNOWN_TYPE,
				entity_type,
				"",
				"",
				"Unknown entity type '%s' - no schema defined" % entity_type
			)
			continue

		var schema: Dictionary = schema_class.get_fields()

		# Validate each entity of this type
		for entity_key in asset_dict[entity_type].keys():
			var entity_data: Dictionary = asset_dict[entity_type][entity_key]
			var validator := EntitySchemaValidator.new(schema)
			validator.validate(entity_data, entity_type, entity_key, result)

## Phase 2: Cross-reference validation (KeyRefs, Main entity, duplicates)
func _validate_cross_references() -> void:
	# Collect all entity keys first
	_collect_all_keys()

	# Validate Main entity (exactly 1)
	_validate_main_entity()

	# Validate no duplicate keys across entity types
	_validate_no_duplicate_keys()

	# Validate KeyRefs resolve
	var keyref_validator := KeyRefValidator.new(all_keys)
	keyref_validator.validate(asset_dict, result)

	# Validate action functions
	var action_validator := ActionValidator.new()
	action_validator.validate(asset_dict, result)

## Phase 3: Validate asset paths exist in ZIP
func _validate_assets() -> void:
	var asset_validator := AssetValidator.new(archive)
	asset_validator.validate(asset_dict, result)

## Phase 4: Validate dice expressions
func _validate_dice_expressions() -> void:
	var dice_validator := DiceValidator.new()
	dice_validator.validate(asset_dict, result)

## Collects all entity keys grouped by type
func _collect_all_keys() -> void:
	all_keys.clear()
	for entity_type in asset_dict.keys():
		all_keys[entity_type] = asset_dict[entity_type].keys()

## Validates exactly one Main entity exists
func _validate_main_entity() -> void:
	var main_count := 0
	if asset_dict.has("Main"):
		main_count = asset_dict["Main"].keys().size()

	if main_count == 0:
		result.add_error(
			ValidationError.Type.MAIN_ENTITY_MISSING,
			"Main",
			"",
			"",
			"Campaign requires exactly one Main entity (found 0)"
		)
	elif main_count > 1:
		result.add_error(
			ValidationError.Type.MAIN_ENTITY_DUPLICATE,
			"Main",
			"",
			"",
			"Campaign requires exactly one Main entity (found %d)" % main_count
		)

## Validates no duplicate entity keys across different entity types
func _validate_no_duplicate_keys() -> void:
	var seen_keys: Dictionary = {}  # key -> [entity_types]

	for entity_type in all_keys.keys():
		for entity_key in all_keys[entity_type]:
			if not seen_keys.has(entity_key):
				seen_keys[entity_key] = []
			seen_keys[entity_key].append(entity_type)

	# Report duplicates
	for entity_key in seen_keys.keys():
		var types: Array = seen_keys[entity_key]
		if types.size() > 1:
			result.add_error(
				ValidationError.Type.DUPLICATE_KEY,
				types[0],
				entity_key,
				"",
				"Duplicate key '%s' found in entity types: %s" % [entity_key, ", ".join(types)]
			)
