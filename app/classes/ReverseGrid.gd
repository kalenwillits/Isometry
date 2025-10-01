extends GridContainer
class_name ReverseGrid

## A Grid that grows in the opposite direction

func _notification(what):
	match (what):
		NOTIFICATION_SORT_CHILDREN:
			for i in get_child_count():
				var child = get_child(i)
				var hs = get("custom_constants/hseparation")
				var vs = get("custom_constants/vseparation")
				var row = floor(i / columns)
#				child.rect_position = Vector2(i % columns * -hs, row * -vs)
