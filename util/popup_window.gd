extends PanelContainer


enum MessageType { INFO, WARNING, ERROR }
var _message_type: MessageType = MessageType.INFO:
	set(value):
		match value:
			MessageType.INFO:
				%MessageTypeLabel.text = "[center][b][color=#ADD8E6]Information[/color][/b][/center]"
			MessageType.WARNING:
				%MessageTypeLabel.text = "[center][b][color=orange]Warning![/color][/b][/center]"
			MessageType.ERROR:
				%MessageTypeLabel.text = "[center][b][color=red]Error![/color][/b][/center]"
var _message: String = "":
	set(value):
		%MessageLabel.text = value
		_message = value

func _ready():
	EventBus.show_error.connect(_on_show_error)
	EventBus.show_warning.connect(_on_show_warning)
	EventBus.show_info.connect(_on_show_info)

func _on_show_error(message):
	show_message(message, MessageType.ERROR)

func _on_show_warning(message):
	show_message(message, MessageType.WARNING)

func _on_show_info(message):
	show_message(message, MessageType.INFO)

func show_message(message: String, type: MessageType = MessageType.INFO):
	_message = message
	_message_type = type
	show()

func _on_okay_button_pressed() -> void:
	hide()
