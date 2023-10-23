extends Node2D

const CardBase = preload("res://Prefabs/Card/Card.tscn")
const Utility = preload("res://Utils/utility.gd")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")

@onready var deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
@onready var ViewportSize = ProjectSettings.get_setting("display/window/size/viewport_width")
#Vector2(get_viewport().size.x, get_viewport().size.y)
@onready var CenterCardOval = ViewportSize * Vector2(0.45, 1.55)
@onready var Horizontal_radius = ViewportSize * 0.45
@onready var Vertical_radius = ViewportSize * 0.3
var angle = deg_to_rad(-130)
var OvalAngleVector = Vector2()
var playerIndex = 0
var posOffsetYRight = 0
var posOffsetYLeft = 0
var posOffsetX = 0

const PlayerHandCardAngleOffset = 0.12
const RightPlayerCardPositionOffset = 0.07
const TopPlayerCardPositionOffset = 0.05
const LeftPlayerCardPositionOffset = 0.07

func _ready():
	for card in deckOfCards:
		var new_card = CardBase.instantiate()
		new_card.cardName = card
		
		if playerIndex == 0:
			# TODO: Make it more dynamic for later when removing pairs and adding cards to hand 
			OvalAngleVector = Vector2(-Horizontal_radius * cos(angle), -Vertical_radius * sin(angle))
			new_card.position = CenterCardOval - OvalAngleVector
			new_card.rotation = deg_to_rad(angle)/2
			new_card.SetIsMyCard()
			$PlayerCards.add_child(new_card)
			angle += PlayerHandCardAngleOffset
		if playerIndex == 1:
			new_card.position = ViewportSize * Vector2(0.95, 1 - posOffsetYRight)
			new_card.rotation = deg_to_rad(90)
			$SecondPlayer.add_child(new_card)
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerIndex == 2:
			new_card.position = ViewportSize * Vector2(0.75 - posOffsetX, -0.1)
			$ThirdPlayer.add_child(new_card)
			posOffsetX += TopPlayerCardPositionOffset
		if playerIndex == 3:
			new_card.position = ViewportSize * Vector2(-0.08, 1 - posOffsetYLeft)
			new_card.rotation = deg_to_rad(90)
			$FourthPlayer.add_child(new_card)
			posOffsetYLeft += LeftPlayerCardPositionOffset
		
		playerIndex = (1+playerIndex)%4
