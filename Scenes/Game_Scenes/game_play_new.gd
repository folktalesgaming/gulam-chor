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

@onready var player = %Player
@onready var player_2 = %Player2
@onready var player_3 = %Player3
@onready var player_4 = %Player4

@onready var indicator_has_jack = %IndicatorHasJack

@onready var ViewportSizeX = ProjectSettings.get_setting("display/window/size/viewport_width") # Size of viewport
@onready var ViewportSizeY = ProjectSettings.get_setting("display/window/size/viewport_height") # Size of viewport
@onready var CenterCardOval = ViewportSizeX * Vector2(0.45, 1.55) # Calculating the center of oval for player card arc
@onready var Horizontal_radius = ViewportSizeX * 0.45 # Horizontal radius of the oval arc
@onready var Vertical_radius = ViewportSizeY * 0.2 # Vertical radius of the oval arc

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

# Variables to check and operate the current state of the game
var isGameMoving = false
var isGameOver = false
var isGamePaused = false

var isRandomMode = false
var playerTurnIndex = 0

var rng = RandomNumberGenerator.new()

var angle = deg_to_rad(-130) # Angle at which the card must be positioned
var OvalAngleVector = Vector2() # Vector to convert the polar points (r, 0) to cartesian points (x,y)

var posOffsetYRight = 0 # Position of cards of player to the right
var posOffsetYLeft = 0 # Position of cards of player to the left
var posOffsetX = 0 # Position of cards of player to the top

var isPlayerTurnToPick = false # Determine if it is players turn to pick card

# Offset of cards angle and position of each players
const PlayerHandCardAngleOffset = 0.12
const RightPlayerCardPositionOffset = 0.07
const TopPlayerCardPositionOffset = 0.05
const LeftPlayerCardPositionOffset = 0.07

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

func _process(delta):
	if !isGameOver && !isGamePaused:
		if isGameMoving:
			pass

# Start the game by shuffling and diving the 51 cards
func _start_game():
	var deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
	if isRandomMode:
		deckOfCards = Utility.shuffleDeck(DeckOfCardRandomMode.getDeckAllRandomMode())
		indicator_has_jack.texture = load("res://Assets/UI/random_mode_indicator.png")
	
	for cardName in deckOfCards:
		var targetDestination = _get_player_card_target_destination(playerTurnIndex)
		var card = CardBase.instantiate()
		card.cardName = cardName
		card.targetPosition = targetDestination.targetPosition
		card.targetRotation = targetDestination.targetRotation
		
		deck_pile.add_child(card)
		card.state = STATE.MOVINGFROMDECKTOHAND
		
		var playerNode = _get_player_node_from_player_index(playerTurnIndex)
		playerNode._add_cards(cardName)
		if playerTurnIndex == 0:
			card.SetCardVisible()
			angle += PlayerHandCardAngleOffset
		if playerTurnIndex == 1:
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerTurnIndex == 2:
			posOffsetX += TopPlayerCardPositionOffset
		if playerTurnIndex == 3:
			posOffsetYLeft += LeftPlayerCardPositionOffset
		playerTurnIndex = (playerTurnIndex+1)%NUM_OF_PLAYERS
		
		await get_tree().create_timer(DIVIDING_TIME).timeout
	
	playerTurnIndex = 0
	pack_of_deck.hide()
	
	await get_tree().create_timer(REMOVE_BOT_CARDS_TIME).timeout
	_remove_pair_cards_from_hand(1)
	_remove_pair_cards_from_hand(2)
	_remove_pair_cards_from_hand(3)
	
	_player_card_pick_state(playerTurnIndex, false, true)
	await get_tree().create_timer(REMOVE_BOT_CARDS_TIME - 0.2).timeout
	_remove_pair_cards_from_hand(playerTurnIndex) 

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
	
	_check_jack_in_player()

