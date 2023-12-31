extends Node

var random_mode_setting_path = ("user://random-mode-setting.save")

# PRELOADS
const CardBase = preload("res://Prefabs/Card/Card.tscn")
const Utility = preload("res://Utils/utility.gd")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")
const DeckOfCardRandomMode = preload("res://Utils/deck_of_cards_all.gd")

# on ready variables from the game scene
@onready var deck_pile = %DeckPile
@onready var pack_of_deck = %PackOfDeck
@onready var pause_panel = %PausePanel
@onready var game_over_panel = %GameOverPanel

@onready var player = %Player
@onready var player_2 = %Player2
@onready var player_3 = %Player3
@onready var player_4 = %Player4

@onready var indicator_has_jack = %IndicatorHasJack
@onready var player_pick_turn_timer = %PlayerPickTurnTimer
@onready var player_pick_turn_progress_bar = %PlayerPickTurnProgressBar
@onready var player_turn_emote = %PlayerTurnEmote

@onready var ViewportSizeX = ProjectSettings.get_setting("display/window/size/viewport_width") # Size of viewport
@onready var ViewportSizeY = ProjectSettings.get_setting("display/window/size/viewport_height") # Size of viewport

@onready var player_position = Vector2(ViewportSizeX / 2, ViewportSizeY - 520) - deck_pile.position
@onready var player2_position = Vector2(ViewportSizeX - 40, ViewportSizeY - 1170) - deck_pile.position
@onready var player3_position = Vector2(ViewportSizeX / 2, ViewportSizeY - 1880) - deck_pile.position
@onready var player4_position = Vector2(ViewportSizeX - 1040, ViewportSizeY - 1170) - deck_pile.position

# exported variables
@export var spread_curve: Curve
@export var height_curve: Curve
@export var rotation_curve: Curve

# CONSTANTS
# State of each card
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
const DIVIDING_TIME = 0.08
const NUM_OF_PLAYERS = 4
const REMOVE_BOT_CARDS_TIME = 0.8
const BOT_PICK_TIME = 0.9

# Variables to check and operate the current state of the game
var isGameMoving = false
var isGameOver = false
var isGamePaused = false

var isRandomMode = false
var playerTurnIndex = 0
var wasGameRegular = true

var pickedCard = null
var mayBePickedCards = []

var rng = RandomNumberGenerator.new()

var posOffsetX = 0 # Position of cards of player to the top
var isPlayerTurnToPick = false # Determine if it is players turn to pick card

# FUNCTIONS
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
	_start_game()

func _process(_delta):
	if !isGameOver && !isGamePaused:
		if isGameMoving:
			var nextPlayerIndex = _get_next_player_index(playerTurnIndex)
			var playerNode = _get_player_node_from_player_index(playerTurnIndex)
			var nextPlayerNode = _get_player_node_from_player_index(nextPlayerIndex)
			_player_card_pick_state(nextPlayerIndex)
			isGameMoving = false
			
			if playerTurnIndex == 0:
				if wasGameRegular:
					_player_pick()
				else:
					wasGameRegular = true
				if !pickedCard:
					return
			else:
				pickedCard = Utility.pickRandomCard(_get_player_cards(nextPlayerNode))
			
			var targetValues = _get_player_card_target_destination(playerTurnIndex)
			pickedCard.targetPosition = targetValues.targetPosition
			pickedCard.targetRotation = targetValues.targetRotation
			pickedCard.state = STATE.MOVINGFROMPICKINGTOHAND
			playerNode._add_cards(pickedCard.cardName)
			nextPlayerNode._remove_cards([pickedCard.cardName])
			if nextPlayerIndex == 0:
				pickedCard.SetCardNotVisible()
				_rearrange_cards_in_hand(0)
			if playerTurnIndex == 0:
				pickedCard.SetCardVisible()
			
			await get_tree().create_timer(BOT_PICK_TIME).timeout
			_remove_pair_cards_from_hand(playerTurnIndex)
			_rearrange_cards_in_hand(playerTurnIndex)
			_player_card_pick_state(nextPlayerIndex, true)
			pickedCard = null
			if playerTurnIndex == 0 || nextPlayerIndex == 0:
				_check_jack_in_player()
			playerTurnIndex = _get_next_player_index(playerTurnIndex)
			isGameMoving = true

