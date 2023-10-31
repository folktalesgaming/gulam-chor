extends TextureButton

func _on_pressed():
	$"../../ButtonClick".play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Scenes/Game_play.tscn")
