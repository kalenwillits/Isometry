extends Node
class_name Dice

var caller_peer_id: int
var target_peer_id: int
var expression: String

class Builder extends Object:
	var this: Dice = Dice.new()
	
	func caller(peer_id: int) -> Builder:
		this.caller_peer_id = peer_id
		return self
	
	func target(peer_id: int) -> Builder:
		this.target_peer_id = peer_id
		return self
	
	func expression(expr: String) -> Builder:
		this.experssion = expr
		return self
	
	func build() -> Dice:
		return this
		
static func builder() -> Builder:
	return Builder.new()

func evaluate() -> int:
	return RollEngine.evaluate(expression)
