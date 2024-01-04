extends StaticBody2D

signal pick_card(card)
signal select_card(card)
signal cancel_select()

@onready var card = %Card
@onready var card_back = %CardBack

var cardName = "card_a_spade"
var isCardInPickingOrPair = false

var is_draggable = false
var is_inside_dropable = false
var drop_zone_ref
var offset: Vector2
var initialPosition

var dragging_zone = "pile"

var targetPosition: Vector2 = Vector2.ZERO
var targetRotation = 0
var DRAWTIME = 0.4 # time for the tween animation to animate for. TODO: make different timing for different states of the card
var ShuffleTime = 0.2
var GETFROMDECKTIME = 0.08

enum STATE {
	INDECK,
	MOVINGFROMDECKTOHAND,
	INHAND,
	INTOBEPICKED,
	INPICKING,
	MOVINGFROMPICKINGTOHAND,
	INPAIR,
	MOVINGFROMHANDTODECK,
	REORGANIZE,
	SHUFFLE,
}
var state = STATE.INDECK

var tween

func _ready():
	card.texture = load("res://Assets/UI/Cards/"+cardName+".png")
	#card.scale *= card_container.size/card.texture.get_size()
	
	card_back.texture = load("res://Assets/UI/Cards/new_card_back.png")
	#card_back.scale *= card_container.size/card_back.texture.get_size()

func SetCardVisible():
	card_back.visible = false

func SetCardNotVisible():
	card_back.visible = true

func _physics_process(delta):
	if is_draggable:
		if Input.is_action_just_pressed("click"):
			initialPosition = self.position
			emit_signal("select_card", self)
		if Input.is_action_pressed("click"):
			if !Drag.pickedCard:
				Drag._change_picked_card(self)
			global_position = lerp(global_position, get_global_mouse_position(), 65 * delta)
		if Input.is_action_just_released("click"):
			_check_drop()
		_check_inentered_drop_zone()
	match state:
		STATE.INDECK:
			pass
		STATE.MOVINGFROMDECKTOHAND:
			animateFromStartToTarget(STATE.INHAND, GETFROMDECKTIME)
		STATE.INHAND:
			pass
		STATE.INPAIR:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME, false)
		STATE.INPICKING:
			pass
		STATE.MOVINGFROMHANDTODECK:
			animateFromStartToTarget(STATE.INDECK, DRAWTIME)
		STATE.INTOBEPICKED:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME)
		STATE.MOVINGFROMPICKINGTOHAND:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME)
		STATE.REORGANIZE:
			animateFromStartToTarget(STATE.INHAND, ShuffleTime)
		STATE.SHUFFLE:
			animateFromStartToTarget(STATE.INHAND, ShuffleTime, true)

func animateFromStartToTarget(nextState, tweenTime, shouldRotate=true):
	if tween:
		tween.kill()
		
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	
	tween.tween_property($".", "position", targetPosition, tweenTime).from(self.position)
	if shouldRotate:
		tween.tween_property($".", "rotation", targetRotation, tweenTime).from(self.rotation)
	
	state = nextState

func _check_drop():
	scale = Vector2(1, 1)
	if is_inside_dropable && dragging_zone == drop_zone_ref.dragging_zone:
		is_draggable = false
		scale = Vector2(1, 1)
		emit_signal("pick_card", self)
	else:
		targetPosition = initialPosition
		state = STATE.MOVINGFROMHANDTODECK
		emit_signal("cancel_select")

func _check_inentered_drop_zone():
	if is_inside_dropable && dragging_zone == drop_zone_ref.dragging_zone:
		is_draggable = false
		scale = Vector2(1, 1)
		emit_signal("pick_card", self)

func _on_drag_area_mouse_entered():
	if isCardInPickingOrPair && !Drag.pickedCard:
		initialPosition = self.position
		is_draggable = true
		scale = Vector2(1.2, 1.2)
		emit_signal("select_card", self)

func _on_drag_area_body_entered(body):
	if body.is_in_group("dragzone") && body.dragging_zone == dragging_zone:
		is_inside_dropable = true
		drop_zone_ref = body

func _on_drag_area_body_exited(_body):
	is_inside_dropable = false

func _play_glow_animation():
	$GlowAnimationPlayer.play("glow")
	
func _stop_glow_animation():
	$GlowAnimationPlayer.stop()
