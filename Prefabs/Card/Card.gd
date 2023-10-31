extends MarginContainer

signal pick_card(card)

var cardName = "card_a_spade"
var isCardInPickingOrPair = false

var startPosition = 0
var targetPosition = 0
var startRotation = deg_to_rad(0)
var targetRotation = 0
var DRAWTIME = 0.4 # time for the tween animation to animate for. TODO: make different timing for different states of the card
var GETFROMDECKTIME = 0.08

enum STATE {
	INDECK,
	MOVINGFROMDECKTOHAND,
	INHAND,
	INPICKING,
	INPAIR,
	MOVINGFROMHANDTODECK,
	MOVINGFROMPICKINGTOHAND,
	REORGANIZE,
	INPICKED,
	INREMOVEPICKED,
	SHUFFLE,
}
var state = STATE.INDECK

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
		STATE.INDECK:
			pass
		STATE.MOVINGFROMDECKTOHAND:
			animateFromStartToTarget(STATE.INHAND, GETFROMDECKTIME)
		STATE.INHAND:
			pass
		STATE.INPAIR:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME, false, true, true)
		STATE.MOVINGFROMHANDTODECK:
			animateFromStartToTarget(STATE.INDECK, DRAWTIME)
		STATE.INPICKING:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME, false, true, true)
		STATE.INPICKED:
			animateInPicked()
		STATE.INREMOVEPICKED:
			animateInRemovePicked()
		STATE.MOVINGFROMPICKINGTOHAND:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME, true, true, false)
		STATE.REORGANIZE:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME)
		STATE.SHUFFLE:
			pass

func animateFromStartToTarget(nextState, tweenTime, shouldRotate=true, shouldSelect=false, selected=false):
	if tween:
		tween.kill()
		
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	
	tween.tween_property($".", "position", targetPosition, tweenTime).from(startPosition)
	if shouldRotate:
		tween.tween_property($".", "rotation", targetRotation, tweenTime).from(startRotation)
	if shouldSelect:
		if selected:
			tween.tween_property($SelectedContainer, "visible", true, tweenTime-0.3).from(false)
		else:
			tween.tween_property($SelectedContainer, "visible", false, tweenTime-0.3).from(true)
	
	state = nextState

func animateInPicked():
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	
	tween.tween_property($PickedContainer, "visible", true, 0.5).from(false)
	tween.tween_property($SelectedContainer, "visible", false, 0.5).from(true)
	
	state = STATE.INHAND

func animateInRemovePicked():
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	
	tween.tween_property($PickedContainer, "visible", false, 0.5).from(true)
	tween.tween_property($SelectedContainer, "visible", true, 0.5).from(false)
	
	state = STATE.INHAND

func _on_selected_container_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1 and isCardInPickingOrPair:
		state = STATE.INPICKED
		emit_signal("pick_card", self)
