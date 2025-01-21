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
		inject_target_resources()
		inject_caller_resources()
		inject_target_measures()
		inject_caller_measures()
	return RollEngine.new().roll(expression)
	
func inject_target_resources() -> void:
	if target_name == "": return
	var target_actor: Actor = scene_tree.get_first_node_in_group(target_name)
	for target_resource_key in target_actor.resources.keys(): # TODO use regex
		if target_resource_key not in self.expression: continue
		var target_resource_code: String = "%s%s" % [TARGET_MARKER, target_resource_key]
		self.expression = self.expression.replacen(target_resource_code, str(target_actor.resources[target_resource_key]))
	
func inject_caller_resources() -> void:
	var caller_actor: Actor = scene_tree.get_first_node_in_group(caller_name)
	for caller_resource_key in caller_actor.resources.keys(): # TODO use regex
		if caller_resource_key not in self.expression: continue
		var caller_resource_code: String = "%s%s" % [TARGET_MARKER, caller_resource_key]
		self.expression = self.expression.replacen(caller_resource_code, str(caller_actor.resources[caller_resource_key]))

func inject_target_measures() -> void:
	if target_name == "": return
	var target_actor: Actor = scene_tree.get_first_node_in_group(target_name)
	for target_measure_key in target_actor.measures.keys(): # TODO use regex
		if target_measure_key not in self.expression: continue
		var target_measure_code: String = "%s%s" % [TARGET_MARKER, target_measure_key]
		self.expression = self.expression.replacen(target_measure_code, str(target_actor.measures[target_measure_key].call()))
	
func inject_caller_measures() -> void:
	var caller_actor: Actor = scene_tree.get_first_node_in_group(caller_name)
	for caller_measure_key in caller_actor.measures.keys(): # TODO use regex
		if caller_measure_key not in self.expression: continue
		var caller_measure_code: String = "%s%s" % [TARGET_MARKER, caller_measure_key]
		self.expression = self.expression.replacen(caller_measure_code, str(caller_actor.measures[caller_measure_key].call()))
