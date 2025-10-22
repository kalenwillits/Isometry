extends GridContainer
class_name CenterExpandGrid

## A Grid that grows symmetrically from the center outward
## Resource 0 appears in center, then 1-2 on either side, 3-4 further out, etc.

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

				# Calculate centered position
				# Even indices (0, 2, 4...) go to the right
				# Odd indices (1, 3, 5...) go to the left
				var center_offset = 0
				if i == 0:
					# First item is centered
					center_offset = 0
				elif i % 2 == 1:
					# Odd indices go left
					var left_count = (i + 1) / 2
					center_offset = -left_count * (child.size.x + hs)
				else:
					# Even indices go right
					var right_count = i / 2
					center_offset = right_count * (child.size.x + hs)

				# Handle multi-row layouts
				var y_offset = row * (child.size.y + vs)

				child.position = Vector2(center_offset, y_offset)
