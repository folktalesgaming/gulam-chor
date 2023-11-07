extends Node2D

# PRELOAD
const CardBase = preload("res://Prefabs/Card/Card.tscn")
const Utility = preload("res://Utils/utility.gd")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")
const Emotes = preload("res://Utils/emotes.gd")

# Nodes from game play scene
@onready var JackIndicator = get_node("UI/IndicatorHasJack")

@onready var CardShuffleAudio = get_node("Audios/CardShuffle")
@onready var ButtonClickAudio = get_node("Audios/ButtonClick")
@onready var CardTakeAudio = get_node("Audios/CardTake")
@onready var CardPairThrowAudio = get_node("Audios/CardPairThrow")

@onready var Player1 = get_node("Players/Player")
@onready var Player2 = get_node("Players/Player2")
@onready var Player3 = get_node("Players/Player3")
@onready var Player4 = get_node("Players/Player4")

@onready var PackOfDeck = get_node("PackOfDeck")
@onready var PairCards = get_node("PairCards")

@onready var GameOverText = get_node("GameOverText")
@onready var ReplayButton = get_node("ReplayButton")
@onready var ExitButton = get_node("ExitButton")
@onready var PausePanel = get_node("UI/PausePanel")

@onready var RemovePairBotTimer = get_node("RemovePairBotTimer")
@onready var RemovePairPlayerTimer = get_node("RemovePairPlayerTimer")
@onready var PlayerPickTurnTimer = get_node("PlayerPickTurnTimer")

@onready var PlayerPickTurnProgressBar = get_node("UI/Control/PlayerPickTurnProgressBar")

@onready var EmotePlayer1 = get_node("Emotes/PlayerEmote")
@onready var EmotePlayer2 = get_node("Emotes/Player2Emote")
@onready var EmotePlayer3 = get_node("Emotes/Player3Emote")
@onready var EmotePlayer4 = get_node("Emotes/Player4Emote")

# Utilities and global variables
@onready var deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
@onready var PairCardsPosition = PairCards.position

@onready var ViewportSizeX = ProjectSettings.get_setting("display/window/size/viewport_width") # Size of viewport
@onready var ViewportSizeY = ProjectSettings.get_setting("display/window/size/viewport_height") # Size of viewport
#@onready var ViewportSize = Vector2(ViewportSizeX, ViewportSizeY)
#@onready var ViewportSize = Vector2(get_viewport().size.x, get_viewport().size.y) # Size of viewport
@onready var CenterCardOval = ViewportSizeX * Vector2(0.45, 1.55) # Calculating the center of oval for player card arc
@onready var Horizontal_radius = ViewportSizeX * 0.45 # Horizontal radius of the oval arc
@onready var Vertical_radius = ViewportSizeY * 0.2 # Vertical radius of the oval arc
var angle = deg_to_rad(-130) # Angle at which the card must be positioned
var OvalAngleVector = Vector2() # Vector to convert the polar points (r, 0) to cartesian points (x,y)

var playerTurn = 0 # To determine the turn of player
var playerToPickFrom = 1
@onready var playerToPickFromNode = Player2

var cardSpread = 0.25

var posOffsetYRight = 0 # Position of cards of player to the right
var posOffsetYLeft = 0 # Position of cards of player to the left
var posOffsetX = 0 # Position of cards of player to the top

var isGameMoving = false # Determine the game is on automatic mode or waiting for player inputs
var isPlayerTurnToPick = false # Determine if it is players turn to pick card
var isGameOver = false # Determine the game is over or not
var isPaused = false # Determine the game is paused or not

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
	INPICKED,
	INREMOVEPICKED,
	SHUFFLE,
}

func _ready():
	startTheGame()

