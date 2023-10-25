extends MarginContainer

var cardName = "card_a_spade"
var startPosition = 0
var targetPosition = 0
var startRotation = 0
var targetRotation = 0
var DRAWTIME = 1

enum {
	INDECK,
	MOVINGFROMDECKTOHAND,
	INHAND,
	INPAIR,
	MOVINGFROMHANDTOPAIR,
	INPICK,
	MOVINGFROMPICKTOHAND,
	REORGANIZE,
	SHUFFLE,
}
var state = INDECK

func _ready():
	$Card.texture = load("res://Assets/UI/Cards/"+cardName+".png")
	$Card.scale *= size/$Card.texture.get_size()
	
	$CardBack.texture = load("res://Assets/UI/Cards/new_card_back.png")
	$CardBack.scale *= size/$CardBack.texture.get_size()

static func SetIsMyCard():
	$CardBack.visible = false

func _physics_process(delta):
	match state:
		INDECK:
			pass
		MOVINGFROMDECKTOHAND:
			animateFromStartToTarget()
		INHAND:
			pass
		INPAIR:
			pass
		MOVINGFROMHANDTOPAIR:
			animateFromStartToTarget()
		INPICK:
			pass
		MOVINGFROMPICKTOHAND:
			pass
		REORGANIZE:
			animateFromStartToTarget()
		SHUFFLE:
			pass

func animateFromStartToTarget():
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property($".", "position", targetPosition, DRAWTIME).from(startPosition).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($".", "rotation", targetRotation, DRAWTIME-0.5).from(startRotation).set_trans(Tween.TRANS_CUBIC)
	
	state = INHAND
