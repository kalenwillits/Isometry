extends Object
class_name Dice

var caller_name: String
var target_name: String
var scene_tree: SceneTree
var expression: String

const TARGET_MARKER: String = "."
const CALLER_MARKER: String = ":"

class Builder extends Object:
	var this: Dice = Dice.new()
	
	func scene_tree(scene_tree: SceneTree) -> Builder:
		this.scene_tree = scene_tree
		return self
	
	func caller(self_name: String) -> Builder:
		this.caller_name = self_name
		return self
	
	func target(target_name: String) -> Builder:
		this.target_name = target_name
		return self
	
	func expression(expr: String) -> Builder:
		this.expression = expr
		return self
	
	func build() -> Dice:
		return this
		
static func builder() -> Builder:
	return Builder.new()
	
func evaluate() -> int:
	if scene_tree != null:
		inject_resources()
	return RollEngine.new().roll(expression)
	
func inject_resources() -> void:
	var target_actor: Actor = scene_tree.get_first_node_in_group(target_name)
	for resource_key in target_actor.resources.keys():
		var target_resource_code: String = "%s%s" % [TARGET_MARKER, resource_key]
		self.expression = self.expression.replacen(target_resource_code, str(target_actor.resources[resource_key]))
	var caller_actor: Actor = scene_tree.get_first_node_in_group(target_name)
	for resource_key in caller_actor.resources.keys():
		var caller_resource_code: String = "%s%s" % [TARGET_MARKER, resource_key]
		self.expression = self.expression.replacen(caller_resource_code, str(caller_actor.resources[resource_key]))
