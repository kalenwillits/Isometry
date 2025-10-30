extends Node
class_name CharacterWidthMapper

## Character Width Mapper for Text Pagination
##
## PURPOSE:
## This class generates a mapping of ASCII characters to their pixel widths
## in the current font. This allows accurate pagination by calculating the
## actual rendered width of text rather than using arbitrary character counts.
##
## WHEN TO REGENERATE:
## - Font changes in the theme
## - Font size changes
## - After changing RichTextLabel theme settings
##
## HOW TO SAVE TO RES://
## 1. Run the game once to generate the mapping
## 2. The mapping is saved to user://assets/character_widths.tres
## 3. Manually copy from user:// to res://assets/ for version control
## 4. Commit the .tres file to the repository
##
## USAGE:
## var mapper = CharacterWidthMapper.new()
## mapper.initialize(rich_text_label)
## var width = mapper.get_char_width("A")
## var text_width = mapper.calculate_text_width("Hello World")

var CACHE_PATH_USER = io.get_dir() + "assets/character_widths.tres"
const CACHE_PATH_RES = "res://assets/character_widths.tres"

var char_widths: Dictionary = {}
var default_char_width: float = 10.0

## Initialize the mapper with a RichTextLabel to extract font settings
func initialize(rich_text_label: RichTextLabel) -> void:
	# Try to load from res:// first (committed version)
	if ResourceLoader.exists(CACHE_PATH_RES):
		Logger.info("Loading character width mapping from %s" % CACHE_PATH_RES, self)
		var loaded_data = ResourceLoader.load(CACHE_PATH_RES)
		if loaded_data and loaded_data is Resource:
			char_widths = loaded_data.get("data") if loaded_data.get("data") else {}
		if char_widths.size() > 0:
			Logger.info("Loaded %d character widths from cache" % char_widths.size(), self)
			return

	# Try to load from user:// (runtime generated)
	if FileAccess.file_exists(CACHE_PATH_USER):
		Logger.info("Loading character width mapping from %s" % CACHE_PATH_USER, self)
		var loaded_data = ResourceLoader.load(CACHE_PATH_USER)
		if loaded_data and loaded_data is Resource:
			char_widths = loaded_data.get("data") if loaded_data.get("data") else {}
		if char_widths.size() > 0:
			Logger.info("Loaded %d character widths from cache" % char_widths.size(), self)
			return

	# Generate new mapping if not found
	Logger.info("Generating new character width mapping...", self)
	generate_character_widths(rich_text_label)
	save_to_cache()

## Generate character width mapping by measuring each ASCII character
func generate_character_widths(rich_text_label: RichTextLabel) -> void:
	# Create a temporary Label to measure character widths
	var temp_label = Label.new()
	temp_label.theme = rich_text_label.theme

	# Get the font from the RichTextLabel's theme
	var font: Font = null
	var font_size: int = 16

	if rich_text_label.theme:
		font = rich_text_label.theme.get_font("normal_font", "RichTextLabel")
		font_size = rich_text_label.theme.get_font_size("normal_font_size", "RichTextLabel")

	if not font:
		font = temp_label.get_theme_font("font", "Label")
		font_size = temp_label.get_theme_font_size("font_size", "Label")

	Logger.debug("Using font size: %d" % font_size, self)

	# Measure ASCII printable characters (32-126)
	for ascii_code in range(32, 127):
		var char = char(ascii_code)
		var width = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		char_widths[ascii_code] = width

	# Calculate average width for default
	var total_width = 0.0
	for width in char_widths.values():
		total_width += width
	default_char_width = total_width / char_widths.size()

	temp_label.queue_free()
	Logger.info("Generated %d character widths, average: %.2f px" % [char_widths.size(), default_char_width], self)

## Save the character width mapping to cache
func save_to_cache() -> void:
	# Ensure assets directory exists
	var cache_dir = io.get_dir() + "assets"
	if not DirAccess.dir_exists_absolute(cache_dir):
		DirAccess.make_dir_absolute(cache_dir)

	# Create a Resource to store the data
	var data_resource = Resource.new()
	data_resource.set_meta("data", char_widths)

	var err = ResourceSaver.save(data_resource, CACHE_PATH_USER)
	if err == OK:
		Logger.info("Saved character width mapping to %s" % CACHE_PATH_USER, self)
		Logger.info("To commit this mapping: copy from executable directory to res://assets/", self)
	else:
		Logger.warn("Failed to save character width mapping: %d" % err, self)

## Get the pixel width of a single character
func get_char_width(character: String) -> float:
	if character.length() == 0:
		return 0.0

	var ascii_code = character.unicode_at(0)
	if char_widths.has(ascii_code):
		return char_widths[ascii_code]
	else:
		return default_char_width

## Calculate the total pixel width of a text string (excluding BBCode)
func calculate_text_width(text: String) -> float:
	var total_width: float = 0.0
	var in_bbcode = false

	for i in range(text.length()):
		var char = text[i]

		# Handle BBCode tags
		if char == "[":
			in_bbcode = true
			continue
		elif char == "]":
			in_bbcode = false
			continue

		# Skip characters inside BBCode tags
		if in_bbcode:
			continue

		# Add character width
		total_width += get_char_width(char)

	return total_width

## Calculate line breaks for given text and container width
## Returns array of line end indices
func calculate_line_breaks(text: String, container_width: float) -> Array[int]:
	var line_breaks: Array[int] = []
	var current_line_width: float = 0.0
	var last_space_index: int = -1
	var line_start: int = 0
	var in_bbcode = false

	for i in range(text.length()):
		var char = text[i]

		# Handle BBCode tags
		if char == "[":
			in_bbcode = true
			continue
		elif char == "]":
			in_bbcode = false
			continue

		# Skip characters inside BBCode tags
		if in_bbcode:
			continue

		# Handle newlines
		if char == "\n":
			line_breaks.append(i)
			current_line_width = 0.0
			last_space_index = -1
			line_start = i + 1
			continue

		# Track spaces for word wrapping
		if char == " ":
			last_space_index = i

		# Add character width
		var char_width = get_char_width(char)
		current_line_width += char_width

		# Check if we exceeded container width
		if current_line_width > container_width:
			# Try to break at last space
			if last_space_index > line_start:
				line_breaks.append(last_space_index)
				current_line_width = 0.0
				# Recalculate width from last space to current position
				for j in range(last_space_index + 1, i + 1):
					if text[j] != "[" and text[j] != "]":
						current_line_width += get_char_width(text[j])
				line_start = last_space_index + 1
				last_space_index = -1
			else:
				# No space found, hard break
				line_breaks.append(i - 1)
				current_line_width = char_width
				line_start = i

	return line_breaks
