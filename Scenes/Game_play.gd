extends Node2D

const CardBase = preload("res://Prefabs/Card/Card.tscn")
const Utility = preload("res://Utils/utility.gd")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")

@onready var deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
@onready var PairCardsPosition = $PairCards.position

@onready var ViewportSize = ProjectSettings.get_setting("display/window/size/viewport_width") # Size of viewport
@onready var CenterCardOval = ViewportSize * Vector2(0.45, 1.55) # Calculating the center of oval for player card arc
@onready var Horizontal_radius = ViewportSize * 0.45 # Horizontal radius of the oval arc
@onready var Vertical_radius = ViewportSize * 0.3 # Vertical radius of the oval arc
var angle = deg_to_rad(-130) # Angle at which the card must be positioned
var OvalAngleVector = Vector2() # Vector to convert the polar points (r, 0) to cartesian points (x,y)

var playerTurn = 0 # To determine the turn of player
var playerToPickFrom = 1
@onready var playerToPickFromNode = $Player2

var cardSpread = 0.25

var posOffsetYRight = 0 # Position of cards of player to the right
var posOffsetYLeft = 0 # Position of cards of player to the left
var posOffsetX = 0 # Position of cards of player to the top

var isGameMoving = false # Determine the game is on automatic mode or waiting for player inputs

# Offset of cards angle and position of each players
const PlayerHandCardAngleOffset = 0.12
const RightPlayerCardPositionOffset = 0.07
const TopPlayerCardPositionOffset = 0.05
const LeftPlayerCardPositionOffset = 0.07

# random number generator
var rng = RandomNumberGenerator.new()

# State of each card
enum STATE {
	INDECK,
	MOVINGFROMDECKTOHAND,
	INHAND,
	INPICKING,
	INPAIR,
	MOVINGFROMHANDTODECK,
	MOVINGFROMPICKINGTOHAND,
	REORGANIZE,
	SHUFFLE,
}

func _ready():
	var packOfDeckPosition = $PackOfDeck.position
	var startRotation = deg_to_rad(30)
	
	for card in deckOfCards:
		if playerTurn == 0:
			# TODO: Make it more dynamic for later when removing pairs and adding cards to hand 
			addCardToPile(card, $Player, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 0, true)
			angle += PlayerHandCardAngleOffset
		if playerTurn == 1:
			addCardToPile(card, $Player2, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 1)
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerTurn == 2:
			addCardToPile(card, $Player3, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 2)
			posOffsetX += TopPlayerCardPositionOffset
		if playerTurn == 3:
			addCardToPile(card, $Player4, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 3)
			posOffsetYLeft += LeftPlayerCardPositionOffset
		
		playerTurn = (1+playerTurn)%4
		
		await get_tree().create_timer(0.08).timeout
		
	$PackOfDeck.visible = false
	playerTurn = 0
	
	$RemovePairBotTimer.start() # starting the timer for the bots to remove their pairs

func _physics_process(_delta):
	if $PairCards.get_child_count() >= 50:
		isGameMoving = false #TODO: create a game finish screen and mechanism to know who lost
	if isGameMoving:
		playerToPickFrom = getNextPlayerToPickFromIndex(playerTurn)
		match playerToPickFrom:
			0:
				playerToPickFromNode = $Player
			1:
				playerToPickFromNode = $Player2
			2:
				playerToPickFromNode = $Player3
			3:
				playerToPickFromNode = $Player4
		match playerTurn:
			0:
				turn(playerToPickFromNode, playerToPickFrom, $Player, 0)
			1:
				turn(playerToPickFromNode, playerToPickFrom, $Player2, 1)
			2:
				turn(playerToPickFromNode, playerToPickFrom, $Player3, 2)
			3:
				turn(playerToPickFromNode, playerToPickFrom, $Player4, 3)

func _on_remove_pair_bot_timer_timeout():
	removeCards($Player2)
	removeCards($Player3)
	removeCards($Player4)
	
	# starting the timer for the pairs in player hand to pop up
	$RemovePairPlayerTimer.start() 

func _on_remove_pair_player_timer_timeout():
	var cardsSplit = Utility.findPairs($Player.cardsInHand)
	pairUnPairCards($Player, 0, STATE.INPAIR, false, cardsSplit.pairCards)
	
	# rearrange BOT cards
	rearrangeCards($Player2, 1)
	rearrangeCards($Player3, 2)
	rearrangeCards($Player4, 3)
	
	# await 0.5 sec
	await get_tree().create_timer(0.5).timeout
	
	# remove the pair cards from player hand
	removeCards($Player)
	rearrangeCards($Player, 0)
	
	# await 0.5 sec
	await get_tree().create_timer(0.5).timeout
	
	# start the game in auto mode
	isGameMoving = true

