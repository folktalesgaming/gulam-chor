extends Node2D

var save_path = ("user://setting.save")
@onready var test = $UI/Test

func _ready():
	# check if the settings are saved or not and show tutorial if not saved
	return
	if not FileAccess.file_exists(save_path):
		test.show()
		get_tree().create_timer(4).timeout.connect(_open_tutorial)

# Open the tutorial Scene
func _open_tutorial():
	test.hide()
	get_tree().change_scene_to_file("res://Scenes/Tutorial_Scenes/Tutorial.tscn")

# Start the single player mode game play
func _on_single_mode_pressed():
	AudioManager._play_button_sfx()
	get_tree().change_scene_to_file("res://Scenes/Game_Scenes/Game_play.tscn")

# Start the multiplayer mode game play
func _on_multiplayer_mode_pressed():
	AudioManager._play_button_sfx()
	get_tree().change_scene_to_file("res://Scenes/Game_Scenes/Multiplayer_setup.tscn")

# Go to the settings scene
func _on_settings_pressed():
	AudioManager._play_button_sfx()
	get_tree().change_scene_to_file("res://Scenes/Menu_Scenes/Settings.tscn")