# Start the game by shuffling and diving the 51 cards
func _start_game():
	_indicate_player_turn(false)
	var deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
	if isRandomMode:
		deckOfCards = Utility.shuffleDeck(DeckOfCardRandomMode.getDeckAllRandomMode())
		indicator_has_jack.texture = load("res://Assets/UI/random_mode_indicator.png")
	
	AudioManager._play_shuffle_sfx()
	for cardName in deckOfCards:
		var targetDestination = _get_player_card_target_destination(playerTurnIndex)
		var card = CardBase.instantiate()
		card.connect("pick_card", _pick_card)
		card.connect("select_card", _picking_card)
		card.connect("cancel_select", _cancel_select)
		card.cardName = cardName
		card.targetPosition = targetDestination.targetPosition
		card.targetRotation = targetDestination.targetRotation
		
		deck_pile.add_child(card)
		card.state = STATE.MOVINGFROMDECKTOHAND
		
		var playerNode = _get_player_node_from_player_index(playerTurnIndex)
		playerNode._add_cards(cardName)
		if playerTurnIndex == 0:
			card.SetCardVisible()
		playerTurnIndex = (playerTurnIndex+1)%NUM_OF_PLAYERS
		
		await get_tree().create_timer(DIVIDING_TIME).timeout
	
	playerTurnIndex = 0
	pack_of_deck.hide()
	AudioManager._stop_shuffle_sfx()
	
	await get_tree().create_timer(REMOVE_BOT_CARDS_TIME).timeout
	_remove_pair_cards_from_hand(1)
	_remove_pair_cards_from_hand(2)
	_remove_pair_cards_from_hand(3)
	_remove_pair_cards_from_hand(playerTurnIndex)
	
	await get_tree().create_timer(REMOVE_BOT_CARDS_TIME - 0.2).timeout
	_check_jack_in_player()
	isGameMoving = true

# Reset the game to the initial position for replay
func _reset_game():
	player._remove_all_cards()
	player_2._remove_all_cards()
	player_3._remove_all_cards()
	player_4._remove_all_cards()
	
	deck_pile._pick_back_cards()
	
	isGameMoving = false
	isGameOver = false
	isGamePaused = false
	
	pack_of_deck.show()
	
	playerTurnIndex = 0
	pickedCard = null

# Make the next player cards in hand in picking state
func _player_card_pick_state(playerIndex, isReverse = false, onlyPair = false):
	var offset = 60
	#var spread = 0 # TODO: Create a spread effect in picking mode
	var tPosOffSetX = offset * _get_one_or_zero_or_minus_one(playerIndex, isReverse, 0)
	var tPosOffSetY = offset * _get_one_or_zero_or_minus_one(playerIndex, isReverse, 1)
	var cardsInPickByPlayer = false
	
	var playerNode = _get_player_node_from_player_index(playerIndex)
	var playerCardsInHand = _get_player_cards(playerNode)
	var pairCards = []
	
	if onlyPair:
		pairCards = Utility.findPairs(playerNode._get_cards_in_hand()).pairCards
	
	if playerTurnIndex == 0:
		cardsInPickByPlayer = true
	
	if isReverse:
		cardsInPickByPlayer = false
	
	for card in playerCardsInHand:
		var targetPosition = Vector2(card.position.x + tPosOffSetX, card.position.y + tPosOffSetY)
		if onlyPair:
			if pairCards.has(card.cardName):
				card.isCardInPickingOrPair = cardsInPickByPlayer
				card.dragging_zone = "pile"
				card.targetPosition = targetPosition
				card.state = STATE.INTOBEPICKED
		else:
			card.dragging_zone = "player"
			card.isCardInPickingOrPair = cardsInPickByPlayer
			card.targetPosition = targetPosition
			card.state = STATE.INTOBEPICKED

func _get_one_or_zero_or_minus_one(playerIndex, isReverse, coordinate):
	match coordinate:
		0:
			match playerIndex:
				0, 2:
					return 0
			if (playerIndex == 1 && isReverse) || (playerIndex == 3 && !isReverse):
				return 1
			else:
				return -1
		1:
			match playerIndex:
				1, 3:
					return 0
			if (playerIndex == 0 && isReverse) || (playerIndex == 2 && !isReverse):
				return 1
			else:
				return -1

# When the player is picking the card
func _picking_card(card):
	var nextPlayerIndex = _get_next_player_index(0)
	var nextPlayerNode = _get_player_node_from_player_index(nextPlayerIndex)
	var cardsInNextPlayerHand = _get_player_cards(nextPlayerNode)
	
	for cardInHand in cardsInNextPlayerHand:
		if card.cardName != cardInHand.cardName:
			cardInHand.isCardInPickingOrPair = false
			mayBePickedCards.append(cardInHand)
	
	mayBePickedCards.append(card)
	card.state = STATE.INPICKING

# When player cancels the picking of card
func _cancel_select():
	for card in mayBePickedCards:
		card.isCardInPickingOrPair = true
	
	mayBePickedCards = []

