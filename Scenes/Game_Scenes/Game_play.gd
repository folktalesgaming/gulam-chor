extends Node2D

var random_mode_setting_path = ("user://random-mode-setting.save")

# PRELOAD
const CardBase = preload("res://Prefabs/Card/Card.tscn")
const Utility = preload("res://Utils/utility.gd")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")
const DeckOfCardRandomMode = preload("res://Utils/deck_of_cards_all.gd")
const Emotes = preload("res://Utils/emotes.gd")

# Nodes from game play scene
@onready var JackIndicator = %IndicatorHasJack

@onready var Player1 = %Player
@onready var Player2 = %Player2
@onready var Player3 = %Player3
@onready var Player4 = %Player4

@onready var PackOfDeck = %PackOfDeck
@onready var pair_cards = %PairCards

@onready var game_over_panel = %GameOverPanel
@onready var ReplayButton = %ReplayButton
@onready var ExitButton = %ExitButton
@onready var PausePanel = %PausePanel

@onready var remove_pair_bot_timer = %RemovePairBotTimer
@onready var PlayerPickTurnTimer = %PlayerPickTurnTimer

@onready var PlayerPickTurnProgressBar = %PlayerPickTurnProgressBar

@onready var EmotePlayer1 = %PlayerEmote
@onready var EmotePlayer2 = %Player2Emote
@onready var EmotePlayer3 = %Player3Emote
@onready var EmotePlayer4 = %Player4Emote
@onready var player_turn_emote = %PlayerTurnEmote

# Utilities and global variables
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

var isRandomMode = false
const PLAYER_PICK_TIME = 3 # time given for player to pick the card

func _load_random_mode_setting():
	if FileAccess.file_exists(random_mode_setting_path):
		var file = FileAccess.open(random_mode_setting_path, FileAccess.READ)
		var fileData = file.get_8()
		if fileData == 1:
			isRandomMode = true
		else:
			isRandomMode = false

func _ready():
	_load_random_mode_setting()
	startTheGame()

func startTheGame():
	_reset_gameplay()
	indicatePlayerTurn(false)
	var deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
	if isRandomMode:
		deckOfCards = Utility.shuffleDeck(DeckOfCardRandomMode.getDeckAllRandomMode())
		JackIndicator.texture = load("res://Assets/UI/random_mode_indicator.png")
	
	var packOfDeckPosition = PackOfDeck.position
	var startRotation = deg_to_rad(30)
	
	AudioManager._play_shuffle_sfx()
	for card in deckOfCards:
		if playerTurn == 0:
			angle += PlayerHandCardAngleOffset
		if playerTurn == 1:
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerTurn == 2:
			posOffsetX += TopPlayerCardPositionOffset
		if playerTurn == 3:
			posOffsetYLeft += LeftPlayerCardPositionOffset
		_add_cards(playerTurn, card, packOfDeckPosition, startRotation, STATE.MOVINGFROMDECKTOHAND, playerTurn==0)
		
		playerTurn = (1+playerTurn)%4
		
		await get_tree().create_timer(0.08).timeout
		
	PackOfDeck.hide()
	checkJack()
	playerTurn = 0
	AudioManager._stop_shuffle_sfx()
	
	remove_pair_bot_timer.start()

func _physics_process(_delta):
	if not isGameOver && not isPaused:
		if isGameMoving:
			if pair_cards.get_child_count() >= 50:
				_game_over()
				return
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
	_remove_cards(Player2, 1)
	_remove_cards(Player3, 2)
	_remove_cards(Player4, 3)
	
	var cardsSplit = Utility.findPairs(Player1.cardsInHand)
	pairUnPairCards(Player1, 0, STATE.INPAIR, false, cardsSplit.pairCards)
	
	await get_tree().create_timer(0.5).timeout
	_remove_cards(Player1, 0)
	
	await get_tree().create_timer(0.5).timeout
	isGameMoving = true