func startTheGame():
	# reset everything to replay
	removeTheUnpairJack(getLossingPlayerIndex())
	for card in PairCards.get_children():
		card.free()
	removeEmotes()
	isGameOver = false
	GameOverText.visible = false
	ReplayButton.visible = false
	ExitButton.visible = false
	JackIndicator.texture = null
	indicatePlayerTurn(false)
	
	isGameMoving = false
	playerTurn = 0
	angle = deg_to_rad(-130)
	posOffsetX = 0
	posOffsetYLeft = 0
	posOffsetYRight = 0
	playerToPickFrom = 1
	playerToPickFromNode = Player2
	pickedCard = null
	deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
	
	# real game start
	var packOfDeckPosition = PackOfDeck.position
	var startRotation = deg_to_rad(30)
	
	CardShuffleAudio.play()
	for card in deckOfCards:
		if playerTurn == 0:
			# TODO: Make it more dynamic for later when removing pairs and adding cards to hand 
			addCardToPile(card, Player1, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 0, true)
			angle += PlayerHandCardAngleOffset
		if playerTurn == 1:
			addCardToPile(card, Player2, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 1)
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerTurn == 2:
			addCardToPile(card, Player3, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 2)
			posOffsetX += TopPlayerCardPositionOffset
		if playerTurn == 3:
			addCardToPile(card, Player4, STATE.MOVINGFROMDECKTOHAND, packOfDeckPosition, startRotation, 3)
			posOffsetYLeft += LeftPlayerCardPositionOffset
		
		playerTurn = (1+playerTurn)%4
		
		await get_tree().create_timer(0.08).timeout
		
	PackOfDeck.visible = false
	playerTurn = 0
	CardShuffleAudio.stop()
	
	RemovePairBotTimer.start() # starting the timer for the bots to remove their pairs

func _physics_process(_delta):
	if not isGameOver:
		if not isPaused:
			if PairCards.get_child_count() >= 50:
				isGameMoving = false
				isGameOver = true
				GameOverText.visible = true
				ReplayButton.visible = true
				ExitButton.visible = true
				var losingPlayerIndex = getLossingPlayerIndex()
				showFinalEmotes(losingPlayerIndex)
				showTheUnpairJack(losingPlayerIndex)
			if isGameMoving:
				playerToPickFrom = getNextPlayerToPickFromIndex(playerTurn)
				match playerToPickFrom:
					0:
						playerToPickFromNode = Player1
					1:
						playerToPickFromNode = Player2
					2:
						playerToPickFromNode = Player3
					3:
						playerToPickFromNode = Player4
				match playerTurn:
					0:
						indicatePlayerTurn(true)
						turn(playerToPickFromNode, playerToPickFrom, Player1, 0)
					1:
						indicatePlayerTurn(false)
						turn(playerToPickFromNode, playerToPickFrom, Player2, 1)
					2:
						indicatePlayerTurn(false)
						turn(playerToPickFromNode, playerToPickFrom, Player3, 2)
					3:
						indicatePlayerTurn(false)
						turn(playerToPickFromNode, playerToPickFrom, Player4, 3)

func _on_remove_pair_bot_timer_timeout():
	removeCards(Player2)
	removeCards(Player3)
	removeCards(Player4)
	
	# starting the timer for the pairs in player hand to pop up
	RemovePairPlayerTimer.start() 

func _on_remove_pair_player_timer_timeout():
	var cardsSplit = Utility.findPairs(Player1.cardsInHand)
	pairUnPairCards(Player1, 0, STATE.INPAIR, false, cardsSplit.pairCards)
	
	# rearrange BOT cards
	rearrangeCards(Player2, 1)
	rearrangeCards(Player3, 2)
	rearrangeCards(Player4, 3)
	
	# await 0.5 sec
	await get_tree().create_timer(0.5).timeout
	
	# remove the pair cards from player hand
	removeCards(Player1)
	CardPairThrowAudio.play()
	rearrangeCards(Player1, 0)
	
	# await 0.5 sec
	await get_tree().create_timer(0.5).timeout
	
	# start the game in auto mode
	isGameMoving = true

