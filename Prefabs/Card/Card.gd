extends MarginContainer

var cardName = "card_a_spade"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	$Card.texture = load("res://Assets/UI/Cards/"+cardName+".png")
	$Card.scale *= size/$Card.texture.get_size()
	
	$CardBack.texture = load("res://Assets/UI/Cards/new_card_back.png")
	$CardBack.scale *= size/$CardBack.texture.get_size()

static func SetIsMyCard():
	$CardBack.visible = false
