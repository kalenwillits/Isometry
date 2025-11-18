extends CanvasLayer

const PAGE_SIZE: Vector2i = Vector2i(408, 512)
# TODO - This NEWLINE_LOOKBACK_LINES feature does not actually work, fix or remove it.
const NEWLINE_LOOKBACK_LINES: int = 9 # How many lines to search upward for natural paragraph breaks

var plate_entity: Entity
var caller_name: String = ""
var target_name: String = ""
var processed_text: String = ""
var current_page: int = 0
var total_pages: int = 1
var page_breaks: Array[int] = []  # Indices where pages break
var char_mapper: CharacterWidthMapper

@onready var rich_text_label: RichTextLabel = $Overlay/CenterContainer/PanelContainer/VBox/ScrollContainer/RichTextLabel
@onready var title_label: Label = $Overlay/CenterContainer/PanelContainer/VBox/Title
@onready var pagination_label: Label = $Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationLabel
@onready var bottom_bar: HBoxContainer = $Overlay/CenterContainer/PanelContainer/VBox/BottomBar

var prev_button: Button
var next_button: Button

func _ready() -> void:
	visible = false
	add_to_group(Group.PLATE_VIEW)

	# Initialize character width mapper
	char_mapper = CharacterWidthMapper.new()
	char_mapper.initialize(rich_text_label)

	# Create pagination buttons
	_create_pagination_buttons()

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)

func _create_pagination_buttons() -> void:
	# Create Previous button
	prev_button = Button.new()
	prev_button.text = "←"
	prev_button.custom_minimum_size = Vector2(40, 24)
	prev_button.pressed.connect(_on_prev_button_pressed)
	bottom_bar.add_child(prev_button)
	bottom_bar.move_child(prev_button, 0)  # Move to first position

	# Pagination label is already in the middle (created in scene)

	# Create Next button
	next_button = Button.new()
	next_button.text = "→"
	next_button.custom_minimum_size = Vector2(40, 24)
	next_button.pressed.connect(_on_next_button_pressed)
	bottom_bar.add_child(next_button)  # Add to end

func _on_prev_button_pressed() -> void:
	previous_page()

func _on_next_button_pressed() -> void:
	next_page()


func _on_visibility_changed() -> void:
	if visible:
		var theme_mgr = get_node_or_null("/root/ThemeManager")
		if theme_mgr:
			theme_mgr._apply_theme_recursive(self)
			
			
func reset() -> void:
	title_label.set_text("")
	rich_text_label.set_text("")

func open_plate(plate_ent: Entity, caller: String, target: String) -> void:
	reset()
	if plate_ent == null:
		Logger.warn("Cannot open plate: invalid plate entity")
		return

	plate_entity = plate_ent
	caller_name = caller
	target_name = target
	current_page = 0

	# Process text through Dice engine for resource/measure injection
	processed_text = process_text(plate_entity.text)

	# Set title
	title_label.set_text(plate_entity.title if plate_entity.title else "")

	# Make visible first so layout is computed
	visible = true

	# Enqueue pagination calculation to run after layout is ready
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Calculate plate pagination after layout")
		.condition(func(): return rich_text_label.size.x > 0 and rich_text_label.size.y > 0)
		.task(func():
			calculate_page_breaks()
			render_page()).build()
	)

func close_plate() -> void:
	visible = false
	plate_entity = null
	caller_name = ""
	target_name = ""
	processed_text = ""
	current_page = 0
	total_pages = 1

func process_text(text: String) -> String:
	# Use Jinja2-like syntax: {{@resource}} {{$resource}} {{@measure}} {{$measure}}
	# @ = target actor values, $ = caller/self actor values
	var processed = text
	var regex = RegEx.new()
	regex.compile("\\{\\{([^}]+)\\}\\}")

	var matches = regex.search_all(processed)
	if matches == null or matches.size() == 0:
		return processed

	# Process matches in reverse order to avoid offset issues
	for i in range(matches.size() - 1, -1, -1):
		var match_ = matches[i]
		var expression = match_.get_string(1).strip_edges()
		# Use Dice engine to evaluate and inject actor values
		var dice = Dice.builder()\
			.caller(caller_name)\
			.target(target_name)\
			.expression(expression)\
			.build()
		# Get processed expression with injected values
		var result = dice.get_processed_expression()
		processed = processed.substr(0, match_.get_start()) + result + processed.substr(match_.get_end())

	return processed