func turn(nextPlayer, nextPlayerIndex, currentPlayer, currentPlayerIndex):
	pairUnPairCards(nextPlayer, nextPlayerIndex, STATE.INPICKING)
	isGameMoving = false
	
	# picking card from next player
	if currentPlayerIndex == 0:
		PlayerPickTurnTimer.start()
		PlayerPickTurnProgressBar.visible = true
		await get_tree().create_timer(3).timeout
		PlayerPickTurnProgressBar.visible = false
		if not pickedCard:
			pickedCard = Utility.pickRandomCard(nextPlayer.get_children())
	else:
		if Player1.cardsInHand.size() <= 0:
			await get_tree().create_timer(0.2).timeout
		else:
			await get_tree().create_timer(1).timeout
		pickedCard = Utility.pickRandomCard(nextPlayer.get_children())
	
	var sPos = pickedCard.position
	var sRot = pickedCard.rotation
	var shouldShowCard = false
	if currentPlayerIndex == 0:
		shouldShowCard = true
	addCardToPile(pickedCard.cardName, currentPlayer, STATE.MOVINGFROMPICKINGTOHAND, sPos, sRot, currentPlayerIndex, shouldShowCard)
	CardTakeAudio.play()
	removeCardsFromPile(nextPlayer, [pickedCard.cardName])
	pairUnPairCards(nextPlayer, nextPlayerIndex, STATE.MOVINGFROMPICKINGTOHAND, true, [], true)
	
	# checking if there is pair after pickup and throwing the pair cards
	if Player1.cardsInHand.size() <= 0:
		await get_tree().create_timer(0.3).timeout
	else:
		await get_tree().create_timer(0.7).timeout
	var cardsSplitted = Utility.findPairs(currentPlayer.cardsInHand)
	if(cardsSplitted.pairCards.size() > 0):
		adjustPositionRotationToThrow(currentPlayer, cardsSplitted.pairCards)
		CardPairThrowAudio.play()
		removeCardsFromPile(currentPlayer, cardsSplitted.pairCards)
	
	# rearranging cards for both players
	if Player1.cardsInHand.size() <= 0:
		await get_tree().create_timer(0.2).timeout
	else:
		await get_tree().create_timer(0.5).timeout
	rearrangeCards(nextPlayer, nextPlayerIndex)
	if currentPlayerIndex == 0 || nextPlayerIndex == 0:
		if checkJack():
			JackIndicator.texture = load("res://Assets/UI/indicator_has_jack.png")
		else:
			JackIndicator.texture = load("res://Assets/UI/indicator_no_jack.png")
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
				card.targetPosition = CenterCardOval - OvalAngleVector - Player1.position
				card.targetRotation = deg_to_rad(angle)/2
				card.state = STATE.REORGANIZE
				angle += PlayerHandCardAngleOffset
		1:
			posOffsetYRight = 0
			for card in cards:
				card.startPosition = card.position
				card.startRotation = card.rotation
				card.targetPosition = ViewportSizeX * Vector2(0.95, 0.85 - posOffsetYRight) - node.position
				card.targetRotation = card.rotation
				card.state = STATE.REORGANIZE
				posOffsetYRight += RightPlayerCardPositionOffset
		2:
			posOffsetX = 0
			for card in cards:
				card.startPosition = card.position
				card.startRotation = card.rotation
				card.targetPosition = ViewportSizeX * Vector2(0.55 - posOffsetX, -0.1) - node.position
				card.targetRotation = card.rotation
				card.state = STATE.REORGANIZE
				posOffsetX += TopPlayerCardPositionOffset
		3:
			posOffsetYLeft = 0
			for card in cards:
				card.startPosition = card.position
				card.startRotation = card.rotation
				card.targetPosition = ViewportSizeX * Vector2(-0.08, 0.85 - posOffsetYLeft) - node.position
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
			targetPosition = ViewportSizeX * Vector2(0.95, 1 - posOffsetYRight) - node.position
			targetRotation = deg_to_rad(-90)
		2:
			targetPosition = ViewportSizeX * Vector2(0.75 - posOffsetX, -0.1) - node.position
			targetRotation = deg_to_rad(180)
		3:
			targetPosition = ViewportSizeX * Vector2(-0.08, 1 - posOffsetYLeft) - node.position
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
			addCardToPile(card.cardName, PairCards, STATE.MOVINGFROMHANDTODECK, sPos, sRot, -1, true)

# Remove the cards to pair pile
func removeCards(node):
	var cardsSplited = Utility.findPairs(node.cardsInHand)
	node.SetNewSetOfCards(cardsSplited.nonPairCards)
	adjustPositionRotationToThrow(node, cardsSplited.pairCards)
	CardPairThrowAudio.play()
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
			numberOfCardsInPlayerHand = Player1.cardsInHand.size()
		1:
			numberOfCardsInPlayerHand = Player2.cardsInHand.size()
		2:
			numberOfCardsInPlayerHand = Player3.cardsInHand.size()
		3:
			numberOfCardsInPlayerHand = Player4.cardsInHand.size()
	return numberOfCardsInPlayerHand

