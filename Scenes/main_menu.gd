extends Node2D

@onready var button_click = %ButtonClick
@onready var panel_container = %PanelContainer

func _on_yes_button_pressed():
	button_click.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _on_no_button_pressed():
	button_click.play()
	panel_container.hide()

func _on_settings_button_pressed():
	button_click.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scenes/Settings.tscn")

func _on_single_mode_pressed():
	button_click.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Scenes/Game_play.tscn")

func _on_exit_button_pressed():
	button_click.play()
	panel_container.show()

func _on_multiplayer_mode_pressed():
	button_click.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scenes/Multiplayer_setup.tscn")
