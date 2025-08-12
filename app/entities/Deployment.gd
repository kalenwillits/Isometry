extends Entity

var location: KeyRef
var actor: KeyRef

func _ready() -> void:
	tag(Group.DEPLOYMENT_ENTITY)
