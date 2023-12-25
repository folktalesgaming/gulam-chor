extends StaticBody2D

signal pick_card(card)

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

func _physics_process(_delta):
	if is_draggable:
		initialPosition = global_position
		if Input.is_action_just_pressed("click"):
			offset = get_global_mouse_position() - global_position
		if Input.is_action_pressed("click"):
			global_position = get_global_mouse_position() - offset
		if is_inside_dropable:
			is_draggable = false
			targetPosition = drop_zone_ref.position
			print(drop_zone_ref.position)
			if dragging_zone == "pile":
				print("Moving to deck")
				state = STATE.MOVINGFROMHANDTODECK
			else:
				print("Moving back to hand")
				state = STATE.MOVINGFROMPICKINGTOHAND
		else:
			targetPosition = initialPosition
			state = STATE.MOVINGFROMPICKINGTOHAND
		#elif Input.is_action_just_released("click"):
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
			animateFromStartToTarget(STATE.INDECK, DRAWTIME, true, true, false)
		STATE.INTOBEPICKED:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME, false, true, true)
		STATE.MOVINGFROMPICKINGTOHAND:
			animateFromStartToTarget(STATE.INHAND, DRAWTIME, true, true, false)
		STATE.REORGANIZE:
			animateFromStartToTarget(STATE.INHAND, ShuffleTime)
		STATE.SHUFFLE:
			animateFromStartToTarget(STATE.INHAND, ShuffleTime, true)

func animateFromStartToTarget(nextState, tweenTime, shouldRotate=true, shouldSelect=false, selected=false):
	if tween:
		tween.kill()
		
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	
	tween.tween_property($".", "position", targetPosition, tweenTime).from(self.position)
	if shouldRotate:
		tween.tween_property($".", "rotation", targetRotation, tweenTime).from(self.rotation)
	#if shouldSelect:
		#if selected:
			#tween.tween_property($SelectedContainer, "visible", true, tweenTime-0.3).from(false)
		#else:
			#tween.tween_property($SelectedContainer, "visible", false, tweenTime-0.3).from(true)
	
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
		state = STATE.MOVINGFROMPICKINGTOHAND
		emit_signal("pick_card", self)

func _on_drag_area_mouse_entered():
	if isCardInPickingOrPair:
		is_draggable = true
		scale = Vector2(1.2, 1.2)

func _on_drag_area_mouse_exited():
	scale = Vector2(1, 1)

func _on_drag_area_body_entered(body):
	if body.is_in_group("dragzone"):
		if body.dragging_zone == dragging_zone:
			is_inside_dropable = true
			drop_zone_ref = body

func _on_drag_area_body_exited(body):
	if body.is_in_group("dragzone"):
		is_inside_dropable = false
