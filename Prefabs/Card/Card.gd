extends MarginContainer

var cardName = "card_a_spade"

var startPosition = 0
var targetPosition = 0
var startRotation = deg_to_rad(0)
var targetRotation = 0
var DRAWTIME = 0.4 # time for the tween animation to animate for. TODO: make different timing for different states of the card
var GETFROMDECKTIME = 0.08

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

var tween

func _ready():
	$Card.texture = load("res://Assets/UI/Cards/"+cardName+".png")
	$Card.scale *= size/$Card.texture.get_size()
	
	$CardBack.texture = load("res://Assets/UI/Cards/new_card_back.png")
	$CardBack.scale *= size/$CardBack.texture.get_size()

static func SetCardVisible():
	$CardBack.visible = false

func _physics_process(_delta):
	match state:
		INDECK:
			pass
		MOVINGFROMDECKTOHAND:
			animateFromStartToTarget(INHAND, GETFROMDECKTIME)
		INHAND:
			pass
		INPAIR:
			animateFromStartToTarget(INHAND, DRAWTIME, false, true)
		MOVINGFROMHANDTOPAIR:
			animateFromStartToTarget(INDECK, DRAWTIME)
		INPICK:
			pass
		MOVINGFROMPICKTOHAND:
			pass
		REORGANIZE:
			animateFromStartToTarget(INHAND, DRAWTIME)
		SHUFFLE:
			pass

func animateFromStartToTarget(nextState, tweenTime, shouldRotate=true, selected=false):
	if tween:
		tween.kill()
		
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	
	tween.tween_property($".", "position", targetPosition, tweenTime).from(startPosition)
	if shouldRotate:
		tween.tween_property($".", "rotation", targetRotation, tweenTime).from(startRotation)
	else:
		if selected:
			tween.tween_property($SelectedContainer, "visible", true, tweenTime-0.3).from(false)
		else:
			tween.tween_property($SelectedContainer, "visible", false, tweenTime-0.3).from(true)
	
	state = nextState
