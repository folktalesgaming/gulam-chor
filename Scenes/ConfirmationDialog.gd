extends ConfirmationDialog

# TODO: make it custom confirmation dialog
func _on_canceled():
	$"..".hide()

func _on_confirmed():
	$"..".hide()
	get_tree().quit()
