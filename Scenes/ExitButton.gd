extends TextureButton

# TODO: add click sound effects in all buttons
func _on_pressed():
	$"../../ExitPopupPanel".show()