func turn(nextPlayer, nextPlayerIndex, currentPlayer, currentPlayerIndex):
	pairUnPairCards(nextPlayer, nextPlayerIndex, STATE.INPICKING)
	isGameMoving = false
	
	# picking card from next player
	if currentPlayerIndex == 0:
		PlayerPickTurnTimer.start()
		PlayerPickTurnProgressBar.show()
		await get_tree().create_timer(PLAYER_PICK_TIME).timeout
		PlayerPickTurnProgressBar.hide()
		if not pickedCard:
			pickedCard = Utility.pickRandomCard(nextPlayer.get_children())
	else:
		if Player1.cardsInHand.size() <= 0:
			await get_tree().create_timer(0.2).timeout
		else:
			await get_tree().create_timer(0.6).timeout
		pickedCard = Utility.pickRandomCard(nextPlayer.get_children())
	
	var sPos = pickedCard.position
	var sRot = pickedCard.rotation
	var shouldShowCard = false
	if currentPlayerIndex == 0:
		shouldShowCard = true
	_add_cards(currentPlayerIndex, pickedCard.cardName, sPos, sRot, STATE.MOVINGFROMPICKINGTOHAND, shouldShowCard)
	AudioManager._play_card_take_sfx()
	_remove_cards(nextPlayer, nextPlayerIndex, pickedCard.cardName)
	pairUnPairCards(nextPlayer, nextPlayerIndex, STATE.MOVINGFROMPICKINGTOHAND, true, [], true)
	
	# checking if there is pair after pickup and throwing the pair cards
	if Player1.cardsInHand.size() <= 0:
		await get_tree().create_timer(0.3).timeout
	else:
		await get_tree().create_timer(0.5).timeout
	_remove_cards(currentPlayer, currentPlayerIndex)
	
	# rearranging cards for both players
	if Player1.cardsInHand.size() <= 0:
		await get_tree().create_timer(0.2).timeout
	else:
		await get_tree().create_timer(0.4).timeout
	if currentPlayerIndex == 0 || nextPlayerIndex == 0:
		checkJack()
	if currentPlayer.cardsInHand.size() > 0:
		if not currentPlayerIndex == 0:
			shuffleCardsInHand(currentPlayer)
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

func _on_shuffle_button_pressed():
	AudioManager._play_button_sfx()
	shuffleCardsInHand(Player1)

# Pause Game
# TODO: make the pause work when the player turn is on
func _on_pause_button_pressed():
	AudioManager._play_button_sfx()
	isPaused = true
	if playerTurn == 0:
		PlayerPickTurnTimer.set_paused(true)
	PausePanel.visible = true

# Continue Game
func _on_continue_button_pressed():
	AudioManager._play_button_sfx()
	PausePanel.visible = false
	isPaused = false
	if playerTurn == 0:
		PlayerPickTurnTimer.start()

# Shuffle Cards
func shuffleCardsInHand(playerNode):
	var oldPositionsWithIndex = []
	var i = 0
	
	for card in playerNode.cardsInHand:
		oldPositionsWithIndex.append({
			"position": playerNode.get_child(i).position,
			"rotation": playerNode.get_child(i).rotation,
		})
		i += 1
	
	playerNode.cardsInHand.shuffle()
	i = 0
	
	var cardSprites = playerNode.get_children()
	
	for card in cardSprites:
		var newIndex = playerNode.cardsInHand.find(card.cardName)
		card.startPosition = card.position
		card.startRotation = card.rotation
		card.targetPosition = oldPositionsWithIndex[newIndex].position
		card.targetRotation = oldPositionsWithIndex[newIndex].rotation
		playerNode.move_child(card, newIndex)
		card.state = STATE.SHUFFLE
		pass


# ALL NEW FUNCTION FROM HERE ALL FUNCTIONS ABOVE THIS WILL BE REPLACED LATER
# Except for the inbuilt functions and singal connected functions from button pressed

# remove card from the given node
func _remove_cards(node, nodeIndex, removeCard = null):
	var toRemoveCards = []
	if !removeCard:
		var cardsSplited = Utility.findPairs(node.cardsInHand)
		if cardsSplited.pairCards.size() <= 0:
			return
		node.SetNewSetOfCards(cardsSplited.nonPairCards)
		_remove_pairs_to_pile(node, cardsSplited.pairCards)
		toRemoveCards = cardsSplited.pairCards
		AudioManager._play_card_pair_throw_sfx()
	else:
		toRemoveCards = [removeCard]
	
	node.RemoveCardsFromHand(toRemoveCards)
	for card in node.get_children():
		if toRemoveCards.has(card.cardName):
			card.queue_free()
	
	await get_tree().create_timer(0.6).timeout
	rearrangeCards(node, nodeIndex)

