extends Node2D

const CardBase = preload("res://Prefabs/Card/Card.tscn")
const Utility = preload("res://Utils/utility.gd")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")
const Emotes = preload("res://Utils/emotes.gd")

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
@onready var playerToPickFromNode = $Players/Player2

var cardSpread = 0.25

var posOffsetYRight = 0 # Position of cards of player to the right
var posOffsetYLeft = 0 # Position of cards of player to the left
var posOffsetX = 0 # Position of cards of player to the top

var isGameMoving = false # Determine the game is on automatic mode or waiting for player inputs
var isPlayerTurnToPick = false # Determine if it is players turn to pick card
var isGameOver = false # Determine the game is over or not

# Offset of cards angle and position of each players
const PlayerHandCardAngleOffset = 0.12
const RightPlayerCardPositionOffset = 0.07
const TopPlayerCardPositionOffset = 0.05
const LeftPlayerCardPositionOffset = 0.07

# random number generator
var rng = RandomNumberGenerator.new()

# picked card by players
var pickedCard = null

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
	startTheGame()

func startTheGame():
	# reset everything to replay
	removeTheUnpairJack(getLossingPlayerIndex())
	for card in $PairCards.get_children():
		card.free()
	removeEmotes()
	isGameOver = false
	$GameOverText.visible = false
	$ReplayButton.visible = false
	$ExitButton.visible = false
	$IndicatorHasJack.texture = null
	$YourTurnIndicator.hide()
	
	isGameMoving = false
	playerTurn = 0
	angle = deg_to_rad(-130)
	posOffsetX = 0
	posOffsetYLeft = 0
	posOffsetYRight = 0
	playerToPickFrom = 1
	playerToPickFromNode = $Players/Player2
	pickedCard = null
	deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
	
	# real game start
	var packOfDeckPosition = $PackOfDeck.position
	var startRotation = deg_to_rad(30)
	
	for card in deckOfCards:
		if playerTurn == 0:
			# TODO: Make it more dynamic for later when removing pairs and adding cards to hand 
			addCardToPile(card, $Players/Player, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 0, true)
			angle += PlayerHandCardAngleOffset
		if playerTurn == 1:
			addCardToPile(card, $Players/Player2, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 1)
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerTurn == 2:
			addCardToPile(card, $Players/Player3, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 2)
			posOffsetX += TopPlayerCardPositionOffset
		if playerTurn == 3:
			addCardToPile(card, $Players/Player4, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 3)
			posOffsetYLeft += LeftPlayerCardPositionOffset
		
		playerTurn = (1+playerTurn)%4
		
		await get_tree().create_timer(0.08).timeout
		
	$PackOfDeck.visible = false
	playerTurn = 0
	
	$RemovePairBotTimer.start() # starting the timer for the bots to remove their pairs

func _physics_process(_delta):
	if not isGameOver:
		if $PairCards.get_child_count() >= 50:
			isGameMoving = false
			isGameOver = true
			$GameOverText.visible = true
			$ReplayButton.visible = true
			$ExitButton.visible = true
			var losingPlayerIndex = getLossingPlayerIndex()
			showFinalEmotes(losingPlayerIndex)
			showTheUnpairJack(losingPlayerIndex)
		if isGameMoving:
			playerToPickFrom = getNextPlayerToPickFromIndex(playerTurn)
			match playerToPickFrom:
				0:
					playerToPickFromNode = $Players/Player
				1:
					playerToPickFromNode = $Players/Player2
				2:
					playerToPickFromNode = $Players/Player3
				3:
					playerToPickFromNode = $Players/Player4
			match playerTurn:
				0:
					$YourTurnIndicator.show()
					turn(playerToPickFromNode, playerToPickFrom, $Players/Player, 0)
				1:
					$YourTurnIndicator.hide()
					turn(playerToPickFromNode, playerToPickFrom, $Players/Player2, 1)
				2:
					$YourTurnIndicator.hide()
					turn(playerToPickFromNode, playerToPickFrom, $Players/Player3, 2)
				3:
					$YourTurnIndicator.hide()
					turn(playerToPickFromNode, playerToPickFrom, $Players/Player4, 3)

