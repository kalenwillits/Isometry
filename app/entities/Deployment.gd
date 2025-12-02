## Deployment Entity
## Defines an actor's initial placement on a map.
##
extends Entity

## Vertex entity defining spawn position (x, y).
var location: KeyRef # Vertex
## Actor entity to deploy at this location.
var actor: KeyRef # Actor

func _ready() -> void:
	tag(Group.DEPLOYMENT_ENTITY)
