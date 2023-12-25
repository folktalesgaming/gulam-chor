extends StaticBody2D

@export var dragging_zone = "pile"

func _on_area_2d_body_entered(body):
	print("dragging_zone = %s"%body.dragging_zone)
	if body.dragging_zone == dragging_zone:
		print("can drop")