# pick the card from human player
func pickCardByPlayer(card):
	if playerTurn == 0 and not pickedCard == null and not pickedCard == card:
		for cards in playerToPickFromNode.get_children():
			if cards.cardName == pickedCard.cardName:
				cards.state = STATE.INREMOVEPICKED
				break
	if pickedCard == card:
		for cards in playerToPickFromNode.get_children():
			if cards.cardName == pickedCard.cardName:
				cards.state = STATE.INREMOVEPICKED
				break
		pickedCard = null
	else:
		pickedCard = card

func getLossingPlayerIndex():
	if Player1.cardsInHand.size() >= 1:
		return 0
	if Player2.cardsInHand.size() >= 1:
		return 1
	if Player3.cardsInHand.size() >= 1:
		return 2
	
	return 3

# show emotes at end of game
func showFinalEmotes(losserIndex):
	match losserIndex:
		0:
			EmotePlayer1.texture = load("res://Assets/Emotes/emote_"+Emotes.getSadEmote()+".png")
			EmotePlayer2.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer3.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer4.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
		1:
			EmotePlayer1.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer2.texture = load("res://Assets/Emotes/emote_"+Emotes.getSadEmote()+".png")
			EmotePlayer3.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer4.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
		2:
			EmotePlayer1.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer2.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer3.texture = load("res://Assets/Emotes/emote_"+Emotes.getSadEmote()+".png")
			EmotePlayer4.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
		3:
			EmotePlayer1.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer2.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer3.texture = load("res://Assets/Emotes/emote_"+Emotes.getHappyEmote()+".png")
			EmotePlayer4.texture = load("res://Assets/Emotes/emote_"+Emotes.getSadEmote()+".png")

# on click replay button
func _on_replay_button_pressed():
	ButtonClickAudio.play()
	await get_tree().create_timer(0.2).timeout
	startTheGame()

# on click exit button
func _on_exit_button_pressed():
	ButtonClickAudio.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

# remove the emotes
func removeEmotes():
	EmotePlayer1.texture = null
	EmotePlayer2.texture = null
	EmotePlayer3.texture = null
	EmotePlayer4.texture = null

# Show the remaining jack
func showTheUnpairJack(playerIndex):
	var player
	match playerIndex:
		0:
			player = Player1
		1:
			player = Player2
		2:
			player = Player3
		3:
			player = Player4
	
	for card in player.get_children():
		card.SetCardVisible()

# Remove the unpaired jack
func removeTheUnpairJack(playerIndex):
	var player
	match playerIndex:
		0:
			player = Player1
		1:
			player = Player2
		2:
			player = Player3
		3:
			player = Player4
	
	for card in player.get_children():
		card.free()
	player.RemoveAllCards()

# Check for jack in player hand
func checkJack():
	for card in Player1.cardsInHand:
		if card == "card_j_spade" or card == "card_j_diamond" or card == "card_j_heart":
			return true
	return false

# indicate player turn
func indicatePlayerTurn(isPlayerTurn):
	if isPlayerTurn:
		EmotePlayer1.texture = load("res://Assets/Emotes/emote_dots1.png")
		await get_tree().create_timer(0.5).timeout
		EmotePlayer1.texture = load("res://Assets/Emotes/emote_dots2.png")
		await get_tree().create_timer(0.5).timeout
		EmotePlayer1.texture = load("res://Assets/Emotes/emote_dots3.png")
		await get_tree().create_timer(0.5).timeout
		EmotePlayer1.texture = load("res://Assets/Emotes/emote_dots1.png")
		await get_tree().create_timer(0.5).timeout
		EmotePlayer1.texture = load("res://Assets/Emotes/emote_dots2.png")
		await get_tree().create_timer(0.5).timeout
		EmotePlayer1.texture = null
	else:
		EmotePlayer1.texture = null

func _on_shuffle_button_pressed():
	ButtonClickAudio.play()

# Pause Game
# TODO: make the pause work when the player turn is on
func _on_pause_button_pressed():
	ButtonClickAudio.play()
	isPaused = true
	if playerTurn == 0:
		PlayerPickTurnTimer.set_paused(true)
	PausePanel.visible = true

# Continue Game
func _on_continue_button_pressed():
	ButtonClickAudio.play()
	PausePanel.visible = false
	isPaused = false
	if playerTurn == 0:
		PlayerPickTurnTimer.start()

# Quit Game
func _on_quit_button_pressed():
	ButtonClickAudio.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
