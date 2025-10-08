extends Widget

const TICK_RATE: int = 1 # Seconds
const DELIM: String = "\n"

var chat_queue: Array[Chat] = [] 

func _ready() -> void:
	$Timer.wait_time = TICK_RATE
	$Timer.timeout.connect(_process_chat)
	$VBox/LineEdit.text_submitted.connect(_on_text_submitted)

func submit_new_chat(new_text: String) -> void:
	var new_chat: Chat = Chat.builder().text(new_text).build()
	chat_queue.append(new_chat)
	var rendered_chat_entry: String = new_chat.render()
	$VBox/Text.append_text(rendered_chat_entry)
	
func clean_text(text: String) -> String:
	# TODO remove id tags
	return text.strip_edges().strip_escapes()
	
func push_text(text: String, timestamp: int) -> void:
	var line: String = "[id=%d]%s[/id]" % [timestamp, clean_text(text)]
	$VBox/Text.append_text(line)

func pop_n_chat(n: int) -> void:
	pass
	# TODO 
	# Remove the botton `n` id enclosed tags and contents from $VBox/Text.text	
	

func _on_text_submitted(new_text: String) -> void:
	submit_new_chat(new_text)
	
func _process_chat() -> void:
	var now: int = Time.get_unix_time_from_system()
	for _chat: Chat in chat_queue.filter(func(chat: Chat): return chat.get_expiry() < now):
		if chat_queue.size() > 0: chat_queue.pop_at(0)
		
