extends MarginContainer

var cardName = "card_a_spade";

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	$Card.texture = load("res://Assets/UI/Cards/"+cardName+".png")
	$Card.scale *= size/$Card.texture.get_size()