func turn(nextPlayer, nextPlayerIndex, currentPlayer, currentPlayerIndex):
	pairUnPairCards(nextPlayer, nextPlayerIndex, STATE.INPICKING)
	isGameMoving = false
	await get_tree().create_timer(2).timeout # later make it wait till the player choose one
	
	# picking card from next player
	var pickedCard = Utility.pickRandomCard(nextPlayer.get_children())
	var sPos = pickedCard.position
	var sRot = pickedCard.rotation
	var shouldShowCard = false
	if currentPlayerIndex == 0:
		shouldShowCard = true
	addCardToPile(pickedCard.cardName, currentPlayer, STATE.MOVINGFROMPICKINGTOHAND, sPos, sRot, currentPlayerIndex, shouldShowCard)
	removeCardsFromPile(nextPlayer, [pickedCard.cardName])
	pairUnPairCards(nextPlayer, nextPlayerIndex, STATE.MOVINGFROMPICKINGTOHAND, true, [], true)
	
	# checking if there is pair after pickup and throwing the pair cards
	await get_tree().create_timer(0.7).timeout
	var cardsSplitted = Utility.findPairs(currentPlayer.cardsInHand)
	if(cardsSplitted.pairCards.size() > 0):
		adjustPositionRotationToThrow(currentPlayer, cardsSplitted.pairCards)
		removeCardsFromPile(currentPlayer, cardsSplitted.pairCards)
	
	# rearranging cards for both players
	await get_tree().create_timer(0.5).timeout
	rearrangeCards(nextPlayer, nextPlayerIndex)
	if currentPlayer.cardsInHand.size() > 0:
		rearrangeCards(currentPlayer, currentPlayerIndex)
	
	playerTurn = getNextPlayerIndex(currentPlayerIndex)
	isGameMoving = true

# TODO: when rearranging make the card position relative to the number of remaining cards 
func rearrangeCards(node, pIndex):
	var cards = node.get_children()
	
	match pIndex:
		0:
			angle = deg_to_rad(-105)
			for card in cards:
				card.startPosition = card.position
				card.startRotation = card.rotation
				OvalAngleVector = Vector2(-Horizontal_radius * cos(angle), -Vertical_radius * sin(angle))
				card.targetPosition = CenterCardOval - OvalAngleVector - $Player.position
				card.targetRotation = deg_to_rad(angle)/2
				card.state = STATE.REORGANIZE
				angle += PlayerHandCardAngleOffset
		1:
			posOffsetYRight = 0
			for card in cards:
				card.startPosition = card.position
				card.startRotation = card.rotation
				card.targetPosition = ViewportSize * Vector2(0.95, 0.85 - posOffsetYRight) - node.position
				card.targetRotation = card.rotation
				card.state = STATE.REORGANIZE
				posOffsetYRight += RightPlayerCardPositionOffset
		2:
			posOffsetX = 0
			for card in cards:
				card.startPosition = card.position
				card.startRotation = card.rotation
				card.targetPosition = ViewportSize * Vector2(0.55 - posOffsetX, -0.1) - node.position
				card.targetRotation = card.rotation
				card.state = STATE.REORGANIZE
				posOffsetX += TopPlayerCardPositionOffset
		3:
			posOffsetYLeft = 0
			for card in cards:
				card.startPosition = card.position
				card.startRotation = card.rotation
				card.targetPosition = ViewportSize * Vector2(-0.08, 0.85 - posOffsetYLeft) - node.position
				card.targetRotation = card.rotation
				card.state = STATE.REORGANIZE
				posOffsetYLeft += LeftPlayerCardPositionOffset

# NEW FUNCTIONS FROM HERE

# Remove the cards from pile (free the card)
func removeCardsFromPile(node, toRemoveCards):
	node.RemoveCardsFromHand(toRemoveCards)
	for card in node.get_children():
		if toRemoveCards.has(card.cardName):
			card.free()

# Add a card to the pile
func addCardToPile(toAddCardName, node, state, startPos, startRot, playerIndex, shouldCardBeVisible=false):
	var targetPosition = Vector2(0, 0)
	var targetRotation = deg_to_rad(0)
	#var cardNum = 0
	
	var new_to_add_card = CardBase.instantiate()
	new_to_add_card.cardName = toAddCardName
	new_to_add_card.startPosition = startPos
	new_to_add_card.startRotation = startRot
	
	match playerIndex:
		0:
			OvalAngleVector = Vector2(-Horizontal_radius * cos(angle), -Vertical_radius * sin(angle))
			targetPosition = CenterCardOval - OvalAngleVector - node.position
			targetRotation = deg_to_rad(angle)/2
		1:
			targetPosition = ViewportSize * Vector2(0.95, 1 - posOffsetYRight) - node.position
			targetRotation = deg_to_rad(90)
		2:
			targetPosition = ViewportSize * Vector2(0.75 - posOffsetX, -0.1) - node.position
			targetRotation = deg_to_rad(0)
		3:
			targetPosition = ViewportSize * Vector2(-0.08, 1 - posOffsetYLeft) - node.position
			targetRotation = deg_to_rad(90)
		-1:
			targetPosition = Vector2(rng.randf_range(-2.0, 10.0), rng.randf_range(-2.0, 10.0))
			targetRotation = deg_to_rad(startRot + rng.randf_range(-30.0, 60.0))
	
	new_to_add_card.targetPosition = targetPosition
	new_to_add_card.targetRotation = targetRotation
		
	if shouldCardBeVisible:
		new_to_add_card.SetCardVisible()
	# TODO: make rearrange of cards more smoother upon new card
