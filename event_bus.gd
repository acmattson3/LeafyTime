extends Node
# EventBus
# Handles all game-related signals

var exploring: bool = false # Are we currently exploring an environment?

signal load_game() # Instruct everyone to load data from GameManager
signal seed_button_pressed(seed_button)
signal seed_button_released(seed_button)
signal enter_explore_mode()
signal exit_explore_mode()
signal unlock_plant(plant_name)

# Study signals
signal start_study_session(plant: BasePlant)
signal start_break()
signal resume_study_session()
# if completed, user studied without distraction/breaking too long.
# if not completed, user got distracted/breaked too long.
signal stop_study_session(completed: bool)
signal resume_study_after_exit(plant_name)
