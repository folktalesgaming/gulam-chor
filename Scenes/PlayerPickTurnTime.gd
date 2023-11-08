extends Timer

func _process(_delta):
	%PlayerPickTurnProgressBar.value = lerp(100, 0, 1 - time_left / wait_time)
