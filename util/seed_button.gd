@tool
extends PanelContainer
class_name SeedButton

@onready var button = $Button
@export var plant_scene: PackedScene
@export var plant_icon: CompressedTexture2D

var set_position = false
@onready var start_position = global_position

func _ready():
	if plant_icon:
		button.icon = plant_icon

func _physics_process(delta: float) -> void:
	if set_position:
		global_position = get_global_mouse_position() - button.size/2.0

func _on_button_button_down() -> void:
	set_position = true
	start_position = global_position
	EventBus.seed_button_pressed.emit(self)

func _on_button_button_up() -> void:
	global_position = start_position
	set_position = false
	make_transparent(false)
	EventBus.seed_button_released.emit(self)

func make_transparent(do_transparent: bool):
	button.self_modulate.a = 0.25 if do_transparent else 1.0