# Make the next player cards in hand in picking state
func _player_card_pick_state(playerIndex, isReverse = false, onlyPair = false):
	var offset = 60
	var spread = 0 # TODO: Create a spread effect in picking mode
	var tPosOffSetX = offset * _get_one_or_zero_or_minus_one(playerIndex, isReverse, 0)
	var tPosOffSetY = offset * _get_one_or_zero_or_minus_one(playerIndex, isReverse, 1)
	var isCardInPickingOrPair = false
	
	var playerNode = _get_player_node_from_player_index(playerIndex)
	var playerCardsInHand = _get_player_cards(playerNode)
	var pairCards = []
	
	if onlyPair:
		pairCards = Utility.findPairs(playerNode._get_cards_in_hand()).pairCards
	
	for card in playerCardsInHand:
		var targetPosition = Vector2(card.position.x + tPosOffSetX, card.position.y + tPosOffSetY)
		if onlyPair:
			if pairCards.has(card.cardName):
				card.targetPosition = targetPosition
				card.state = STATE.INTOBEPICKED
		else:
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
func _picking_card(cardName):
	var cardNode = _get_card_node_from_card_name(cardName)
	
	#cardNode.position =  global position of the hand
	
	cardNode.state = STATE.INPICKING
	pass

# Picks the card from next player in line to the current player hand
func _pick_card(cardName):
	var playerNode = _get_player_node_from_player_index(playerTurnIndex)
	var nextPlayerIndex = _get_next_player_index(playerTurnIndex)
	var nextPlayerNode = _get_player_node_from_player_index(nextPlayerIndex)
	
	var cardNode = _get_card_node_from_card_name(cardName)
	
	playerNode._add_cards(cardName)
	nextPlayerNode._remove_cards([cardName])
	
	cardNode.state = STATE.MOVINGFROMPICKINGTOHAND

# Removes the pair of cards from the players hand to the pile of cards
func _remove_pair_cards_from_hand(playerIndex):
	var playerNode = _get_player_node_from_player_index(playerIndex)
	var cardsSplitted = Utility.findPairs(playerNode._get_cards_in_hand())
	if cardsSplitted.pairCards.size() <= 0:
		return
	
	playerNode._remove_cards(cardsSplitted.pairCards)
	for cardName in cardsSplitted.pairCards:
		var cardNode = _get_card_node_from_card_name(cardName)
		cardNode.targetPosition = Vector2(rng.randf_range(0.0, 5.0), rng.randf_range(0.0, 5.0))
		cardNode.targetRotation = deg_to_rad(rng.randf_range(-30.0, 60.0))
		cardNode.state = STATE.MOVINGFROMHANDTODECK
		cardNode.SetCardVisible()

# Shows and operates the essential operation on game finish
func _game_finish():
	isGameOver = true
	isGameMoving = false
	
	# TODO: Operate other stuffs like showing UI and etc

# Shuffles the cards in hand
func _shuffle_cards_in_hand(playerIndex):
	var playerNode = _get_player_node_from_player_index(playerIndex)
	var cardsInPlayerHand = _get_player_cards(playerNode)
	
	# TODO: shuffle the cards around

# UTILITY FUNCTIONS

# Returns the target position and target rotation of the card according to player
func _get_player_card_target_destination(playerIndex):
	var targetPosition = Vector2(0, 0)
	var targetRotation = deg_to_rad(0)
	
	match playerIndex:
		0:
			OvalAngleVector = Vector2(-Horizontal_radius * cos(angle), -Vertical_radius * sin(angle))
			targetPosition = CenterCardOval - OvalAngleVector - deck_pile.position
			targetRotation = deg_to_rad(angle)/2
		1:
			targetPosition = ViewportSizeX * Vector2(0.95, 1 - posOffsetYRight) - deck_pile.position 
			targetRotation = deg_to_rad(-90)
		2:
			targetPosition = ViewportSizeX * Vector2(0.75 - posOffsetX, -0.1) - deck_pile.position
			targetRotation = deg_to_rad(180)
		3:
			targetPosition = ViewportSizeX * Vector2(-0.08, 1 - posOffsetYLeft) - deck_pile.position
			targetRotation = deg_to_rad(90)
	
	return {
		"targetPosition": targetPosition,
		"targetRotation": targetRotation,
	}

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
	var playerNode = _get_player_node_from_player_index(playerIndex)
	if playerNode._check_jack():
		indicator_has_jack.texture = load("res://Assets/UI/indicator_has_jack.png")
	else:
		indicator_has_jack.texture = load("res://Assets/UI/indicator_no_jack.png")