func _on_remove_pair_bot_timer_timeout():
	removeCards($Players/Player2)
	removeCards($Players/Player3)
	removeCards($Players/Player4)
	
	# starting the timer for the pairs in player hand to pop up
	$RemovePairPlayerTimer.start() 

func _on_remove_pair_player_timer_timeout():
	var cardsSplit = Utility.findPairs($Players/Player.cardsInHand)
	pairUnPairCards($Players/Player, 0, STATE.INPAIR, false, cardsSplit.pairCards)
	
	# rearrange BOT cards
	rearrangeCards($Players/Player2, 1)
	rearrangeCards($Players/Player3, 2)
	rearrangeCards($Players/Player4, 3)
	
	# await 0.5 sec
	await get_tree().create_timer(0.5).timeout
	
	# remove the pair cards from player hand
	removeCards($Players/Player)
	rearrangeCards($Players/Player, 0)
	
	# await 0.5 sec
	await get_tree().create_timer(0.5).timeout
	
	# start the game in auto mode
	isGameMoving = true

func turn(nextPlayer, nextPlayerIndex, currentPlayer, currentPlayerIndex):
	pairUnPairCards(nextPlayer, nextPlayerIndex, STATE.INPICKING)
	isGameMoving = false
	
	# picking card from next player
	if currentPlayerIndex == 0:
		await get_tree().create_timer(3).timeout
		if not pickedCard:
			await get_tree().create_timer(1.5).timeout
		if not pickedCard:
			pickedCard = Utility.pickRandomCard(nextPlayer.get_children())
	else:
		await get_tree().create_timer(1.5).timeout
		pickedCard = Utility.pickRandomCard(nextPlayer.get_children())
	
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
	if currentPlayerIndex == 0 || nextPlayerIndex == 0:
		if checkJack():
			$IndicatorHasJack.texture = load("res://Assets/UI/indicator_has_jack.png")
		else:
			$IndicatorHasJack.texture = load("res://Assets/UI/indicator_no_jack.png")
	if currentPlayer.cardsInHand.size() > 0:
		rearrangeCards(currentPlayer, currentPlayerIndex)
	
	playerTurn = getNextPlayerIndex(currentPlayerIndex)
	pickedCard = null
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
				card.targetPosition = CenterCardOval - OvalAngleVector - $Players/Player.position
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
	new_to_add_card.connect("pick_card", pickCardByPlayer)
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
			targetRotation = deg_to_rad(-90)
		2:
			targetPosition = ViewportSize * Vector2(0.75 - posOffsetX, -0.1) - node.position
			targetRotation = deg_to_rad(180)
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
	var isCardInPickingOrPair = false
	
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
				if playerTurn == 0 and playerToPickFrom == 1:
					isCardInPickingOrPair = true # later make it for all cards in multiplayer mode
			else:
				tPosOffSetX = offset
		2:
			tPosOffSetX = spread
			if not isreverse:
				tPosOffSetY = offset
				if playerTurn == 0 and playerToPickFrom == 2:
					isCardInPickingOrPair = true
			else:
				tPosOffSetY = -offset
		3:
			tPosOffSetY = spread
			if not isreverse:
				tPosOffSetX = offset
				if playerTurn == 0 and playerToPickFrom == 3:
					isCardInPickingOrPair = true
			else:
				tPosOffSetX = -offset
	
	if shouldEffectAllCard:
		for card in node.get_children():
			card.startPosition = card.position
			card.targetPosition = Vector2(card.position.x + tPosOffSetX, card.position.y + tPosOffSetY)
			card.isCardInPickingOrPair = isCardInPickingOrPair
			card.state = state
	else:
		for card in node.get_children():
			if affectedCardsName.has(card.cardName):
				card.startPosition = card.position
				card.targetPosition = Vector2(card.position.x + tPosOffSetX, card.position.y + tPosOffSetY)
				card.isCardInPickingOrPair = isCardInPickingOrPair
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

