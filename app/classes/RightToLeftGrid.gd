extends GridContainer
class_name RightToLeftGrid

## A Grid that grows from right to left instead of left to right

func _notification(what):
	match (what):
		NOTIFICATION_SORT_CHILDREN:
			var child_count = get_child_count()
			if child_count == 0:
				return

			var hs = get_theme_constant("h_separation")
			var vs = get_theme_constant("v_separation")

			for i in child_count:
				var child = get_child(i)
				if not child.is_visible_in_tree():
					continue

				var row = floor(i / columns)
				var col = i % columns

				# Position from right to left
				var x_offset = -col * (child.size.x + hs)
				var y_offset = row * (child.size.y + vs)

				child.position = Vector2(x_offset, y_offset)
