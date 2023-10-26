extends Node2D

const CardBase = preload("res://Prefabs/Card/Card.tscn")
const Utility = preload("res://Utils/utility.gd")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")

@onready var deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
@onready var PairCardsPosition = $PairCards.position

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
		new_card.startRotation = deg_to_rad(30)
		
		if playerIndex == 0:
			# TODO: Make it more dynamic for later when removing pairs and adding cards to hand 
			OvalAngleVector = Vector2(-Horizontal_radius * cos(angle), -Vertical_radius * sin(angle))
			new_card.targetPosition = CenterCardOval - OvalAngleVector - $PlayerCards.position
			new_card.targetRotation = deg_to_rad(angle)/2
			new_card.SetIsMyCard()
			$PlayerCards.add_child(new_card)
			player.append(card)
			angle += PlayerHandCardAngleOffset
		if playerIndex == 1:
			new_card.targetPosition = ViewportSize * Vector2(0.95, 1 - posOffsetYRight) - $SecondPlayer.position
			new_card.targetRotation = deg_to_rad(90)
			$SecondPlayer.add_child(new_card)
			playerRight.append(card)
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerIndex == 2:
			new_card.targetPosition = ViewportSize * Vector2(0.75 - posOffsetX, -0.1) - $ThirdPlayer.position
			$ThirdPlayer.add_child(new_card)
			playerTop.append(card)
			posOffsetX += TopPlayerCardPositionOffset
		if playerIndex == 3:
			new_card.targetPosition = ViewportSize * Vector2(-0.08, 1 - posOffsetYLeft) - $FourthPlayer.position
			new_card.targetRotation = deg_to_rad(90)
			playerLeft.append(card)
			$FourthPlayer.add_child(new_card)
			posOffsetYLeft += LeftPlayerCardPositionOffset
			
		new_card.state = MOVINGFROMDECKTOHAND
		
		playerIndex = (1+playerIndex)%4
		
		await get_tree().create_timer(0.08).timeout
		
	$PackOfDeck.visible = false
	
	$RemovePairBotTimer.start() # starting the timer for the bots to remove their pairs

func _on_remove_pair_bot_timer_timeout():
	playerRight = Utility.removePairs(playerRight)
	removeCardsFromScreen($SecondPlayer, playerRight)
	
	playerTop = Utility.removePairs(playerTop)
	removeCardsFromScreen($ThirdPlayer, playerTop)
	
	playerLeft = Utility.removePairs(playerLeft)
	removeCardsFromScreen($FourthPlayer, playerLeft)
	
	$RemovePairPlayerTimer.start() # starting the timer for the pairs in player hand to pop up

# TODO: adjust the position of remaining cards in hands for each players after removing pairs
func removeCardsFromScreen(node, toCheckCardList):
	for card in node.get_children():
		if not toCheckCardList.has(card.cardName):
			var new_removed_card = CardBase.instantiate()
			new_removed_card.cardName = card.cardName
			new_removed_card.startPosition = Vector2(PairCardsPosition.x - card.position.x, PairCardsPosition.y - card.position.y)
			new_removed_card.targetPosition = Vector2(rng.randf_range(-2.0, 10.0), rng.randf_range(-2.0, 10.0))
			new_removed_card.startRotation = card.rotation
			new_removed_card.targetRotation = deg_to_rad(card.rotation + rng.randf_range(-30.0, 60.0))
			new_removed_card.SetIsMyCard()
			$PairCards.add_child(new_removed_card)
			new_removed_card.state = MOVINGFROMHANDTOPAIR
			card.free()


func _on_remove_pair_player_timer_timeout():
	# TODO: add animations for removing pairs of cards into the center pile
	# player = Utility.removePairs(player)
	# removeCardsFromScreen($PlayerCards, player)
	popUpPlayerPairs()

func popUpPlayerPairs():
	var toRemovePairs = Utility.removePairs(player)
	for card in $PlayerCards.get_children():
		if not toRemovePairs.has(card.cardName):
			card.startPosition = card.position
			card.targetPosition = Vector2(card.position.x, card.position.y - 60)
			card.state = INPAIR
