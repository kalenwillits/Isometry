extends Node2D

const MAX_WIDTH: int = 256
const TTL: int = 25 # Seconds

@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = TTL
	timer.start()
	recalculate_size()

func set_text(text: String) -> void:
	rich_text_label.text = text
	recalculate_size()

func recalculate_size() -> void:
	# Create temporary label to measure text
	var temp_label = RichTextLabel.new()
	temp_label.theme = rich_text_label.theme
	temp_label.bbcode_enabled = rich_text_label.bbcode_enabled
	temp_label.text = rich_text_label.text
	temp_label.fit_content = true
	temp_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# Add to tree temporarily to get accurate measurements
	add_child(temp_label)
	await get_tree().process_frame

	# Measure the content width
	var content_width = temp_label.get_content_width()
	temp_label.queue_free()

	# Clamp width and apply
	var final_width = min(content_width, MAX_WIDTH)
	rich_text_label.custom_minimum_size.x = final_width

	# Set autowrap for actual label
	if content_width > MAX_WIDTH:
		rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		rich_text_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# Calculate height after wrapping
	await get_tree().process_frame
	var content_height = rich_text_label.get_content_height()
	rich_text_label.custom_minimum_size.y = content_height


func _on_timer_timeout() -> void:
	queue_free()
