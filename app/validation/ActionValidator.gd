## ActionValidator
## Validates Action entities have valid function names and parameters.
##
class_name ActionValidator

## List of valid action function names from actions.gd
const VALID_ACTION_FUNCTIONS: Array = [
	"echo",
	"wait",
	"set_destination_self",
	"change_map_target",
	"change_map_self",
	"minus_resource_target",
	"minus_resource_self",
	"plus_resource_self",
	"plus_resource_target",
	"set_resource_self",
	"set_resource_target",
	"transfer_resource",
	"target_nearest",
	"target_furthest",
	"target_random",
	"target_lowest_resource",
	"target_highest_resource",
	"target_lowest_measure",
	"target_highest_measure",
	"target_nearest_in_group",
	"target_random_in_group",
	"clear_target_self",
	"move_to_target",
	"move_away_from_target",
	"move_to_target_radial",
	"move_to_self_radial",
	"push_target_away",
	"pull_target_closer",
	"teleport_self_to_target",
	"teleport_target_to_self",
	"teleport_self_to_target_radial",
	"teleport_target_to_self_radial",
	"teleport_to_radial",
	"teleport",
	"swap_positions",
	"area_of_effect_at_self",
	"area_of_effect_at_target",
	"area_of_effect_at_self_radial",
	"area_of_effect_at_target_radial",
	"despawn_self",
	"despawn_target",
	"change_actor_self",
	"change_actor_target",
	"spawn_actor_at_self",
	"spawn_actor_at_target",
	"spawn_actor_at_self_radial",
	"spawn_actor_at_target_radial",
	"play_keyframe_self",
	"play_keyframe_target",
	"use_track",
	"change_strategy",
	"set_speed_target",
	"set_speed_self",
	"temp_speed_target",
	"temp_speed_self",
	"set_modulate_self",
	"set_modulate_target",
	"open_options",
	"close_game",
	"show_connection_info",
	"open_chat",
	"open_plate"
]

## Required parameters for each action function
const ACTION_REQUIRED_PARAMS: Dictionary = {
	"echo": ["message"],
	"set_destination_self": ["waypoint"],
	"change_map_target": ["map"],
	"change_map_self": ["map"],
	"minus_resource_target": ["resource", "expression"],
	"minus_resource_self": ["resource", "expression"],
	"plus_resource_self": ["resource", "expression"],
	"plus_resource_target": ["resource", "expression"],
	"set_resource_self": ["resource", "expression"],
	"set_resource_target": ["resource", "expression"],
	"transfer_resource": ["resource", "expression"],
	"target_lowest_resource": ["resource"],
	"target_highest_resource": ["resource"],
	"target_lowest_measure": ["measure"],
	"target_highest_measure": ["measure"],
	"target_nearest_in_group": ["group"],
	"target_random_in_group": ["group"],
	"move_away_from_target": ["distance"],
	"move_to_target_radial": ["radial", "distance"],
	"move_to_self_radial": ["radial", "distance"],
	"push_target_away": ["distance"],
	"pull_target_closer": ["distance"],
	"teleport_self_to_target_radial": ["radial", "distance"],
	"teleport_target_to_self_radial": ["radial", "distance"],
	"teleport_to_radial": ["radial", "distance"],
	"teleport": ["x", "y"],
	"area_of_effect_at_self": ["action", "radius"],
	"area_of_effect_at_target": ["action", "radius"],
	"area_of_effect_at_self_radial": ["action", "radial", "distance", "radius"],
	"area_of_effect_at_target_radial": ["action", "radial", "distance", "radius"],
	"change_actor_self": ["actor"],
	"change_actor_target": ["actor"],
	"spawn_actor_at_self": ["actor"],
	"spawn_actor_at_target": ["actor"],
	"spawn_actor_at_self_radial": ["actor", "radial", "distance"],
	"spawn_actor_at_target_radial": ["actor", "radial", "distance"],
	"play_keyframe_self": ["animation"],
	"play_keyframe_target": ["animation"],
	"use_track": ["track"],
	"change_strategy": ["strategy"],
	"set_speed_target": ["speed"],
	"set_speed_self": ["speed"],
	"temp_speed_target": ["speed", "duration"],
	"temp_speed_self": ["speed", "duration"],
	"set_modulate_self": ["color"],
	"set_modulate_target": ["color"],
	"open_plate": ["plate"]
}

## Validates all Action entities in the campaign
func validate(asset_dict: Dictionary, result: ValidationResult) -> void:
	if not asset_dict.has("Action"):
		return

	for action_key in asset_dict["Action"].keys():
		var action_data: Dictionary = asset_dict["Action"][action_key]

		# Validate action function name exists
		if not action_data.has("do"):
			continue  # Already caught by schema validation

		var func_name: String = action_data["do"]
		if func_name not in VALID_ACTION_FUNCTIONS:
			result.add_error(
				ValidationError.Type.INVALID_ACTION_NAME,
				"Action",
				action_key,
				"do",
				"Action function '%s' does not exist in actions.gd" % func_name
			)
			continue

		# Validate required parameters are present
		_validate_action_parameters(action_data, action_key, func_name, result)

## Validates action parameters match function requirements
func _validate_action_parameters(action_data: Dictionary, action_key: String, func_name: String, result: ValidationResult) -> void:
	if not ACTION_REQUIRED_PARAMS.has(func_name):
		return  # No required parameters

	var required_params: Array = ACTION_REQUIRED_PARAMS[func_name]
	var parameters: Array = action_data.get("parameters", [])

	# Build set of provided parameter names
	var provided_params: Dictionary = {}
	for param_ref in parameters:
		# Note: param_ref is a KeyRef to a Parameter entity
		# We can't validate the actual parameter names here without loading Parameter entities
		# This would be done at runtime or we'd need to resolve the KeyRefs first
		pass

	# For now, we just validate that parameters field exists if required params > 0
	if required_params.size() > 0 and parameters.size() == 0:
		result.add_error(
			ValidationError.Type.INVALID_ACTION_PARAM,
			"Action",
			action_key,
			"parameters",
			"Action function '%s' requires parameters: %s" % [func_name, ", ".join(required_params)]
		)