func find_best_page_break(calculated_break_index: int, line_breaks: Array[int]) -> int:
	# Priority 1: Look for natural newline N lines up from calculated break
	# Estimate ~80 characters per line for lookback range calculation
	var chars_per_line = 80
	var lookback_chars = NEWLINE_LOOKBACK_LINES * chars_per_line
	var search_start = max(0, calculated_break_index - lookback_chars)

	# Search backward through actual text for newline characters
	for i in range(calculated_break_index - 1, search_start, -1):
		if i < processed_text.length() and processed_text[i] == "\n":
			Logger.trace("Page break: Found newline at index %d, calculated was %d (searched back %d chars)" % [i, calculated_break_index, calculated_break_index - i])
			return i

	# Priority 2: Look for last space before calculated break
	var space_search_start = max(0, calculated_break_index - 200)
	for i in range(calculated_break_index - 1, space_search_start, -1):
		if i < processed_text.length() and processed_text[i] == " ":
			Logger.trace("Page break: Found space at index %d, calculated was %d" % [i, calculated_break_index])
			return i

	# Priority 3: Use calculated break as-is
	Logger.trace("Page break: Using hard break at index %d" % calculated_break_index)
	return calculated_break_index

func calculate_page_breaks() -> void:
	var container_width = PAGE_SIZE.x
	var container_height = PAGE_SIZE.y

	# Calculate line breaks
	var line_breaks = char_mapper.calculate_line_breaks(processed_text, container_width)

	# Estimate lines per page (rough estimate based on font size)
	var font_size = 16  # Default
	if rich_text_label.theme:
		font_size = rich_text_label.theme.get_font_size("normal_font_size", "RichTextLabel")
	var line_height = font_size * 1.5  # Account for line spacing
	var lines_per_page = int(container_height / line_height)

	Logger.debug("Text length: %d, Line breaks: %d, Lines per page: %d" % [processed_text.length(), line_breaks.size(), lines_per_page])

	# Calculate page breaks based on line count
	page_breaks.clear()
	var current_line_count = 0
	var last_break_index = 0

	for break_index in line_breaks:
		current_line_count += 1
		if current_line_count >= lines_per_page:
			# Find the best break point using priority system
			var best_break = find_best_page_break(break_index, line_breaks)
			page_breaks.append(best_break)
			current_line_count = 0
			last_break_index = best_break

	# Add final page break if needed
	if last_break_index < processed_text.length():
		page_breaks.append(processed_text.length())

	total_pages = max(1, page_breaks.size())
	Logger.debug("Calculated %d pages for plate text, page breaks at: %s" % [total_pages, str(page_breaks)])

func render_page() -> void:
	# Get the text slice for this page
	var start_pos = 0
	if current_page > 0 and page_breaks.size() > current_page - 1:
		start_pos = page_breaks[current_page - 1] + 1

	var end_pos = processed_text.length()
	if page_breaks.size() > current_page:
		end_pos = page_breaks[current_page]

	var page_text = processed_text.substr(start_pos, end_pos - start_pos)

	# Set the text in the RichTextLabel
	rich_text_label.clear()
	rich_text_label.append_text(page_text)

	# Update pagination label
	pagination_label.set_text("%d/%d" % [current_page + 1, total_pages])

	# Update button enabled states
	if prev_button:
		prev_button.disabled = (current_page == 0)
	if next_button:
		next_button.disabled = (current_page >= total_pages - 1)

func next_page() -> void:
	if current_page < total_pages - 1:
		current_page += 1
		render_page()

func previous_page() -> void:
	if current_page > 0:
		current_page -= 1
		render_page()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Cancel action is handled by UIStateMachine via interface.gd
	# We only handle navigation here
	if event.is_action_pressed("menu_accept"):
		close_plate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		next_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		previous_page()
		get_viewport().set_input_as_handled()
