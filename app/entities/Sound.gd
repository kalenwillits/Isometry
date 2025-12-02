## Sound Entity
## An audio file with volume control and looping options.
##
extends Entity

## Path to audio file.
var source: String
## Volume scale multiplier (dice expression, e.g., "1.0" or "1d4*0.25").
var scale: String
## If true, audio loops continuously.
var loop: bool

func _ready() -> void:
	tag(Group.SOUND_ENTITY)