#	if playerIndex == 0:
#		for card in node.get_children():
#			angle = PI/2 + cardSpread*(float(node.get_child_count())/2 - cardNum)
#			OvalAngleVector = Vector2(-Horizontal_radius * cos(angle), -Vertical_radius * sin(angle))
#			card.startPosition = card.position
#			card.startRotation = card.rotation
#			targetPosition = CenterCardOval - OvalAngleVector - node.position
#			targetRotation = deg_to_rad(angle)/2
#			card.state = STATE.REORGANIZE
#			cardNum += 1
#	if playerIndex == 1:
#		for card in node.get_children():
#			card.startPosition = card.position
#			card.startRotation = card.rotation
#			card.targetPosition = ViewportSize * Vector2(card.position.x, 0.6 + pow(cardNum, -1) * 0.07* floor(cardNum/2)) - node.position
#			card.targetRotation = card.rotation
#			card.state = STATE.REORGANIZE
#			cardNum += 1
	
	node.add_child(new_to_add_card)
	if not playerIndex == -1:
		node.AddCardInHand(new_to_add_card.cardName)
	new_to_add_card.state = state

# Adjust card in picking mode, after picking mode and in pair mode for player cards
func pairUnPairCards(node, index, state, shouldEffectAllCard=true, affectedCardsName=[], isreverse=false):
	var offset = 60
	var spread = 0 # TODO: Create a spread effect in picking mode
	var tPosOffSetY = 0
	var tPosOffSetX = 0
	
	match index:
		0:
			tPosOffSetX = spread
			if not isreverse:
				tPosOffSetY = -offset
			else:
				tPosOffSetY = offset
		1:
			tPosOffSetY = spread
			if not isreverse:
				tPosOffSetX = -offset
			else:
				tPosOffSetX = offset
		2:
			tPosOffSetX = spread
			if not isreverse:
				tPosOffSetY = offset
			else:
				tPosOffSetY = -offset
		3:
			tPosOffSetY = spread
			if not isreverse:
				tPosOffSetX = offset
			else:
				tPosOffSetX = -offset
	
	if shouldEffectAllCard:
		for card in node.get_children():
			card.startPosition = card.position
			card.targetPosition = Vector2(card.position.x + tPosOffSetX, card.position.y + tPosOffSetY)
			card.state = state
	else:
		for card in node.get_children():
			if affectedCardsName.has(card.cardName):
				card.startPosition = card.position
				card.targetPosition = Vector2(card.position.x + tPosOffSetX, card.position.y + tPosOffSetY)
				card.state = state

# Adjust the card before adding it to the pair pile and add to pile card
func adjustPositionRotationToThrow(node, toRemoveCards):
	var sPos = 0
	var sRot = 0
	
	for card in node.get_children():
		if toRemoveCards.has(card.cardName):
			sPos = Vector2(PairCardsPosition.x - card.position.x, PairCardsPosition.y - card.position.y)
			sRot = card.rotation
			addCardToPile(card.cardName, $PairCards, STATE.MOVINGFROMHANDTODECK, sPos, sRot, -1, true)

# Remove the cards to pair pile
func removeCards(node):
	var cardsSplited = Utility.findPairs(node.cardsInHand)
	node.SetNewSetOfCards(cardsSplited.nonPairCards)
	adjustPositionRotationToThrow(node, cardsSplited.pairCards)
	removeCardsFromPile(node, cardsSplited.pairCards)

func getNextPlayerIndex(currentIndex):
	var nextPlayerIndex = (currentIndex+1) % 4
	var numberOfCardsInPlayerHand = getNumberOfPlayerCards(nextPlayerIndex)
	if numberOfCardsInPlayerHand <= 0:
		return getNextPlayerIndex(nextPlayerIndex)
	return nextPlayerIndex

func getNextPlayerToPickFromIndex(currentPlayerIndex):
	var nextPlayerIndex = (currentPlayerIndex+1)%4
	var numberOfCardsInPlayerHand = getNumberOfPlayerCards(nextPlayerIndex)
	if numberOfCardsInPlayerHand <= 0:
		return getNextPlayerToPickFromIndex(nextPlayerIndex)
	return nextPlayerIndex
	
func getNumberOfPlayerCards(index):
	var numberOfCardsInPlayerHand = 0
	match index:
		0:
			numberOfCardsInPlayerHand = $Player.cardsInHand.size()
		1:
			numberOfCardsInPlayerHand = $Player2.cardsInHand.size()
		2:
			numberOfCardsInPlayerHand = $Player3.cardsInHand.size()
		3:
			numberOfCardsInPlayerHand = $Player4.cardsInHand.size()
	return numberOfCardsInPlayerHand