# Picks the card from next player in line to the current player hand
func _pick_card(card):
	var nextPlayerIndex = _get_next_player_index(0)
	var nextPlayerNode = _get_player_node_from_player_index(nextPlayerIndex)
	
	await get_tree().create_timer(0.2).timeout
	player._add_cards(card.cardName)
	nextPlayerNode._remove_cards([card.cardName])
	
	card.state = STATE.MOVINGFROMPICKINGTOHAND
	card.SetCardVisible()
	
	player_pick_turn_timer.stop()
	_indicate_player_turn(false)
	#await get_tree().create_timer(0.2).timeout
	_remove_pair_cards_from_hand(0)
	_rearrange_cards_in_hand(0)
	
	wasGameRegular = true
	isGameMoving = true
	
	if nextPlayerNode._get_cards_in_hand().size() >= 1:
		playerTurnIndex = nextPlayerIndex
	else:
		playerTurnIndex = _get_next_player_index(0)

# Removes the pair of cards from the players hand to the pile of cards
func _remove_pair_cards_from_hand(playerIndex):
	var playerNode = _get_player_node_from_player_index(playerIndex)
	var cardsSplitted = Utility.findPairs(playerNode._get_cards_in_hand())
	if cardsSplitted.pairCards.size() <= 0:
		return
	
	playerNode._remove_cards(cardsSplitted.pairCards)
	deck_pile._add_to_pile(cardsSplitted.pairCards.size())
	for cardName in cardsSplitted.pairCards:
		var cardNode = _get_card_node_from_card_name(cardName)
		cardNode.targetPosition = Vector2(rng.randf_range(0.0, 5.0), rng.randf_range(0.0, 5.0))
		cardNode.targetRotation = deg_to_rad(rng.randf_range(-30.0, 60.0))
		cardNode.isCardInPickingOrPair = false
		cardNode.state = STATE.MOVINGFROMHANDTODECK
		cardNode.SetCardVisible()
	
	if playerNode._get_cards_in_hand().size() > 0:
		await get_tree().create_timer(REMOVE_BOT_CARDS_TIME - 0.6).timeout
		_rearrange_cards_in_hand(playerIndex)
	# Check if all cards expect the odd jack or odd card is removed or not to set game over state
	if deck_pile.cardsInPile >= 50:
		isGameMoving = false
		isGameOver = true
		game_over_panel.show()

# Shuffles the cards in hand
func _shuffle_cards_in_hand(playerIndex):
	var playerNode = _get_player_node_from_player_index(playerIndex)
	var cardsInPlayerHand = _get_player_cards(playerNode)
	
	# TODO: Proper shuffling and check for start of the game
	if cardsInPlayerHand.size() < 0:
		return
	
	var oldPositionsWithIndex = []
	
	for card in cardsInPlayerHand:
		oldPositionsWithIndex.append({
			"position": card.position,
			"rotation": card.rotation,
		})
	
	playerNode.cardsInHand.shuffle()
	
	for card in cardsInPlayerHand:
		var newIndex = playerNode._get_cards_in_hand().find(card.cardName)
		card.targetPosition = oldPositionsWithIndex[newIndex].position
		card.targetRotation = oldPositionsWithIndex[newIndex].rotation
		deck_pile.move_child(card, newIndex)
		card.state = STATE.SHUFFLE

# Start the timer for player pick turn
func _player_pick():
	_indicate_player_turn()
	player_pick_turn_timer.start()

# UTILITY FUNCTIONS

# Returns the target position and target rotation of the card according to player
func _get_player_card_target_destination(playerIndex):
	var targetPosition = Vector2(0, 0)
	var targetRotation = deg_to_rad(0)
	
	match playerIndex:
		0:
			targetPosition = player_position
			targetRotation = deg_to_rad(0)
		1:
			targetPosition = player2_position
			targetRotation = deg_to_rad(-90)
		2:
			targetPosition = player3_position
			targetRotation = deg_to_rad(180)
		3:
			targetPosition = player4_position
			targetRotation = deg_to_rad(90)
	
	return {
		"targetPosition": targetPosition,
		"targetRotation": targetRotation,
	}

