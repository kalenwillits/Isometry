## Main Entity
## Campaign configuration defining the starting state.
## A Main entity is required for each campaign and for
## each campaign, there can only be one Main entity.
##
extends Entity

## Main player-controlled Actor entity.
var actor: KeyRef # Actor
## Starting Map entity where campaign begins.
var map: KeyRef # Map
## Campaign notes or description. Default empty.
var notes: String = ""

func _ready() -> void:
	tag(Group.MAIN_ENTITY)
