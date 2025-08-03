extends Entity

var symbol: String
var index: int
var polygon: KeyRef
var origin: int
var navigation: bool

func _ready() -> void:
	tag(tile_group_name())
	tag(Group.TILE_ENTITY)
	
func tile_group_name() -> String:
	return "%s-%s" % [Group.TILE_ENTITY, symbol]
