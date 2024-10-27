extends Node
# EventBus
# Handles all game-related signals

var exploring: bool = false # Are we currently exploring an environment?

signal load_game() # Instruct everyone to load data from GameManager
signal seed_button_pressed(seed_button)
signal seed_button_released(seed_button)
signal start_study_session()
signal study_session_completed()
signal enter_explore_mode()
signal exit_explore_mode()