# Rearrange the cards in hand after cards in hand changes
func _rearrange_cards_in_hand(playerIndex):
	var playerNode = _get_player_node_from_player_index(playerIndex)
	var cardsInPlayerHand = _get_player_cards(playerNode)
	cardsInPlayerHand.reverse()
	var numOfCards = cardsInPlayerHand.size()
	
	var playerPos = player_position
	var cardRotationOffset = deg_to_rad(90)
	
	match playerIndex:
		1:
			playerPos = player2_position
		2:
			playerPos = player3_position
		3:
			playerPos = player4_position
	
	var i = 0
	for card in cardsInPlayerHand:
		var hand_ratio = 0.5
		
		if numOfCards > 1:
			hand_ratio = float(i) / float(numOfCards - 1)
		
		var spreadOffset = spread_curve.sample(hand_ratio) * (30 * (numOfCards - 1))
		var heightOffset = height_curve.sample(hand_ratio) * (10 * (numOfCards - 1))
		var rotationOffset = rotation_curve.sample(hand_ratio) * (0.05 * (numOfCards - 1))
		
		var xPos = playerPos.x
		var yPos = playerPos.y
		
		match playerIndex:
			0:
				card.targetPosition = Vector2(xPos - spreadOffset, yPos - heightOffset)
				card.targetRotation = rotationOffset
			1:
				card.targetPosition = Vector2(xPos - heightOffset, yPos - spreadOffset)
				card.targetRotation = -rotationOffset - cardRotationOffset
			2:
				card.targetPosition = Vector2(xPos - spreadOffset, yPos + heightOffset)
				card.targetRotation = -rotationOffset
			3:
				card.targetPosition = Vector2(xPos + heightOffset, yPos + spreadOffset)
				card.targetRotation = -(cardRotationOffset + rotationOffset)
		card.state = STATE.REORGANIZE
		i += 1

# Returns the player node from player index
func _get_player_node_from_player_index(playerIndex):
	match playerIndex:
		0:
			return player
		1:
			return player_2
		2:
			return player_3
		3:
			return player_4

# Returns the card node from cardName
func _get_card_node_from_card_name(cardName):
	var cardNode = null
	
	for card in deck_pile.get_children():
		if cardName == card.cardName:
			cardNode = card
			break
	
	return cardNode

# Returns the array of card nodes the player has in hand
func _get_player_cards(playerNode):
	var cardNodes = []
	
	for card in deck_pile.get_children():
		if playerNode._get_cards_in_hand().has(card.cardName):
			cardNodes.append(card)
	
	return cardNodes;

# Returns the next player to pick from
func _get_next_player_index(currentPlayerIndex):
	var nextPlayerIndex = (currentPlayerIndex+1) % 4
	var numberOfCardsInPlayerHand = _get_player_node_from_player_index(nextPlayerIndex)._get_cards_in_hand().size()
	if numberOfCardsInPlayerHand <= 0:
		return _get_next_player_index(nextPlayerIndex)
	return nextPlayerIndex

# Check for jack in player hand if not random mode
func _check_jack_in_player(playerIndex = 0):
	if isRandomMode:
		return
	if _get_player_node_from_player_index(playerIndex)._check_jack():
		indicator_has_jack.texture = load("res://Assets/UI/indicator_has_jack.png")
	else:
		indicator_has_jack.texture = load("res://Assets/UI/indicator_no_jack.png")

# Indicate either its player turn or not
func _indicate_player_turn(isPlayerTurn = true):
	if isPlayerTurn:
		player_turn_emote.play()
		player_turn_emote.show()
		player_pick_turn_progress_bar.show()
	else:
		player_turn_emote.stop()
		player_turn_emote.hide()
		player_pick_turn_progress_bar.hide()

# On player pick timer timeout if player already hasn't picked a card pick a random card for player
func _on_player_pick_turn_timer_timeout():
	_indicate_player_turn(false)
	var nextPlayerIndex = _get_next_player_index(0)
	var nextPlayerNode = _get_player_node_from_player_index(nextPlayerIndex)
	
	# TODO: Check for timeout when a card is picked
	if pickedCard:
		pickedCard.isCardInPickingOrPair = false
		
	pickedCard = Utility.pickRandomCard(_get_player_cards(nextPlayerNode))
	
	wasGameRegular = false
	isGameMoving = true

# Replay the game
func _on_replay_button_pressed():
	AudioManager._play_button_sfx()
	game_over_panel.hide()
	_reset_game()
	_start_game() 

# Quit the game
func _on_exit_button_pressed():
	AudioManager._play_button_sfx()
	get_tree().change_scene_to_file("res://Scenes/Menu_Scenes/main_menu.tscn")

# Quit game from pause menu
func _on_quit_button_pressed():
	AudioManager._play_button_sfx()
	get_tree().change_scene_to_file("res://Scenes/Menu_Scenes/main_menu.tscn")

# Continue game from pause menu
func _on_continue_button_pressed():
	AudioManager._play_button_sfx()
	pause_panel.hide()
	isGamePaused = false
	if playerTurnIndex == 0:
		player_pick_turn_timer.paused = false

# Pause the game
func _on_pause_button_pressed():
	AudioManager._play_button_sfx()
	wasGameRegular = false
	isGamePaused = true
	if playerTurnIndex == 0:
		player_pick_turn_timer.paused = true
	pause_panel.show()

# Shuffle the cards in hand
func _on_shuffle_button_pressed():
	_shuffle_cards_in_hand(0)
