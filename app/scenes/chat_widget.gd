extends Widget

const TICK_RATE: float = 0.66 # Seconds

var chat_queue: Array[Chat] = []
var needs_render: bool = true
var ui_state_machine: Node

func _ready() -> void:
	ui_state_machine = get_node("/root/UIStateMachine")
	$Timer.wait_time = TICK_RATE
	$Timer.timeout.connect(_process_chat)
	$Timer.autostart = true
	$Timer.start()
	$VBox/LineEdit.text_submitted.connect(_on_text_submitted)
	$VBox/LineEdit.focus_entered.connect(_on_chat_focus_entered)
	$VBox/LineEdit.focus_exited.connect(_on_chat_focus_exited)
	add_to_group(Group.UI_CHAT_WIDGET)

func submit_message(new_text: String, author: String) -> void:
	var new_chat: Chat = Chat.builder().text(new_text).author(author).build()
	chat_queue.append(new_chat)
	needs_render = true
	
func pop_n_chat(n: int) -> void:
	if n > 0: 
		needs_render = true
	chat_queue = chat_queue.slice(n, chat_queue.size())

func render() -> void:
	$VBox/Text.clear()
	for chat: Chat in chat_queue:
		$VBox/Text.append_text(chat.render())
	needs_render = false

func _on_text_submitted(new_text: String) -> void:
	$VBox/LineEdit.clear()
	$VBox/LineEdit.release_focus()
	var primary_actor: Actor = Finder.get_primary_actor()
	Controller.submit_chat_request_to_server.rpc_id(1, new_text, primary_actor.display_name)
	#submit_message(new_text, primary_actor.display_name)
	# State transition happens in focus_exited

func _on_chat_focus_entered() -> void:
	ui_state_machine.transition_to(ui_state_machine.State.CHAT_ACTIVE)

func _on_chat_focus_exited() -> void:
	ui_state_machine.transition_to(ui_state_machine.State.GAMEPLAY)

func _process_chat() -> void:
	var now: int = Time.get_unix_time_from_system()
	var num_expired_chats: int = chat_queue.filter(func(chat: Chat): return chat.get_expiry() < now).size()
	pop_n_chat(num_expired_chats)
	if needs_render:
		render()

func focus_chat_input() -> void:
	"""Focus the chat input field"""
	$VBox/LineEdit.grab_focus()
