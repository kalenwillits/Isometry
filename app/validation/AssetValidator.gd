## AssetValidator
## Validates that all referenced asset paths exist in the campaign ZIP archive.
##
class_name AssetValidator

var archive: ZIPReader
var available_files: Array = []

func _init(p_archive: ZIPReader) -> void:
	archive = p_archive
	if archive != null:
		available_files = archive.get_files()

## Asset fields for each entity type
const ASSET_FIELDS: Dictionary = {
	"Sprite": {"texture": ["png", "jpg", "jpeg"]},
	"Resource": {"icon": ["png", "jpg", "jpeg"]},
	"Measure": {"icon": ["png", "jpg", "jpeg"]},
	"Skill": {"icon": ["png", "jpg", "jpeg"]},
	"Waypoint": {"icon": ["png", "jpg", "jpeg"]},
	"Sound": {"source": ["mp3", "wav", "ogg"]},
	"Floor": {"texture": ["png", "jpg", "jpeg"]},
	"TileSet": {"texture": ["png", "jpg", "jpeg"]},
	"Parallax": {"texture": ["png", "jpg", "jpeg"]},
	"Layer": {"source": ["tmj"]}
}

## Validates all asset paths in the campaign
func validate(asset_dict: Dictionary, result: ValidationResult) -> void:
	if archive == null:
		return  # Skip validation if no archive provided

	for entity_type in ASSET_FIELDS.keys():
		if not asset_dict.has(entity_type):
			continue

		var field_defs: Dictionary = ASSET_FIELDS[entity_type]

		for entity_key in asset_dict[entity_type].keys():
			var entity_data: Dictionary = asset_dict[entity_type][entity_key]

			for field_name in field_defs.keys():
				if not entity_data.has(field_name):
					continue

				var asset_path: String = entity_data[field_name]
				if asset_path.is_empty():
					continue

				var allowed_extensions: Array = field_defs[field_name]
				_validate_asset_path(asset_path, allowed_extensions, entity_type, entity_key, field_name, result)

## Validates a single asset path exists in archive
func _validate_asset_path(asset_path: String, allowed_extensions: Array, entity_type: String, entity_key: String, field_name: String, result: ValidationResult) -> void:
	# Normalize path: strip leading '/' only
	var normalized_path: String = asset_path.lstrip("/")

	# Check if any ZIP file ends with this normalized path
	var found: bool = false
	for zip_file in available_files:
		if zip_file.ends_with(normalized_path):
			found = true
			break

	if not found:
		result.add_error(
			ValidationError.Type.ASSET_NOT_FOUND,
			entity_type,
			entity_key,
			field_name,
			"Asset '%s' not found in campaign archive" % asset_path
		)
		return

	# Validate file extension (skip if file has no extension)
	var extension: String = asset_path.get_extension().to_lower()
	if not extension.is_empty() and extension not in allowed_extensions:
		result.add_error(
			ValidationError.Type.ASSET_NOT_FOUND,
			entity_type,
			entity_key,
			field_name,
			"Asset '%s' has invalid extension '.%s', expected one of: %s" % [
				asset_path,
				extension,
				", ".join(allowed_extensions)
			]
		)