# Get the index of next player that will pick
func getNextPlayerIndex(currentIndex):
	var nextPlayerIndex = (currentIndex+1) % 4
	var numberOfCardsInPlayerHand = getNumberOfPlayerCards(nextPlayerIndex)
	if numberOfCardsInPlayerHand <= 0:
		return getNextPlayerIndex(nextPlayerIndex)
	return nextPlayerIndex

# Get the index of next player that will get their card picked
func getNextPlayerToPickFromIndex(currentPlayerIndex):
	var nextPlayerIndex = (currentPlayerIndex+1)%4
	var numberOfCardsInPlayerHand = getNumberOfPlayerCards(nextPlayerIndex)
	if numberOfCardsInPlayerHand <= 0:
		return getNextPlayerToPickFromIndex(nextPlayerIndex)
	return nextPlayerIndex

# get the number of cards in player hand
func getNumberOfPlayerCards(index):
	var numberOfCardsInPlayerHand = 0
	match index:
		0:
			numberOfCardsInPlayerHand = $Players/Player.cardsInHand.size()
		1:
			numberOfCardsInPlayerHand = $Players/Player2.cardsInHand.size()
		2:
			numberOfCardsInPlayerHand = $Players/Player3.cardsInHand.size()
		3:
			numberOfCardsInPlayerHand = $Players/Player4.cardsInHand.size()
	return numberOfCardsInPlayerHand

# pick the card from human player
func pickCardByPlayer(card):
	pickedCard = card

func getLossingPlayerIndex():
	if $Players/Player.cardsInHand.size() >= 1:
		return 0
	if $Players/Player2.cardsInHand.size() >= 1:
		return 1
	if $Players/Player3.cardsInHand.size() >= 1:
		return 2
	
	return 3

# show emotes at end of game
func showFinalEmotes(losserIndex):
	match losserIndex:
		0:
			$Emotes/PlayerEmote.texture = load("res://Assets/Emotes/emote_"+Emotes.getSadEmote()+".png")
			$Emotes/Player2Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			$Emotes/Player3Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			$Emotes/Player4Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
		1:
			$Emotes/Player2Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getSadEmote()+".png")
			$Emotes/PlayerEmote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			$Emotes/Player3Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			$Emotes/Player4Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
		2:
			$Emotes/Player3Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getSadEmote()+".png")
			$Emotes/Player2Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			$Emotes/PlayerEmote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			$Emotes/Player4Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
		3:
			$Emotes/Player4Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getSadEmote()+".png")
			$Emotes/Player2Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			$Emotes/Player3Emote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			$Emotes/PlayerEmote.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")

# on click replay button
func _on_replay_button_pressed():
	startTheGame()

# on click exit button
func _on_exit_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

# remove the emotes
func removeEmotes():
	$Emotes/PlayerEmote.texture = null
	$Emotes/Player2Emote.texture = null
	$Emotes/Player3Emote.texture = null
	$Emotes/Player4Emote.texture = null

# Show the remaining jack
func showTheUnpairJack(playerIndex):
	var player
	match playerIndex:
		0:
			player = $Players/Player
		1:
			player = $Players/Player2
		2:
			player = $Players/Player3
		3:
			player = $Players/Player4
	
	for card in player.get_children():
		card.SetCardVisible()

# Remove the unpaired jack
func removeTheUnpairJack(playerIndex):
	var player
	match playerIndex:
		0:
			player = $Players/Player
		1:
			player = $Players/Player2
		2:
			player = $Players/Player3
		3:
			player = $Players/Player4
	
	for card in player.get_children():
		card.free()
	player.RemoveAllCards()

# Check for jack in player hand
func checkJack():
	for card in $Players/Player.cardsInHand:
		if card == "card_j_spade" or card == "card_j_diamond" or card == "card_j_heart":
			return true
	return false