# add card to the given node
func _add_cards(nodeIndex, cardName, startPos, startRot, state, showCard = false):
	var targetPosition = Vector2(0, 0)
	var targetRotation = deg_to_rad(0)
	var node = pair_cards
	
	if nodeIndex != -1:
		node = _get_current_player_node(nodeIndex)
	
	var new_to_add_card = CardBase.instantiate()
	new_to_add_card.connect("pick_card", pickCardByPlayer)
	new_to_add_card.cardName = cardName
	new_to_add_card.startPosition = startPos
	new_to_add_card.startRotation = startRot
	
	match nodeIndex:
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
		
	if showCard:
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
	if not nodeIndex == -1:
		node.AddCardInHand(new_to_add_card.cardName)
	new_to_add_card.state = state
	
	await get_tree().create_timer(0.6).timeout
	rearrangeCards(node, nodeIndex)

# remove the pair cards in hand to the pile of the cards in center
func _remove_pairs_to_pile(node, toRemoveCards):
	var sPos = 0
	var sRot = 0
	
	for card in node.get_children():
		if toRemoveCards.has(card.cardName):
			sPos = Vector2(pair_cards.position.x - card.position.x, pair_cards.position.y - card.position.y)
			sRot = card.rotation
			_add_cards(-1, card.cardName, sPos, sRot, STATE.MOVINGFROMHANDTODECK, true)

# indicate player turn
func indicatePlayerTurn(isPlayerTurn):
	if isPlayerTurn:
		player_turn_emote.show()
		player_turn_emote.play()
	else:
		player_turn_emote.hide()
		player_turn_emote.stop()

# Check for jack in player hand if not random mode
func checkJack():
	if isRandomMode:
		return
	if Player1.cardsInHand.has("card_j_spade") || Player1.cardsInHand.has("card_j_diamond") || Player1.cardsInHand.has("card_j_heart"):
		JackIndicator.texture = load("res://Assets/UI/indicator_has_jack.png")
	else:
		JackIndicator.texture = load("res://Assets/UI/indicator_no_jack.png")

func _exit_game():
	AudioManager._play_button_sfx()
	get_tree().change_scene_to_file("res://Scenes/Menu_Scenes/main_menu.tscn")

# on click exit button
func _on_exit_button_pressed():
	_exit_game()

# Quit Game
func _on_quit_button_pressed():
	_exit_game()

# on click replay button
func _on_replay_button_pressed():
	AudioManager._play_button_sfx()
	startTheGame()

# Reset all the cards and variables to the initial state
func _reset_gameplay():
	Player1.RemoveAllCards()
	for player1Card in Player1.get_children():
		player1Card.queue_free()
	Player2.RemoveAllCards()
	for player2Card in Player2.get_children():
		player2Card.queue_free()
	Player3.RemoveAllCards()
	for player3Card in Player3.get_children():
		player3Card.queue_free()
	Player4.RemoveAllCards()
	for player4Card in Player4.get_children():
		player4Card.queue_free()
		
	for pileCard in pair_cards.get_children():
		pileCard.queue_free()
	
	isGameOver = false
	isGameMoving = false
	isPaused = false
	game_over_panel.hide()
	PausePanel.hide()
	
	checkJack()
	
	playerTurn = 0
	angle = deg_to_rad(-130)
	posOffsetX = 0
	posOffsetYLeft = 0
	posOffsetYRight = 0
	playerToPickFrom = 1
	playerToPickFromNode = Player2
	pickedCard = null

# Game over function
func _game_over():
	isGameOver = true
	isGameMoving = false
	indicatePlayerTurn(false)
	for cards in _get_current_player_node(playerTurn).get_children():
		cards.SetCardVisible()
	game_over_panel.show()

# Get the player node with the index
func _get_current_player_node(playerIndex):
	match playerIndex:
		0:
			return Player1
		1:
			return Player2
		2:
			return Player3
		3:
			return Player4
