extends PanelContainer

@onready var seed_button_parent = %FlowContainer
@onready var seed_buttons = seed_button_parent.get_children()
enum SORT_TYPE {
	NAME_ASCENDING, 
	NAME_DESCENDING, 
	DURATION_ASCENDING,
	DURATION_DESCENDING,
	UNLOCKED_ASCENDING,
	UNLOCKED_DESCENDING
}

func _ready():
	sort_seed_buttons()
	EventBus.unlock_plant.connect(_on_unlock_plant)

func _on_unlock_plant(plant_name):
	for seed_button in seed_buttons:
		if seed_button.plant_name == plant_name:
			seed_button.unlocked = true

func sort_seed_buttons(sort_type: SORT_TYPE = SORT_TYPE.NAME_ASCENDING):
	var sorted_buttons := seed_button_parent.get_children()
	
	var sort_func = null
	match sort_type:
		SORT_TYPE.NAME_ASCENDING:
			sort_func = func(a: SeedButton, b: SeedButton): return a.plant_name.naturalnocasecmp_to(b.plant_name) < 0
		SORT_TYPE.NAME_DESCENDING:
			sort_func = func(a: SeedButton, b: SeedButton): return a.plant_name.naturalnocasecmp_to(b.plant_name) > 0
		SORT_TYPE.DURATION_ASCENDING:
			sort_func = func(a: SeedButton, b: SeedButton): return a.duration_seconds < b.duration_seconds
		SORT_TYPE.DURATION_DESCENDING:
			sort_func = func(a: SeedButton, b: SeedButton): return a.duration_seconds > b.duration_seconds
		SORT_TYPE.UNLOCKED_ASCENDING:
			sort_func = func(a: SeedButton, b: SeedButton): return int(b.unlocked) - int(a.unlocked) < 0
		SORT_TYPE.UNLOCKED_DESCENDING:
			sort_func = func(a: SeedButton, b: SeedButton): return int(a.unlocked) - int(b.unlocked) <= 0
		_:
			print("Unimplemented sort type requested; unable to sort.")
			return
	
	sorted_buttons.sort_custom(sort_func)
	
	for node in seed_buttons:
		seed_button_parent.remove_child(node)
	for node in sorted_buttons:
		seed_button_parent.add_child(node)
	
	seed_buttons = seed_button_parent.get_children()

func _on_option_button_item_selected(index: int) -> void:
	sort_seed_buttons(index)
