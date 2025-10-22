extends GridContainer
class_name BottomUpGrid

## A Grid that grows upward when wrapping to new rows
## Can flow either left-to-right or right-to-left based on rtl parameter

@export var rtl: bool = false ## If true, grows from right to left

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

				# Calculate position
				var x_offset = col * (child.size.x + hs)
				if rtl:
					# Right to left
					x_offset = -x_offset

				# Rows grow upward (negative y)
				var y_offset = -row * (child.size.y + vs)

				child.position = Vector2(x_offset, y_offset)
