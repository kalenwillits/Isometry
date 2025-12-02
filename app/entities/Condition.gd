## Condition Entity
## A boolean comparison used in action if/else logic.
##
extends Entity

## Left operand of comparison. Future: dice expression support.
var left: String # TODO - dice
## Comparison operator (==, !=, <, >, <=, >=). NOT NULL.
var operator: String # NOT NULL
## Right operand of comparison. Future: dice expression support.
var right: String # TODO - dice

func _ready() -> void:
	tag(Group.CONDITION_ENTITY)
