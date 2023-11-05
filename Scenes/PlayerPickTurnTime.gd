extends Timer

func _process(delta):
	$"../UI/Control/PlayerPickTurnProgressBar".value = lerp(100, 0, 1 - time_left / wait_time)
