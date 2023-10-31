extends Timer

func _process(delta):
	$"../UI/Control/PlayerPickTurnTimer".value = lerp(100, 0, 1 - time_left / wait_time)
