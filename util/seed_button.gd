@tool
extends PanelContainer
class_name SeedButton

@onready var button = %Button
@export var plant_scene: PackedScene # The plant associated with this button
@export var plant_icon: CompressedTexture2D # The image icon for this button

# Information about our plant_scene
@onready var plant_name: String = "Plant":
	set(value):
		%NameLabel.text = value
		plant_name = value
var duration_seconds: float = 0
var unlocked: bool = false:
	set(value):
		%LockIcon.visible = !value
		unlocked = value

var do_set_position = false
@onready var start_position = global_position

func _ready():
	if plant_icon:
		button.icon = plant_icon
	if Engine.is_editor_hint():
		return
	if plant_scene:
		var plant = plant_scene.instantiate()
		duration_seconds = plant.get_study_duration()
		%DurationLabel.text = plant.get_readable_study_duration()
		plant_name = plant.get_plant_name()
		unlocked = plant.get_unlocked() # Handle exported unlocked plants
	EventBus.load_game.connect(_on_load_game)

func _on_load_game():
	if unlocked: # We already exported as unlocked; save that!
		GameManager.add_unlocked_plant(plant_name)
	if GameManager.is_plant_unlocked(plant_name): # Handle progressively unlocked plants
		unlocked = true

func _physics_process(_delta: float) -> void:
	if do_set_position:
		var pos_offset = button.size/2.0
		global_position = get_global_mouse_position() - pos_offset

func _on_button_button_down() -> void:
	if unlocked:
		%NameLabel.hide()
		%DurationLabel.hide()
		do_set_position = true
		start_position = global_position
	EventBus.seed_button_pressed.emit(self)

func _on_button_button_up() -> void:
	%NameLabel.show()
	%DurationLabel.show()
	if unlocked:
		global_position = start_position
		do_set_position = false
		make_transparent(false)
	EventBus.seed_button_released.emit(self)

func make_transparent(do_transparent: bool):
	button.self_modulate.a = 0.25 if do_transparent else 1.0
