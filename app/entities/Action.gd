## Action Entity
## An action used by an actor to effect resources.
##
extends Entity

## Human-readable name of action.
var name_: String
## Array of of parameters. They are expected to match the parameters of the `do` in action.gd 
var parameters: KeyRefArray # Parameter
## If condition to check if the `do` action should be executed.
var if_: KeyRef # Condition
## Function name of action. Must be a valid action function
var do: String # NOT NULL, Must be a defined action function
## KeyRef to another action. To be run if the `if` condtion fails. Must be a valid action key defined in the campaign.
var else_: KeyRef # Action
## KeyRef to anther action. To be run if the `if` condition succeeds after the `do` action function is complete. 
var then: KeyRef # Action
## The time this action takes to execute in seconds. Expressed as a float.
var time: float # default=0.0
## The KeyRef to the animation entity that runs while this action is running. If not null, time must be greater that 0.0 
var animation: KeyRef # Animation

func _ready() -> void:
	tag(Group.ACTION_ENTITY)
