@tool
extends PanelContainer
class_name SeedButton

@onready var button = %Button
@export var plant_scene: PackedScene # The plant associated with this button
@export var plant_icon: CompressedTexture2D # The image icon for this button

var set_position = false
@onready var start_position = global_position

func _ready():
	if plant_icon:
		button.icon = plant_icon
	if plant_scene and not Engine.is_editor_hint():
		var plant = plant_scene.instantiate()
		var duration_text = plant.get_readable_study_duration()
		%DurationLabel.text = duration_text
		%NameLabel.text = plant.get_plant_name()
		

func _physics_process(delta: float) -> void:
	if set_position:
		var pos_offset = button.size/2.0
		global_position = get_global_mouse_position() - pos_offset

func _on_button_button_down() -> void:
	%NameLabel.hide()
	%DurationLabel.hide()
	set_position = true
	start_position = global_position
	EventBus.seed_button_pressed.emit(self)

func _on_button_button_up() -> void:
	%NameLabel.show()
	%DurationLabel.show()
	global_position = start_position
	set_position = false
	make_transparent(false)
	EventBus.seed_button_released.emit(self)

func make_transparent(do_transparent: bool):
	button.self_modulate.a = 0.25 if do_transparent else 1.0
