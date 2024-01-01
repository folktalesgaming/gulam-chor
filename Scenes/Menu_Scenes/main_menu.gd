extends Node2D

var save_path = ("user://setting.save")
@onready var test = $UI/Test
@onready var quit_timer = %QuitTimer
@onready var quit_message = %QuitMessage

var has_quit_timer_started = false
var has_quit_timer_expired = false

func _ready():
	get_tree().set_auto_accept_quit(false)
	# check if the settings are saved or not and show tutorial if not saved
	return
	if not FileAccess.file_exists(save_path):
		test.show()
		get_tree().create_timer(4).timeout.connect(_open_tutorial)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST || what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if has_quit_timer_started && !has_quit_timer_expired:
			get_tree().quit()
		else:
			has_quit_timer_started = true
			has_quit_timer_expired = false
			quit_timer.start()
			quit_message.show()

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

func _on_quit_timer_timeout():
	has_quit_timer_expired = true
	quit_message.hide()
