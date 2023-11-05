extends Node2D

func _on_yes_button_pressed():
	$ButtonClick.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _on_no_button_pressed():
	$ButtonClick.play()
	$UI/PanelContainer.hide()

func _on_settings_button_pressed():
	$ButtonClick.play()
