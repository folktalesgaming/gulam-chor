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

var rng = RandomNumberGenerator.new()

# TODO: make it proper player prefabs and player models to represent them
var player = [];
var playerRight = [];
var playerLeft = [];
var playerTop = [];
var removedPairCards = [];

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

func _ready():
	# TODO: add animations to divide the cards into players
	for card in deckOfCards:
		var new_card = CardBase.instantiate()
		new_card.cardName = card
		new_card.startPosition = $PackOfDeck.position
		new_card.startRotation = 0
		
		if playerIndex == 0:
			# TODO: Make it more dynamic for later when removing pairs and adding cards to hand 
			OvalAngleVector = Vector2(-Horizontal_radius * cos(angle), -Vertical_radius * sin(angle))
			new_card.targetPosition = CenterCardOval - OvalAngleVector
			new_card.targetRotation = deg_to_rad(angle)/2
			new_card.SetIsMyCard()
			$PlayerCards.add_child(new_card)
			player.append(card)
			angle += PlayerHandCardAngleOffset
		if playerIndex == 1:
			new_card.targetPosition = ViewportSize * Vector2(0.95, 1 - posOffsetYRight)
			new_card.targetRotation = deg_to_rad(90)
			$SecondPlayer.add_child(new_card)
			playerRight.append(card)
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerIndex == 2:
			new_card.targetPosition = ViewportSize * Vector2(0.75 - posOffsetX, -0.1)
			$ThirdPlayer.add_child(new_card)
			playerTop.append(card)
			posOffsetX += TopPlayerCardPositionOffset
		if playerIndex == 3:
			new_card.targetPosition = ViewportSize * Vector2(-0.08, 1 - posOffsetYLeft)
			new_card.targetRotation = deg_to_rad(90)
			playerLeft.append(card)
			$FourthPlayer.add_child(new_card)
			posOffsetYLeft += LeftPlayerCardPositionOffset
			
		new_card.state = MOVINGFROMDECKTOHAND
		
		playerIndex = (1+playerIndex)%4
		
	$PackOfDeck.visible = false

	# TODO: add animations for removing pairs of cards into the center pile
	player = Utility.removePairs(player)
	removeCardsFromScreen($PlayerCards, player)
	
	playerRight = Utility.removePairs(playerRight)
	removeCardsFromScreen($SecondPlayer, playerRight)
	
	playerTop = Utility.removePairs(playerTop)
	removeCardsFromScreen($ThirdPlayer, playerTop)
	
	playerLeft = Utility.removePairs(playerLeft)
	removeCardsFromScreen($FourthPlayer, playerLeft)

# TODO: adjust the position of remaining cards in hands for each players after removing pairs
func removeCardsFromScreen(node, toCheckCardList):
	for card in node.get_children():
		if not toCheckCardList.has(card.cardName):
			card.startPosition = card.position
			card.targetPosition = Vector2($PairCards.position.x + rng.randf_range(-2.0, 2.0), $PairCards.position.y + rng.randf_range(-1.0, 1.0))
			card.startRotation = card.rotation
			card.targetRotation = deg_to_rad(rng.randf_range(-130.0, 130.0))
			card.SetIsMyCard()
			card.state = MOVINGFROMHANDTOPAIR
			removedPairCards.append(card)
			card.free()
