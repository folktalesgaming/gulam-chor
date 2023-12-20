extends Node2D

# PRELOAD
const CardBase = preload("res://Prefabs/Card/Card.tscn")
const Utility = preload("res://Utils/utility.gd")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")
const Emotes = preload("res://Utils/emotes.gd")
const Player = preload("res://Prefabs/Player/Player.tscn")

# ONREADY VARS
@onready var players = %Players
@onready var pack_of_deck = %PackOfDeck
@onready var player_1 = %Player1
@onready var player_2 = %Player2
@onready var player_3 = %Player3
@onready var player_4 = %Player4

# Multiplayer
@onready var multiplayer_synchronizer = %MultiplayerSynchronizer

# audios
@onready var card_shuffle_audio = %CardShuffle
# getting the deck of cards
@onready var deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())

# Timers
@onready var remove_pair_bot_timer = %RemovePairBotTimer

# Player position oval calulation
@onready var ViewportSizeX = ProjectSettings.get_setting("display/window/size/viewport_width")
@onready var ViewportSizeY = ProjectSettings.get_setting("display/window/size/viewport_height")
@onready var CenterCardOval = ViewportSizeX * Vector2(0.45, 1.55)
@onready var Horizontal_radius = ViewportSizeX * 0.45
@onready var Vertical_radius = ViewportSizeY * 0.2

# GLOBAL VARS
var playerTurn = 0

var angle = deg_to_rad(-130)
var OvalAngleVector = Vector2()

var posOffsetYRight = 0
var posOffsetYLeft = 0
var posOffsetX = 0

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
	INPICKED,
	INREMOVEPICKED,
	SHUFFLE,
}

func _ready():
	multiplayer_synchronizer.set_multiplayer_authority(1)
	if multiplayer_synchronizer.is_multiplayer_authority():
		_start_game.rpc()

func _process(delta):
	match playerTurn:
		0:
			pass
		1:
			pass
		2:
			pass
		3:
			pass
	pass

func _instantiate_deck_of_cards():
	for card in deckOfCards:
		var new_card = CardBase.instantiate()
		new_card.name = card
		new_card.cardName = card
		new_card.state = STATE.INDECK
		pack_of_deck.add_child(new_card)

@rpc("any_peer", "call_local")
func _start_game():
	deckOfCards = Utility.shuffleDeck(DeckOfCard.getDeckClassic())
	card_shuffle_audio.play()
	
	_instantiate_deck_of_cards()
	
	var i = 0
	
	for card in pack_of_deck.get_children():
		if playerTurn == 0:
			# TODO: Make it more dynamic for later when removing pairs and adding cards to hand 
			moveCard.rpc(i, STATE.MOVINGFROMDECKTOHAND, 0, true)
			angle += PlayerHandCardAngleOffset
		if playerTurn == 1:
			moveCard.rpc(i, STATE.MOVINGFROMDECKTOHAND, 1, false)
			posOffsetYRight += RightPlayerCardPositionOffset
		if playerTurn == 2:
			moveCard.rpc(i, STATE.MOVINGFROMDECKTOHAND, 2, false)
			posOffsetX += TopPlayerCardPositionOffset
		if playerTurn == 3:
			moveCard.rpc(i, STATE.MOVINGFROMDECKTOHAND, 3, false)
			posOffsetYLeft += LeftPlayerCardPositionOffset
		
		playerTurn = (1+playerTurn)%4
		
		i += 1
		await get_tree().create_timer(0.08).timeout
	
	card_shuffle_audio.stop()
	
	

@rpc("any_peer", "call_local")
func moveCard(cardIndex, state, playerIndex, shouldCardBeVisible=false):
	var targetPosition = Vector2(0, 0)
	var targetRotation = deg_to_rad(0)
	var localCard = pack_of_deck.get_child(cardIndex)
#	new_to_add_card.connect("pick_card", pickCardByPlayer)
	var node = player_1
	
	match playerIndex:
		0:
			node = player_1
			OvalAngleVector = Vector2(-Horizontal_radius * cos(angle), -Vertical_radius * sin(angle))
			targetPosition = CenterCardOval - OvalAngleVector - pack_of_deck.position
			targetRotation = deg_to_rad(angle)/2
		1:
			node = player_2
			targetPosition = ViewportSizeX * Vector2(0.95, 1 - posOffsetYRight) - pack_of_deck.position
			targetRotation = deg_to_rad(-90)
		2:
			node = player_3
			targetPosition = ViewportSizeX * Vector2(0.75 - posOffsetX, -0.1) - pack_of_deck.position
			targetRotation = deg_to_rad(180)
		3:
			node = player_4
			targetPosition = ViewportSizeX * Vector2(-0.08, 1 - posOffsetYLeft) - pack_of_deck.position
			targetRotation = deg_to_rad(90)
		-1:
			targetPosition = Vector2(rng.randf_range(-2.0, 10.0), rng.randf_range(-2.0, 10.0))
			targetRotation = deg_to_rad(localCard.rotation + rng.randf_range(-30.0, 60.0))
	
	localCard.startPosition = localCard.position
	localCard.startRotation = localCard.rotation
	localCard.targetPosition = targetPosition
	localCard.targetRotation = targetRotation
		
	if shouldCardBeVisible:
		localCard.SetCardVisible()
	
#	node.add_child(new_to_add_card)
	if not playerIndex == -1:
		node.AddCardInHand(localCard.cardName)
	localCard.state = state
	
#	if multiplayer.is_server():
#		moveCard.rpc(cardIndex, state, startPos, startRot, playerIndex, shouldCardBeVisible)

@rpc("any_peer", "call_local")
func removeCardFromHand(cardIndex: int, playerIndex: int, state: STATE) -> void:
	var targetPosition = pack_of_deck.position
	var targetRotation = deg_to_rad(randi_range(0, 60))
	var localCard = pack_of_deck.get_child(cardIndex)
#	new_to_add_card.connect("pick_card", pickCardByPlayer)
	var node = player_1
	
	match playerIndex:
		0:
			node = player_1
		1:
			node = player_2
		2:
			node = player_3
		3:
			node = player_4
	
	localCard.startPosition = localCard.position
	localCard.startRotation = localCard.rotation
	localCard.targetPosition = targetPosition
	localCard.targetRotation = targetRotation
	localCard.SetCardVisible()

	node.AddCardInHand(localCard.cardName)
	localCard.state = state

# remove cards from bot if any
func _on_remove_pair_player_timer_timeout():
	var BotPlayers = GameManager.Players
	pass
